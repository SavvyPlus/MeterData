# -*- coding: utf-8 -*-
"""
Created on Thu Jul 03 17:01:55 2014

@author: andrew.dodds
"""
#import pyodbc
import ceODBC
import logging
from StringIO import StringIO
from pandas import read_csv#, ExcelFile, DataFrame
from re import match, sub
from math import isnan
#from petl import addfield
from datetime import datetime
from cdecimal import Decimal
from numpy import all, arange, float64
import os
from zipfile import ZipFile
from datadog import api as DataDogAPI
#import xml.etree.ElementTree as ET


logger = logging.getLogger(__name__)
# db_connection_string = 'Driver={SQL Server Native Client 11.0};Server=MEL-LT-001\SQLEXPRESS;Database=MeterDataDB;Trusted_Connection=yes;'
# conn = pyodbc.connect(db_connection_string)
# Logging tag
tags = ['version:1', 'application:meter data loader']

def format_column_heading(ch):
    # handle tupleized columns
    if ch.__class__ is tuple:
        tup = ch
        ch = ''
        for elem in tup:
            ch = ch + ('' if elem.startswith('Unnamed') else elem+' ')
            
    
    # remove leading/trailing whitespace    
    ch = ch.strip()
    
    # remove [number] from rhs
    s = match(r"\][0-9]+\[", ch[::-1])   # apply reversed pattern to reversed string because it occurs on rhs
    ch = ch if s is None else ch[:-s.end()]
    
    # ensure all characters are alphanumeric or underscore
    ch = sub(r"[^$A-Za-z0-9_]+",'_',ch)
    
    # remove leading & trailing underscores
    ch = ch.strip("_")
    
    # ensure first character is valid else prepend underscore
    ch = ch if match(r"[$0-9]", ch) is None else "_"+ch
    
    # lower case
    ch = ch.lower()
    
    return ch

def sql_merge_statement(dest_table,all_fields,key_fields):
    
    data_fields = list(set(all_fields).difference(key_fields))        
    all_fields = map(lambda x: "[" + x + "]", all_fields)
    key_fields = map(lambda x: "[" + x + "]", key_fields)
    data_fields = map(lambda x: "[" + x + "]", data_fields)

    if len(key_fields) > 0:        
        s = "MERGE " + dest_table + "\nUSING (\n\tVALUES(" + ','.join(map(lambda x:'?', all_fields)) + ")\n)"
        s = s + " AS src (" + ','.join(all_fields) + ")\n ON "
        s = s + ' AND '.join(map(lambda x: (dest_table+".{c} = src.{c}").format(c=x), key_fields))
        s = s + "\nWHEN MATCHED THEN \n\tUPDATE SET " + ','.join(map(lambda x: "{c} = src.{c}".format(c=x), data_fields))
        s = s + "\nWHEN NOT MATCHED THEN \n\tINSERT (" + ','.join(all_fields) + ")"
        s = s + "\n\tVALUES (" + ','.join(map(lambda x:'src.'+x, all_fields)) + ")\n;"
        
    else:
        s = "INSERT INTO " + dest_table + "(" + ','.join(all_fields) + ") VALUES (" + ','.join(map(lambda x:'?', all_fields)) + ")"
    return s

def sql_mdff_merge_statement(dest_table,fields,merge_keys):
    
    # data_fields = list(set(fields).difference(merge_keys))        
    fields = map(lambda x: "[" + x + "]", fields)
    merge_keys = map(lambda x: "[" + x + "]", merge_keys)
    # data_fields = map(lambda x: "[" + x + "]", data_fields)
    
    if len(merge_keys) > 0:
        s = "MERGE " + dest_table + "\nUSING (\n\tVALUES(" + ','.join(map(lambda x:'?', fields)) + ")\n)"
        s = s + " AS src (" + ','.join(fields) + ")\n ON "
        s = s + ' AND '.join(map(lambda x: ("("+dest_table+".{c} = src.{c} OR ("+dest_table+".{c} is null and src.{c} is null))").format(c=x), merge_keys))
        s = s + "\nWHEN MATCHED THEN \n\tUPDATE SET " + fields[0] + "=" + dest_table + "." + fields[0] # + ','.join(map(lambda x: "{c} = src.{c}".format(c=x), data_fields))
        s = s + "\nWHEN NOT MATCHED THEN \n\tINSERT (" + ','.join(fields) + ")"
        s = s + "\n\tVALUES (" + ','.join(map(lambda x:'src.'+x, fields)) + ")\n"    
        s = s + "\nOUTPUT inserted.ID;"
    else:
        s = "INSERT INTO " + dest_table + "(" + ','.join(fields) + ") OUTPUT inserted.ID VALUES (" + ','.join(map(lambda x:'?', fields)) + ")"
    return s

def unzip_handler(source_file_id,fname,conn,dest_folder=None):
    
    (file_folder,file_name) = os.path.split(fname)
    dest_folder = file_folder if dest_folder is None else dest_folder
    
    with ZipFile(fname) as zf:
        zf.extractall(dest_folder)
    
    return (True,0)
    
                    


def csv_load(source_file_id,fname,conn,dest_table,header_end_text=None,footer_start_text=None,key_fields=None,**kwargs):
    # read entire file into memory
    f = open(fname,'rt')
    s = f.read()
    f.close()

    # identify payload, top & tail
    start_index = 0 if header_end_text is None else s.find(header_end_text)+len(header_end_text)
    if header_end_text is not None and start_index<len(header_end_text):    # note: find returns -1 if string not found
        error_text = "The text specified to indicate the end of the header is not found"
        logger.error(error_text)
        DataDogAPI.Event.create(title="Header not found error:", text=error_text, alert_type="error",tags=tags) 

        return (False, 0)
    else:
        end_index = len(s) if footer_start_text is None else start_index + s[start_index:].find(footer_start_text)
        if end_index<start_index:
            error_text = "The text specified to indicate the beginning of the footer is not found"
            logger.error(error_text)
            DataDogAPI.Event.create(title="Footer not found error:", text=error_text, alert_type="error",tags=tags) 
            return (False, 0)
            
    csv_str = s[start_index:end_index]
#    if csv_str[0] == ',':
#        csv_scsv_str.replace("\n,","\n")[1:]
    str_buf = StringIO(csv_str)
    
    # read as csv
    df = read_csv(str_buf, **kwargs)
    
    # format headings
    df = df.rename(columns=format_column_heading)
    
    # parse csv headings and verify they match destination table
    df = df.rename(columns=format_column_heading)
    
    # add source file identifier
    df['source_file_id'] = source_file_id

    # determine key fields and data fields
    if key_fields is None:
        key_fields = []
    else:        
        if not set(key_fields).issubset(df.keys()):
            error_text = 'key_fields must be a subset of csv fields. key_fields: %s, csv fields: %s'% str(key_fields), str(df.keys())
            logger.error(error_text)
            DataDogAPI.Event.create(title="key_fields error:", text=error_text, alert_type="error",tags=tags) 
            return (False,0)
    
    
    
#        
#    else:
#        logger.warning('')        

    # check for duplicates/conflicts


    # fields to compare

    # return dataframe if destination table is not specified
    if dest_table is None:
        return df

    # merge into database
    sql = sql_merge_statement(dest_table,df.keys(),key_fields)
    
    sql_params = map(tuple, df.values)
    # convert nans to None so insert/update will work correctly    
    sql_params = map(lambda sp: map(lambda x: None if x.__class__ is float and isnan(x) else x,sp),sql_params)    
    
    #try:    
    # merge to database if any records found
    if len(df) > 0:         
        curs = conn.cursor()
        curs.executemany(sql, sql_params)
        conn.commit()
        curs.close()
    #except:
    #    raise
    #    return (df, sql)
    
    return (True,len(df))


def sql_mdff_merge_statement(dest_table,fields,merge_keys):
    
    # data_fields = list(set(fields).difference(merge_keys))        
    fields = map(lambda x: "[" + x + "]", fields)
    merge_keys = map(lambda x: "[" + x + "]", merge_keys)
    # data_fields = map(lambda x: "[" + x + "]", data_fields)
    
    if len(merge_keys) > 0:
        s = "MERGE " + dest_table + "\nUSING (\n\tVALUES(" + ','.join(map(lambda x:'?', fields)) + ")\n)"
        s = s + " AS src (" + ','.join(fields) + ")\n ON "
        s = s + ' AND '.join(map(lambda x: ("("+dest_table+".{c} = src.{c} OR ("+dest_table+".{c} is null and src.{c} is null))").format(c=x), merge_keys))
        s = s + "\nWHEN MATCHED THEN \n\tUPDATE SET " + fields[0] + "=" + dest_table + "." + fields[0] # + ','.join(map(lambda x: "{c} = src.{c}".format(c=x), data_fields))
        s = s + "\nWHEN NOT MATCHED THEN \n\tINSERT (" + ','.join(fields) + ")"
        s = s + "\n\tVALUES (" + ','.join(map(lambda x:'src.'+x, fields)) + ")\n"    
        s = s + "\nOUTPUT inserted.ID;"
    else:
        s = "INSERT INTO " + dest_table + "(" + ','.join(fields) + ") OUTPUT inserted.ID VALUES (" + ','.join(map(lambda x:'?', fields)) + ")"
    return s


def throws_a(func, *exceptions):
    try:
        func()
        return False
    except exceptions or Exception:
        return True

# checks that all tokens comply with MDFF requirements on length, data type, manadatory etc.
def mdf_length_type_check(toks,fields,data_types,lengths,mandatory):    
    if not len(fields) == len(data_types) == len(lengths) == len(mandatory):
        raise Exception("Invalid configuration passed to mdf_length_type_check. Lengths are %d %d %d %d",len(fields), len(data_types), len(lengths), len(mandatory))
    if not len(fields) == len(toks):
        error_text = 'Invalid token stream in meter data file. Too many or too few tokens. Expecting %d, found %d'% len(fields), len(toks[1:])
        logger.error(error_text)
        DataDogAPI.Event.create(title="Invalid token stream error:", text=error_text, alert_type="error",tags=tags)         
        return (False,[])
    tok_length = map(len,toks)
    vals = []        
    
    for i in range(0,len(fields)):  # check each field
        # warn if leading or trailing spaces, but remove and continue
        if toks[i].strip() <> toks[i]:
            logger.warn('Leading or trailing whitespace found in field %s. Found: "%s"', fields[i], toks[i])
            toks[i] = toks[i].strip()
            tok_length[i] = len(toks[i])
        
        if mandatory[i] and tok_length[i]==0:   # for missing mandatory values
            error_text = 'Missing a mandatory value in field %s'% fields[i]
            logger.error(error_text)
            DataDogAPI.Event.create(title="Missing a mandatory value error:", text=error_text, alert_type="error",tags=tags)         
            return (False,[])
        if data_types[i] == 'C' and tok_length[i] not in (0,lengths[i]):
            error_text = 'Fixed length string of incorrect length in field %s. Expecting %d characters, found "%s"'% fields[i], lengths[i], toks[i]
            logger.error(error_text)
            DataDogAPI.Event.create(title="Incorrect length error:", text=error_text, alert_type="error",tags=tags)         
            return (False,[])
        if data_types[i] == 'V' and tok_length[i] > lengths[i]:
            error_text = 'Value exceeds maximum allowed length in field %s. Expecting %d characters, found %d. Value is "%s"'% fields[i], lengths[i], tok_length[i], toks[i]
            logger.error(error_text)
            DataDogAPI.Event.create(title="Exceeds maximum allowed length:", text=error_text, alert_type="error",tags=tags) 
            return (False,[])
        if data_types[i] == 'D' and tok_length[i] not in (0,lengths[i]):
            error_text = 'Datetime value of incorrect length in field %s. Expecting %d characters, found "%s"'% fields[i], lengths[i], toks[i]
            logger.error(error_text)
            DataDogAPI.Event.create(title="Datetime value of incorrect:", text=error_text, alert_type="error",tags=tags) 
            return (False,[])
        if data_types[i] == 'D' and tok_length[i] != 0:     # check that toks[i] contains a valid date
            try:
                if lengths[i] > 12:
                    s = int(toks[i][12:14])
                else:
                    s = 0
                if lengths[i] > 8:
                    h = int(toks[i][8:10])
                    m = int(toks[i][10:12])
                else:
                    h = m = 0
                datetime(int(toks[i][0:4]),int(toks[i][4:6]),int(toks[i][6:8]),h,m,s)
            except ValueError:
                error_text = 'Invalid date value. Expecting Datetime(%d), found "%s"'% lengths[i], toks[i]
                logger.error(error_text)
                DataDogAPI.Event.create(title="Invalid date value:", text=error_text, alert_type="error",tags=tags)
                return (False,[])
        if data_types[i] == 'N' and int(lengths[i]) == lengths[i]:      # expecting integer
            if tok_length[i] > lengths[i]:
                error_text = 'Value exceeds maximum allowed length in field %s. Expecting max of %d characters, found %d. Value is "%s"'% fields[i], lengths[i], tok_length[i], toks[i]
                logger.error(error_text)
                DataDogAPI.Event.create(title="Value exceeds maximum allowed length:", text=error_text, alert_type="error",tags=tags)
                return (False,[])
            if len(toks[i]) > 0 and throws_a(lambda: int(toks[i]), ValueError):
                error_text = 'Invalid value encountered in field %s. Expecting integer, found "%s"', fields[i], toks[i]
                logger.error(error_text)
                DataDogAPI.Event.create(title="Invalid value error:", text=error_text, alert_type="error",tags=tags)                
                return (False,[])
        if data_types[i] == 'N' and int(lengths[i]) != lengths[i]:      # expecting float
            (pre,post) = map(int,str(lengths[i]).split('.')) # max digits expected before & after decimal place
            s = toks[i].split('.')            
            if len(s[0]) > pre or (len(s)>1 and len(s[1]) > post):
                error_text = 'Value exceeds maximum allowed length or precision in field %s. Expecting Numeric(%d.%d), found "%s"'% fields[i], pre, post, toks[i]
                logger.error(error_text)
                DataDogAPI.Event.create(title="Value exceeds maximum allowed length:", text=error_text, alert_type="error",tags=tags)                
                return (False,[])
            if len(s)>2 or (len(s[0]) > 0 and throws_a(lambda: int(s[0]), ValueError)) or (len(s)==2 and (throws_a(lambda: int(s[1]), ValueError) or int(s[1])<0)) or throws_a(lambda: float(toks[i]), ValueError):
                error_text = 'Invalid value encountered in field %s. Expecting Numeric(%d.%d), found "%s"'% fields[i], pre, post, toks[i]
                logger.error(error_text)
                DataDogAPI.Event.create(title="Invalid value encountered in field:", text=error_text, alert_type="error",tags=tags)                                
                return (False,[])
        
        if data_types[i] in ("C","V"):
            val = toks[i]
        elif data_types[i] == "D" and len(toks[i])==0:  # null date
            val = None
        elif data_types[i] == "D" and len(toks[i])>0:
            val = datetime(int(toks[i][0:4]),int(toks[i][4:6]),int(toks[i][6:8]),h,m,s)
        elif data_types[i] == "N" and int(lengths[i]) != lengths[i] and len(toks[i])>0:
            val = Decimal(toks[i])
        elif data_types[i] == "N" and int(lengths[i]) == lengths[i] and len(toks[i])>0:
            val = int(toks[i])
        elif data_types[i] == "N" and len(toks[i])==0:
            val = None
        else:
            error_text = 'Unhandled data type encountered in field %s'% fields[i]
            logger.error(error_text)
            DataDogAPI.Event.create(title="Unhandled data type:", text=error_text, alert_type="error",tags=tags)                                
            return (False,[])
            
        vals.append(val)
            
    return (True,vals)
                

def process_MDF_100(conn,version_header,toks,last_rec_ind,source_file_id):
    valid_after = [None]    
    table_name = 'NEMMDF_Staging_100'
    fields = ['VersionHeader','DateTime','FromParticipant','ToParticipant']
    merge_keys = []
    data_types = 'VDVV'
    lengths = [5,12,10,10]
    mandatory = [True,True,True,True]
    
    
    if not last_rec_ind in valid_after:      # check for file blocking errors
        error_text = 'Meter data file blocking error'
        logger.error(error_text)
        DataDogAPI.Event.create(title="Meter data file error:", text=error_text, alert_type="error",tags=tags)                                
        return (False,[])
    
    # allocate tokens, confirm data types and field lengths as required
    (status,vals) = mdf_length_type_check(toks,fields,data_types,lengths,mandatory)
    if not status:
        return (False,[])
        
    # specific checks    
    if (version_header is not None) and version_header != toks[0]:
        error_text = 'VersionHeader in filename and 100 record do not match. Filename has %s and 100-record has %s'% version_header, toks[0]
        logger.error(error_text)
        DataDogAPI.Event.create(title="VersionHeader not match:", text=error_text, alert_type="error",tags=tags)                                
        return (False,[])
    if toks[0] not in ("NEM12","NEM13"):
        error_text = 'VersionHeader in 100 record is invalid. Requires NEM12 or NEM13, found %s'% toks[0]
        logger.error(error_text)
        DataDogAPI.Event.create(title="VersionHeader invalid:", text=error_text, alert_type="error",tags=tags)                                        
        return (False,[])
            
    # no merge keys so just insert to database
    sql = sql_mdff_merge_statement(table_name,fields+['source_file_id'],merge_keys)
    curs = conn.cursor()
    curs.execute(sql, tuple(vals)+(source_file_id,))
    thisid = curs.fetchone()[0]
    curs.close()
    vals.append(thisid)
    return (True,vals)

def process_MDF_200(conn,version_header,toks,last_rec_ind,last100,source_file_id):
    valid_after = ['100','300','400','500']
    table_name = 'NEMMDF_Staging_200'
    fields = ['NMI','NMIConfiguration','RegisterID','NMISuffix','MDMDataStreamIdentifier','MeterSerialNumber','UOM','IntervalLength','NextScheduledReadDate']
    merge_keys = []
    data_types = 'CVVCCVVND'
    lengths = [10,240,10,2,2,12,5,2,8]
    mandatory = [True,True,False,True,False,False,True,True,False]
    
    
    if not last_rec_ind in valid_after:      # check for file blocking errors
        error_text = 'Meter data file blocking error'
        logger.error(error_text)
        DataDogAPI.Event.create(title="File blocking error:", text=error_text, alert_type="error",tags=tags)                                                
        return (False,[])
    
    # allocate tokens, confirm data types and field lengths as required
    (status,vals) = mdf_length_type_check(toks,fields,data_types,lengths,mandatory)    
    if not status:
        return (False,[])
        
    # specific checks
    # valid NMIConfiguration
    if not all(map(lambda x: match(r'[A-HJ-NP-Z][1-9A-HJ-NP-Z]',x) is not None,[vals[1][i:i+2] for i in xrange(0, len(vals[1]), 2)])):
        error_text = 'Invalid NMI Configuration. Found %s'% vals[1]
        logger.error(error_text)
        DataDogAPI.Event.create(title="Invalid NMI Configuration:", text=error_text, alert_type="error",tags=tags)
        return (False,[])
    # valid RegisterID?
    # valid NMISuffix
    if match(r'[A-HJ-NP-Z][1-9A-HJ-NP-Z]',vals[3]) is None:
        error_text = 'Invalid NMI Suffix. Found %s'%vals[3]
        logger.error(error_text)
        DataDogAPI.Event.create(title="Invalid NMI Suffix:", text=error_text, alert_type="error",tags=tags)
        return (False,[])
    # valid MDMDataStreamIdentifier?
    # valid UOM
    if not vals[6].lower() in ('mwh','kwh','wh','mvarh','kvarh','varh','mvar','kvar','var','mw','kw','w','mvah','kvah','vah','mva','kva','va','kv','v','ka','a','pf'):
        error_text = 'Invalid UOM encountered. Found value %s'% vals[6]
        logger.error(error_text)
        DataDogAPI.Event.create(title="Invalid UOM:", text=error_text, alert_type="error",tags=tags)
        return (False,[])       
    # valid IntervalLength
    if not vals[7] in (1,5,10,15,30):
        error_text = 'Invalid IntervalLength value encountered. Found %d', vals[7]
        logger.error(error_text)
        DataDogAPI.Event.create(title="Invalid IntervalLength value:", text=error_text, alert_type="error",tags=tags)
        return (False,[])
            
    # insert record to database, returning id
    sql = sql_mdff_merge_statement(table_name,fields+['staging_100_id','source_file_id'],merge_keys)
    curs = conn.cursor()
    curs.execute(sql, tuple(vals)+(last100[-1],source_file_id))
    thisid = curs.fetchone()[0]
    curs.close()
    vals.append(thisid)
    return (True,vals)

def process_MDF_300(conn,version_header,toks,last_rec_ind,last100,last200,source_file_id):
    valid_after = ['200','300','400','500']
    table_name = 'NEMMDF_Staging_300'
    # print last200
    n_readings = 1440 / last200[7]
    qm = 1+n_readings
    fields = ['IntervalDate']+ ['IntervalValue'+str(i) for i in range(1,n_readings+1)] +['QualityMethod','ReasonCode','ReasonDescription','UpdateDateTime','MSATSLoadDateTime']
    db_fields = ['IntervalDate']+ ['IntervalValue'+str(i) for i in range(1,n_readings+1)] +['UpdateDateTime','MSATSLoadDateTime']
    
    data_types = 'D' + 'N'*n_readings + 'VNVDD'
    if last200[6][0].upper() == 'M':
        reading_length = 15.6
    elif last200[6][0].upper() == 'K':
        reading_length = 15.3
    elif last200[6][0].upper() == 'p':
        reading_length = 15.2
    else:
        reading_length = 15
            
    lengths = [8]+ [reading_length for i in range(1,n_readings+1)] +[3,3,240,14,14]
    mandatory = [True] + [True for i in range(1,n_readings+1)] +[True,False,False,False,False]
        
    if not last_rec_ind in valid_after:      # check for file blocking errors
        error_text = 'Meter data file blocking error'
        logger.error(error_text)
        DataDogAPI.Event.create(title="File blocking error:", text=error_text, alert_type="error",tags=tags)
        return (False,[])
    
    # allocate tokens, confirm data types and field lengths as required
    (status,vals) = mdf_length_type_check(toks,fields,data_types,lengths,mandatory)
    if not status:
        return (False,[])
        
    # specific checks
    
    # valid qualitymethod
    if toks[qm] not in ('A','N','V') and match(r"[AEFNSV][1567][1-9]",toks[qm]) is None:    # note: detects most but not all illegal values
        error_text = 'Invalid QualityMethod value in 300 row. Found %s'% toks[qm]
        logger.error(error_text)
        DataDogAPI.Event.create(title="Invalid QualityMethod value:", text=error_text, alert_type="error",tags=tags)
        return (False,[])
    # reasoncode valid if provided
    if len(toks[qm+1])>0 and (vals[qm+1] < 0 or vals[qm+1]>94):
        error_text = 'Invalid ReasonCode supplied in 300 row. Found %s'% toks[qm+1]
        logger.error(error_text)
        DataDogAPI.Event.create(title="Invalid ReasonCode supplied:", text=error_text, alert_type="error",tags=tags)
        return (False,[])
    # no reasoncode if qualityflag is V
    if (vals[qm+1] is not None and toks[qm][0]=='V') or (vals[qm+1] is None and toks[qm][0] in ('F','S')):
        error_text = 'In 300 row, ReasonCode supplied with quality "V" or ReasonCode not supplied with Quality "F" or "S". Quality flag %s, ReasonCode %s'% toks[qm][0], toks[qm+1]
        logger.error(error_text)
        DataDogAPI.Event.create(title="ReasonCode error:", text=error_text, alert_type="error",tags=tags)
        return (False,[])        
    # reasondescription supplied if reasoncode = 0
    if len(vals[qm+2]) < 1 and vals[qm+1]==0:
        error_text = 'Missing ReasonDescription where ReasonCode is 0 in 300 row'
        logger.error(error_text)
        DataDogAPI.Event.create(title="Missing ReasonDescription:", text=error_text, alert_type="error",tags=tags)        
        return (False,[])
    # updatedatetime provided unless qualitymethod is N
    if vals[qm+3] is None and vals[qm][0] != 'N':
        error_text = 'Missing UpdateDateTime in 300 row where Quality is not "N"'
        logger.error(error_text)
        DataDogAPI.Event.create(title="Missing UpdateDateTime:", text=error_text, alert_type="error",tags=tags)                
        return (False,[])
            
    # merge quality record and return id
    sql = sql_mdff_merge_statement(table_name,db_fields+['staging_200_id','source_file_id'],[])
    curs = conn.cursor()
    insert_vals = vals[0:n_readings+1] + vals[n_readings+4:]
    insert_vals[0] = str(insert_vals[0])
    for t in range(1,n_readings+1):
        insert_vals[t] = float(insert_vals[t])
    curs.execute(sql, tuple(insert_vals)+(last200[-1],source_file_id))
    thisid = curs.fetchone()[0]
    curs.close()
    vals.append(thisid)
    
    # insert dummy 400 record to hold quality information
    if toks[qm][0] != 'V':
        (tf,res) = process_MDF_400(conn,version_header,['1',str(n_readings),toks[qm],toks[qm+1],toks[qm+2]],'300',last100,last200,vals,None,source_file_id)
        if not tf:
            return (False,[])
    

            
#    sql = sql_mdff_merge_statement('NEM12_QualityDetails',['QualityMethod','ReasonCode','ReasonDescription'],['QualityMethod','ReasonCode','ReasonDescription'])
#    curs = conn.cursor()
#    curs.execute(sql, tuple(vals[qm:qm+3]))
#    qual_id = curs.fetchone()[0]
#    
#    # insert record to database, returning id
#    sql = sql_mdff_merge_statement(table_name,['StreamDetailsID','IntervalDate','FileDetailsID','UpdateDateTime','MSATSLoadDateTime'],[])
#    curs = conn.cursor()
#    curs.execute(sql, tuple([last200[-1], str(vals[0]), last100[-1], vals[-2], vals[-1]]))
#    thisid = curs.fetchone()[0]
#    curs.close()
#    vals.append(thisid)
#    
#    # insert all readings to interval table    
#    sql = "INSERT NEM12_IntervalData (StreamDayDetailsID,IntervalNumber,Value,QualityDetailsID) VALUES (?,?,?,?)"
#    curs = conn.cursor()
#    insert_vals = [(thisid, n+1, float(vals[n+1]), qual_id) for n in arange(0,n_readings)]
#    
#    curs.executemany(sql, tuple(insert_vals))
    
    # return value
    return (True,vals)

def process_MDF_400(conn,version_header,toks,last_rec_ind,last100,last200,last300,last400,source_file_id):
    valid_after = ['300','400']    
    table_name = 'NEMMDF_Staging_400'
    fields = ['StartInterval','EndInterval','QualityMethod','ReasonCode','ReasonDescription']
    
    data_types = 'NNVNV'
    lengths = [4,4,3,3,240]
    mandatory = [True,True,True,False,False]
    qm = 2
    
    if not last_rec_ind in valid_after:      # check for file blocking errors
        error_text = 'Meter data file blocking error'
        logger.error(error_text)
        DataDogAPI.Event.create(title="File blocking error:", text=error_text, alert_type="error",tags=tags)
        return (False,[])
    
    # allocate tokens, confirm data types and field lengths as required
    (status,vals) = mdf_length_type_check(toks,fields,data_types,lengths,mandatory)
    if not status:
        return (False,[])
        
    # specific checks    
    if vals[0] < 1 or vals[1] < vals[0] or vals[1] > 1440/last200[7]:
        error_text = 'Illegal StartInterval/EndInterval values. StartInterval = %d, EndInterval = %d, IntervalLength = %d'% vals[0], vals[1],last200[7]
        logger.error(error_text )
        DataDogAPI.Event.create(title="Illegal StartInterval/EndInterval values:", text=error_text, alert_type="error",tags=tags)
        return (False,[])        
    if (last_rec_ind != '400' and vals[0] != 1) or (last_rec_ind == '400' and vals[0] != last400[1]+1):
        error_text = 'Mismatch between StartInterval and preceeding row in 400-record'
        logger.error(error_text)
        DataDogAPI.Event.create(title="Mismatch StartInterval and preceeding row:", text=error_text, alert_type="error",tags=tags)
        return (False,[])
    # valid qualitymethod
    if toks[qm] not in ('A','N') and match(r"[AEFNS][1567][1-9]",toks[qm]) is None:    # note: detects most but not all illegal values
        error_text = 'Invalid QualityMethod value in 400 row. Found %s'% toks[qm]
        logger.error(error_text)
        DataDogAPI.Event.create(title="Invalid QualityMethod value:", text=error_text, alert_type="error",tags=tags)
        return (False,[])
    # reasoncode valid if provided
    if len(toks[qm+1])>0 and (vals[qm+1] < 0 or vals[qm+1]>94):
        error_text = 'Invalid ReasonCode supplied in 400 row. Found %s'% toks[qm+1]
        logger.error(error_text)
        DataDogAPI.Event.create(title="Invalid ReasonCode supplied:", text=error_text, alert_type="error",tags=tags)
        return (False,[])
    # no reasoncode if qualityflag is V
    if (vals[qm+1] is not None and toks[qm][0]=='V') or (vals[qm+1] is None and toks[qm][0] in ('F','S')):
        error_text = 'In 400 row, ReasonCode supplied with quality "V" or ReasonCode not supplied with Quality "F" or "S". Quality flag %s, ReasonCode %s'% toks[qm][0], toks[qm+1]
        logger.error(error_text)
        DataDogAPI.Event.create(title="ReasonCode error:", text=error_text, alert_type="error",tags=tags)
        return (False,[])        
    # reasondescription supplied if reasoncode = 0
    if len(vals[qm+2]) < 1 and vals[qm+1]==0:
        error_text = 'Missing ReasonDescription where ReasonCode is 0 in 300 row'
        logger.error(error_text)
        DataDogAPI.Event.create(title="Missing ReasonDescription:", text=error_text, alert_type="error",tags=tags)
        return (False,[])
    # last300 had qualityflag V, or its a single-record 400 row
  
    if last300[-6][0] != "V" and (vals[0] != 1 or vals[1] != 1440/last200[7]):
        error_text = '400-record found after 300-row with quality not V'
        logger.error(error_text)
        DataDogAPI.Event.create(title="400-record found after 300-row:", text=error_text, alert_type="error",tags=tags)        
        return (False,[])
            
    # merge quality record to database, returning id
    sql = sql_mdff_merge_statement(table_name,fields+['staging_300_id','source_file_id'],[])
    curs = conn.cursor()
    curs.execute(sql, tuple(vals)+(last300[-1],source_file_id))
    thisid = curs.fetchone()[0]
    curs.close()
    vals.append(thisid)
    
#    # update interval records in staging table
#    sql = 'UPDATE NEM12_IntervalData SET QualityDetailsID = ? WHERE IntervalNumber >= ? AND IntervalNumber <= ? AND StreamDayDetailsID = ?'
#    curs = conn.cursor()
#    curs.execute(sql, (thisid, vals[0], vals[1], last300[-1]))
#    curs.close()
        
    return (True,vals)
    

def process_MDF_500(conn,version_header,toks,last_rec_ind,last100,last200,last300,last400,source_file_id):
    valid_after = ['300','400','500']    
    table_name = 'NEMMDF_Staging_500'
    fields = ['TransCode','RetServiceOrder','ReadDateTime','IndexRead']
    data_types = 'CVDV'
    lengths = [1,15,14,15]
    mandatory = [True,False,False,False]
        
    if not last_rec_ind in valid_after:      # check for file blocking errors
        error_text = 'Meter data file blocking error'
        logger.error(error_text)
        DataDogAPI.Event.create(title="File blocking error:", text=error_text, alert_type="error",tags=tags)        
        return (False,[])
    
    # allocate tokens, confirm data types and field lengths as required
    (status,vals) = mdf_length_type_check(toks,fields,data_types,lengths,mandatory)
    if not status:
        return (False,[])
        
    # specific checks    
    if vals[0] not in ("A","C","G","D","E","N","O","S","R"):
        logger.error('')
        return (False,[])
    
            
    # insert record to database, returning id
    sql = sql_mdff_merge_statement(table_name,fields+['staging_300_id','source_file_id'],[])
    curs = conn.cursor()    
    curs.execute(sql, tuple(vals+[last300[-1],source_file_id]))
    thisid = curs.fetchone()[0]
    curs.close()
    vals.append(thisid)
    
    
    return (True,vals)


def process_MDF_900(conn,version_header,toks,last_rec_ind, source_file_id):
    valid_after = ['300','400','500']
    if not last_rec_ind in valid_after:      # check for file blocking errors
        error_text = 'Meter data file blocking error'
        logger.error(error_text)
        DataDogAPI.Event.create(title="File blocking error:", text=error_text, alert_type="error",tags=tags)                
        return (False,[])
        
    
    curs = conn.cursor()
    curs.execdirect('EXEC MeterDataDB.dbo.MergeNEMMDF_Staging '+ str(source_file_id) )
    curs.close()
    conn.commit()
        
    return (True,[])
    
def process_MDF_250(conn,version_header,toks,last_rec_ind,last100):
    return (True,[])

def process_MDF_550(conn,version_header,toks,last_rec_ind,last250):
    return (True,[])

def aemo_meter_data_handler(source_file_id,fname,conn):
    (fpath,filename) = os.path.split(fname)
    (filename,fileext) = os.path.splitext(filename)
    # is file zipped? if yes, unzip to temp folder and reset fname
    # if fileext == '.zip':
        
    
    # is file XML? extract csv data
    
    
    # determine if file has a valid filename for a NEM12 or NEM13 file
    s = filename.split('#')
    if len(s) == 4 and s[0] in ("NEM12","NEM13") and len(s[1])<=36 and len(s[2])<=10 and len(s[3])<=10:
        (version_header,sender_id_val,from_participant,to_participant) = s
    else:      
        logger.warning('Invalid file name encountered %s. Expecting NEMXX#IDENTIFIER_LEN36#FROMPARTIC#TOPARTICIP',filename)
        version_header = sender_id_val = from_participant = to_participant = None
        
    # process file
    with open(fname, 'rt') as f:
        line_number = 0        
        last_rec_ind = None
        last100 = last200 = last250 = last300 = last400 = None
        
        while last_rec_ind != '900':
            toks = f.readline().strip().split(',')    # read and split next line
            rec_ind = toks[0].strip()

            if rec_ind == '100':
                status,last100 = process_MDF_100(conn,version_header,toks[1:],last_rec_ind,source_file_id)
            elif rec_ind == '200':
                status,last200 = process_MDF_200(conn,version_header,toks[1:],last_rec_ind,last100,source_file_id)
            elif rec_ind == '300':
                status,last300 = process_MDF_300(conn,version_header,toks[1:],last_rec_ind,last100,last200,source_file_id)
            elif rec_ind == '400':
                status,last400 = process_MDF_400(conn,version_header,toks[1:],last_rec_ind,last100,last200,last300,last400,source_file_id)
            elif rec_ind == '500':
                status,res = process_MDF_500(conn,version_header,toks[1:],last_rec_ind,last100,last200,last300,last400,source_file_id)
            elif rec_ind == '900':
                status,res = process_MDF_900(conn,version_header,toks[1:],last_rec_ind,source_file_id)
            elif rec_ind == '250':
                status,last250 = process_MDF_250(conn,version_header,toks[1:],last_rec_ind,last100)
            elif rec_ind == '550':
                status,res = process_MDF_550(conn,version_header,toks[1:],last_rec_ind,last100,last250)
            else:
                error_text = 'Meter data file error. Invalid record indicator found in line %d: "%s"'% line_number, rec_ind
                logger.error(error_text)
                DataDogAPI.Event.create(title="Meter data file error:", text=error_text, alert_type="error",tags=tags)                
                status = False
            
            if status == False:
                error_text = 'Error encountered processing file %s. The error occurred at line number %d'% fname, line_number
                logger.error(error_text)
                DataDogAPI.Event.create(title="Error encountered processing file:", text=error_text, alert_type="error",tags=tags)                
                return (False,0)
                

            
            # prepare for next iteration of loop
            last_rec_ind = rec_ind
            line_number = line_number + 1
        
        if len(f.read().strip()) > 0:
            error_text = 'Meter data file blocking error. File contents found following the end of a 100-900 block (line %d)'% line_number
            logger.error(error_text)
            DataDogAPI.Event.create(title="Meter data file blocking error:", text=error_text, alert_type="error",tags=tags)                
            raise
            
    conn.commit()
    
    return (True, line_number)
    
def spmdf_handler(source_file_id,fname,conn,header_end_text=None,footer_start_text=None,fixed_column_vals={}, truncateNMI=False, map_col_names=None, flip_signs=[],**hp):
    # read entire file into memory
    f = open(fname,'rt')
    s = f.read()
    f.close()

    # identify payload, top & tail
    start_index = 0 if header_end_text is None else s.find(header_end_text)+len(header_end_text)
    if header_end_text is not None and start_index<len(header_end_text):    # note: find returns -1 if string not found
        error_text = "The text specified to indicate the end of the header is not found"
        logger.error(error_text)
        DataDogAPI.Event.create(title="Header not found:", text=error_text, alert_type="error",tags=tags)
        return (False, 0)
    else:
        end_index = len(s) if footer_start_text is None else start_index + s[start_index:].find(footer_start_text)
        if end_index<start_index:
            error_text = "The text specified to indicate the beginning of the footer is not found"
            logger.error(error_text)
            DataDogAPI.Event.create(title="Footer not found:", text=error_text, alert_type="error",tags=tags)
            return (False, 0)
            
    csv_str = s[start_index:end_index]
#    if csv_str[0] == ',':
#        csv_scsv_str.replace("\n,","\n")[1:]
    str_buf = StringIO(csv_str)
    
    # read as csv
    df = read_csv(str_buf, **hp)
    
    
    for c in fixed_column_vals:
        df[c] = fixed_column_vals[c]
            
    if map_col_names is not None:
        df.rename(columns = map_col_names, inplace = True)
        
    for f in flip_signs:
        df[f][df[f] != 0] = df[f][df[f] != 0]*-1
    
    # ensure field names are all valid
    valid_fields = ['MeterRef','NMI','StreamRef','MeterSerialNumber',
                    'Date','Time','PeriodID','Timestamp','TimestampType','IntervalLength',
                    'Net_KWH','Net_KVARH','Exp_KWH','Imp_KWH','Exp_KVARH','Imp_KVARH','KW','KVA',
                    'MDPUpdateDateTime','QualityCode']
                    
    # check for invalid fields
    fields = set(df.keys())
    if not fields.issubset(valid_fields):
        bad = fields - set(valid_fields)
        error_text = 'Invalid fields names encountered reading file (field names are case-sensitive): ' + ','.join(bad)
        logger.error(error_text)
        DataDogAPI.Event.create(title="Invalid fields names:", text=error_text, alert_type="error",tags=tags)
        return (False, df if conn is None else 0)
    


    # ensure that time interval is properly specified. May be
        # timestamp + timestamptype + intervallength, or
        # date + periodid + intervallength, or
        # date + time + intervallength

    if not 'IntervalLength' in fields:
        error_text = "The compulsory field IntervalLength is missing"
        logger.error(error_text)
        DataDogAPI.Event.create(title="IntervalLength is missing:", text=error_text, alert_type="error",tags=tags)
        return (False,0)
    if not (fields.issuperset(['Timestamp','TimestampType']) or fields.issuperset(['Date','PeriodID']) or fields.issuperset(['Date','Time','TimestampType'])):
        error_text = "Time Interval incorrectly specified. Needs either Timestamp+TimestampType, Date+PeriodID, or Date+Time"
        logger.error(error_text)
        DataDogAPI.Event.create(title="Time Interval incorrectly specified:", text=error_text, alert_type="error",tags=tags)
        return (False,0)
    # TODO: check that both PeriodID and Time are not supplied
    if ('Timestamp' in fields and 'Date' in fields) or ('PeriodID' in fields and 'Time' in fields): 
        error_text = "Duplicate time interval information specified. Needs either Timestamp+TimestampType, Date+PeriodID, or Date+Time"
        logger.error(error_text)
        DataDogAPI.Event.create(title="Duplicate time interval information:", text=error_text, alert_type="error",tags=tags)
        return (False,0)
        
    # ensure that meter info is properly specified. Needs either
        # MeterRef only
        # NMI + StreamRef
    if not (fields.issuperset(['MeterRef']) or fields.issuperset(['NMI','StreamRef'])):
        error_text = "Meter information is incorrectly specified. Needs either MeterRef or NMI+StreamRef"
        logger.error(error_text)
        DataDogAPI.Event.create(title="Meter information is incorrectly specified:", text=error_text, alert_type="error",tags=tags)
        return (False, 0)
    if 'MeterRef' in fields and 'NMI' in fields:
        error_text = "Duplicate meter information specified. Needs either MeterRef only or NMI+StreamRef"
        logger.error(error_text)
        DataDogAPI.Event.create(title="Duplicate meter information specified:", text=error_text, alert_type="error",tags=tags)
        return (False, 0)
        
    # ensure that there is at least one value field
    if len(fields.intersection(['Net_KWH','Net_KVARH','Exp_KWH','Imp_KWH','Exp_KVARH','Imp_KVARH', 'KW', 'KVA']))==0:
        error_text = "There must be at least one value field included in the file"
        logger.error(error_text)
        DataDogAPI.Event.create(title="Value field missing:", text=error_text, alert_type="error",tags=tags)
        return (False, 0)
        
    # Deal with 24:00 and 24:00:00 Times
    
    
    # TODO: type checks
    
    
    # validation checks
    if not set(df['IntervalLength']).issubset(set([15,30])):
        error_text = "IntervalLength must be integer with values 15 and 30"
        logger.error(error_text)
        DataDogAPI.Event.create(title="IntervalLength error:", text=error_text, alert_type="error",tags=tags)
        return (False, 0)
    if 'QualityCode' in fields and not set(df['QualityCode']).issubset(set([None,'A','E','F','I','S','X'])):
        error_text = "QualityCode must be A,E,F,I,S or X. Found " + ','.join(set(df['QualityCode']) - set([None,'A','E','F','I','S','X']))
        logger.error(error_text)
        DataDogAPI.Event.create(title="QualityCode error:", text=error_text, alert_type="error",tags=tags)
        return (False, 0)
    
    # add source file identifier
    df['source_file_id'] = source_file_id

    # truncates NMI or MeterRef to first 10 characters
    if 'NMI' in fields and truncateNMI:
        df['NMI'] = map(lambda x: x[0:10], df['NMI'])
    if 'MeterRef' in fields and truncateNMI:
        df['MeterRef'] = map(lambda x: x[0:10], df['MeterRef'])


    # field-level validation
    if 'Imp_KWH' in fields and min(df['Imp_KWH']) < 0:
        error_text = "Negative Imp_KWH values detected. Consider flip_signs argument"
        logger.error(error_text)
        DataDogAPI.Event.create(title="Negative Imp_KWH:", text=error_text, alert_type="error",tags=tags)        
        return (False,0)
    if 'Exp_KWH' in fields and min(df['Exp_KWH']) < 0:
        error_text = "Negative Exp_KWH values detected. Consider flip_signs argument"
        logger.error(error_text)
        DataDogAPI.Event.create(title="Negative Exp_KWH:", text=error_text, alert_type="error",tags=tags)
        return (False,0)
    if 'Imp_KVARH' in fields and min(df['Imp_KVARH']) < 0:
        error_text = "Negative Imp_KVARH values detected. Consider flip_signs argument"
        logger.error(error_text)
        DataDogAPI.Event.create(title="Negative Imp_KVARH:", text=error_text, alert_type="error",tags=tags)
        return (False,0)
    if 'Exp_KVARH' in fields and min(df['Exp_KVARH']) < 0:
        error_text = "Negative Exp_KVARH values detected. Consider flip_signs argument"
        logger.error(error_text)
        DataDogAPI.Event.create(title="Negative Exp_KVARH:", text=error_text, alert_type="error",tags=tags)
        return (False,0)
    if 'KVA' in fields and min(df['KVA']) < 0:
        error_text = "Negative KVA values detected"
        logger.error(error_text)
        DataDogAPI.Event.create(title="Negative KVA:", text=error_text, alert_type="error",tags=tags)
        return (False,0)
        
    

    # merge into database
    sql = sql_merge_statement('SPMDF_Staging',df.keys(),[])
    
    sql_params = map(tuple, df.values)
    
    # convert nans to None so insert/update will work correctly        
    sql_params = map(lambda sp: map(lambda x: None if x.__class__ is float and isnan(x) else x,sp),sql_params)    
    
    if conn is None:
        return (True,df)
        

    # merge to database if any records found
    if len(df) > 0:         
        curs = conn.cursor()
        curs.executemany(sql, sql_params)
        conn.commit()
        curs.close()
        curs = conn.cursor()
        curs.execute('EXEC MeterDataDB.dbo.MergeSPMDF_Staging '+ str(source_file_id) )
        curs.close()            
        conn.commit()                        
    
    return (True,len(df))
        
