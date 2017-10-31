classdef MeterDataCalculator < handle
    %METERDATACALCULATOR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess = private)
        MeterPointID
        CurrentMeterRef
        MeterOpen
        MeterClose
        NumMeters
        RegionID
        ScenarioParams
        IMD
        TS
        TS15
        HHD
        
        Method
        MinDataPct
        IMDStartDate
        IMDEndDate
        
        DB_DSN
        DB_Usr
        DB_Pwd
        conn
        
    end
    
    methods
        function MDC = MeterDataCalculator(DB, Method, IMDStartDate,IMDEndDate)
            MDC.Method = Method.Method;
            MDC.MinDataPct = Method.MinDataPct;
            
            MDC.IMDStartDate = IMDStartDate;
            MDC.IMDEndDate = IMDEndDate;
                        
            MDC.DB_DSN = DB.DSN;
            MDC.DB_Usr = DB.Usr;
            MDC.DB_Pwd = DB.Pwd;
%             MDC.conn = database.ODBCConnection(DB.DSN, DB.Usr, DB.Pwd);
            MDC.conn = database(DB.DSN, DB.Usr, DB.Pwd);
%             if ~isconnection(MDC.conn)
%                 error('ODBC database connection could not be established. Check connection parameters');
%             end
            
            MDC.CurrentMeterRef = '';
            MDC.MeterPointID = NaN;
            MDC.NumMeters = NaN;
            
            
            MDC.TS = Round2Sec(IMDStartDate+1/48:1/48:IMDEndDate+1);
            MDC.TS15 = Round2Sec(IMDStartDate+1/96:1/96:IMDEndDate+1);
            MDC.IMD.Net_KWH = nan(size(MDC.TS));
            MDC.IMD.KW = nan(size(MDC.TS));
            MDC.IMD.KVA = nan(size(MDC.TS));
            MDC.IMD.Exp_KWH = nan(size(MDC.TS));
            MDC.IMD.Imp_KWH = nan(size(MDC.TS));
            MDC.IMD.KW15 = nan(size(MDC.TS));
            MDC.IMD.KVA15 = nan(size(MDC.TS));            
            IMD.Exp_KVARH = nan(size(MDC.TS));
            IMD.Exp_KVA15 = nan(size(MDC.TS));
            IMD.SD = nan;
            
            prepareHalfHourDefs(MDC)
        end
        
        function prepareHalfHourDefs(MDC)
            % Basic data
            % TODO: get ACT public holidays sorted, and check if
            % all definitions are based on official public hols
%             conn = database.ODBCConnection('MarketData','','');
            conn = database('MarketData','','');
            setdbprefs('DataReturnFormat','table');
            curs = exec(conn, 'SELECT [Date],[Official_NSW],[Official_VIC],[Official_SA],[Official_QLD],[Official_TAS] FROM [MarketData].[dbo].[Public_Holidays]');
            curs = fetch(curs);
            d = curs.Data;
            d.Date = datenum(d.Date, 'yyyy-mm-dd');
            
            close(conn);
            PubHols.Hobart = d.Date(cell2mat(d.Official_TAS)==1);
            PubHols.Melbourne = d.Date(cell2mat(d.Official_VIC)==1);
            PubHols.Sydney = d.Date(cell2mat(d.Official_NSW)==1);
            PubHols.Canberra = d.Date(cell2mat(d.Official_NSW)==1);
            PubHols.Brisbane = d.Date(cell2mat(d.Official_QLD)==1);
            PubHols.Adelaide = d.Date(cell2mat(d.Official_SA)==1);
            
            % Basic time definitions - AEST
            TS = MDC.TS;
            AEST.DS = floor(TS-1/48);
            [AEST.YY,AEST.MM,AEST.DD] = datevec(AEST.DS);
            AEST.QQ = ceil(AEST.MM./3);
            AEST.HH = round((TS - AEST.DS)*48);
            AEST.isWeekday = ismember(weekday(AEST.DS),[2,3,4,5,6]);
            AEST.isSaturday = weekday(AEST.DS)==7;
            AEST.isSunday = weekday(AEST.DS)==1;            
            AEST.monthProportion = ones(size(TS))./48./eomday(AEST.YY, AEST.MM);
            AEST.yearProportion = ones(size(TS))./48./(337+eomday(AEST.YY, 2));
            
            AEST.isWorkday_Hobart = AEST.isWeekday & ~ismember(AEST.DS, PubHols.Hobart);
            AEST.isWorkday_Melbourne = AEST.isWeekday & ~ismember(AEST.DS, PubHols.Melbourne);
            AEST.isWorkday_Sydney = AEST.isWeekday & ~ismember(AEST.DS, PubHols.Sydney);
            AEST.isWorkday_Brisbane = AEST.isWeekday & ~ismember(AEST.DS, PubHols.Brisbane);
            AEST.isWorkday_Canberra = AEST.isWeekday & ~ismember(AEST.DS, PubHols.Canberra);
            AEST.isWorkday_Adelaide = AEST.isWeekday & ~ismember(AEST.DS, PubHols.Adelaide);
            
            % Basic time definitions - CST
            TS = Round2Sec(MDC.TS-1/24);
            CST.TS = TS;
            CST.DS = floor(TS-1/48);
            [CST.YY,CST.MM,CST.DD] = datevec(CST.DS);
            CST.QQ = ceil(CST.MM./3);
            CST.HH = round((TS - CST.DS)*48);
            CST.isWeekday = ismember(weekday(CST.DS),[2,3,4,5,6]);
            CST.isSaturday = weekday(CST.DS)==7;
            CST.isSunday = weekday(CST.DS)==1;            
            CST.monthProportion = ones(size(TS))./48./eomday(CST.YY, CST.MM);
            CST.yearProportion = ones(size(TS))./48./(337+eomday(CST.YY, 2));
            
            CST.isWorkday_Adelaide = CST.isWeekday & ~ismember(CST.DS, PubHols.Adelaide);
            
            
            % Basic time definitions - AELT (Sydney local time - same as
            % Vic, Tas since late 2008 when DST dates synchronised
            rtf = setdbprefs('DataReturnFormat')
            setdbprefs('DataReturnFormat', 'structure')
            curs = exec(MDC.conn,'select StartDate, EndDate from MarketData.dbo.DST WHERE NSW = 1');
            curs = fetch(curs);
            dst = curs.Data;
            dst.StartDate = cellfun(@(x)(addtodate(datenum(x),2,'hour')), dst.StartDate);
            dst.EndDate = cellfun(@(x)(addtodate(datenum(x),2,'hour')), dst.EndDate);
            
            % convert to local time
            LTS = MDC.TS;
            TS = MDC.TS;
            for i = 1:length(dst.StartDate)
                LTS(TS > dst.StartDate(i) & TS <= dst.EndDate(i)) = Round2Sec(LTS(TS > dst.StartDate(i) & TS <= dst.EndDate(i)) + 1/24);
            end
            AELT.TS = LTS;
            AELT.DS = floor(LTS-1/48);
            [AELT.YY,AELT.MM,AELT.DD] = datevec(AELT.DS);
            AELT.QQ = ceil(AELT.MM./3);
            AELT.HH = round((LTS - AELT.DS)*48);
            AELT.isWeekday = ismember(weekday(AELT.DS),[2,3,4,5,6]);
            AELT.isSaturday = weekday(AELT.DS)==7;
            AELT.isSunday = weekday(AELT.DS)==1;            
            AELT.monthProportion = ones(size(LTS))./48./eomday(AELT.YY, AELT.MM);
            AELT.yearProportion = ones(size(LTS))./48./(337+eomday(AELT.YY, 2));
            
            
            AELT.isWorkday_Hobart = AELT.isWeekday & ~ismember(AELT.DS, PubHols.Hobart);
            AELT.isWorkday_Melbourne = AELT.isWeekday & ~ismember(AELT.DS, PubHols.Melbourne);
            AELT.isWorkday_Sydney = AELT.isWeekday & ~ismember(AELT.DS, PubHols.Sydney);
            AELT.isWorkday_Canberra = AELT.isWeekday & ~ismember(AELT.DS, PubHols.Canberra);
            AELT.isWorkday_Adelaide = AELT.isWeekday & ~ismember(AELT.DS, PubHols.Adelaide);
            
            
            
            MDC.HHD.AEST = AEST;
            MDC.HHD.AELT = AELT;
            MDC.HHD.CST = CST;
        end
            
            
        
        function prepareMeterData(MDC, Meter, ScenarioParams, StartDate, EndDate)
            MDC.MeterPointID = Meter.MeterPointID;
            MDC.CurrentMeterRef = Meter.MeterRef;
            MDC.MeterOpen = Meter.MeterOpen;
            MDC.MeterClose = Meter.MeterClose;
            MDC.NumMeters = Meter.NumMeters;
            MDC.ScenarioParams = ScenarioParams;
            
%             if ~isconnection(MDC.conn)
%                 close(MDC.conn);
%                 MDC.conn = database.ODBCConnection(DB.DSN, DB.Usr, DB.Pwd);
%                 if ~isconnection(MDC.conn)
%                     error('Could not connect to database')
%                 end
%             end
            
            c = getTimeSeriesData(MDC.conn, MDC.TS, 'IMD_30min', {'Net_KWH', 'KW', 'KVA', 'Exp_KWH', 'Imp_KWH', 'KW15', 'KVA15', 'Exp_KVARH', 'QualityNumber'}, '(DATEADD(mi,PeriodID*30,convert(datetime,[Date])))', ['MeterPointID = ' num2str(MDC.MeterPointID)]);
            c = num2cell(c,1);
            [IMD.Net_KWH, IMD.KW, IMD.KVA, IMD.Exp_KWH, IMD.Imp_KWH, IMD.KW15, IMD.KVA15, IMD.Exp_KVARH, IMD.Method] = c{:};

            % HACK to derive Exp_KVA from 15 minute data            
            c1 = getTimeSeriesData(MDC.conn, MDC.TS15, 'IMD_15min', {'Exp_KWH', 'Exp_KVARH'}, '(DATEADD(mi,PeriodID*15,convert(datetime,[Date])))', ['MeterPointID = ' num2str(MDC.MeterPointID)]);
            c1 = num2cell(c1,1);
            Exp_KVA15 = sqrt(c1{1,1}.^2 + c1{1,2}.^2) .*4;
            Exp_KVA15 = nanmax(reshape(Exp_KVA15,2,[]))';
            IMD.Exp_KVA15 = Exp_KVA15;
            
            % Forecast Data
            IMD = forecastIMD_SameDayPreviousYear(MDC, IMD, MDC.HHD, 10);
            IMD = forecastIMD_SameDayPreviousWeek(MDC, IMD, MDC.HHD, 2);
            IMD = forecastIMD_CycleAvailableDays(MDC, IMD, MDC.HHD, 365);
            
            MDC.IMD = IMD;
            MDC.IMD.SD = Meter.SD;
        end
        
        function prepareMultiMeterData(MDC, Meter, ScenarioParams, StartDate, EndDate)
            MDC.MeterPointID = Meter.MeterPointID;
            MDC.CurrentMeterRef = Meter.MeterRef;
            MDC.MeterOpen = Meter.MeterOpen;
            MDC.MeterClose = Meter.MeterClose;
            MDC.NumMeters = Meter.NumMeters;
            MDC.ScenarioParams = ScenarioParams;
            
            
            conn2 = database('SVR-DB-002', '','');
            SQL1 = ['SELECT ID FROM [MeterDataDB].[dbo].[NEMMDF_Stream] ',...
                'WHERE NMI = ''', Meter.MeterRef(1:10), ''' AND NMISuffix = ''E', Meter.MeterRef(12:end),'''' ];
            SQL2 = ['SELECT ID FROM [MeterDataDB].[dbo].[NEMMDF_Stream] ',...
                'WHERE NMI = ''', Meter.MeterRef(1:10), ''' AND NMISuffix = ''Q', Meter.MeterRef(12:end),'''' ];
            SQL3 = ['SELECT ID FROM [MeterDataDB].[dbo].[NEMMDF_Stream] ',...
                'WHERE NMI = ''', Meter.MeterRef(1:10), ''' AND NMISuffix = ''B', Meter.MeterRef(12:end),'''' ];
            SQL4 = ['SELECT ID FROM [MeterDataDB].[dbo].[NEMMDF_Stream] ',...
                'WHERE NMI = ''', Meter.MeterRef(1:10), ''' AND NMISuffix = ''K', Meter.MeterRef(12:end),'''' ];
            data1 = fetch(conn2,SQL1);
            data2 = fetch(conn2,SQL2);
            data3 = fetch(conn2,SQL3);
            data4 = fetch(conn2,SQL4);
            Exp_KWH_StreamID = data1.ID;
            Exp_KVARH_StreamID = data2.ID;
            Imp_KWH_StreamID = data3.ID;
            Imp_KVARH_StreamID = data4.ID;
            
            SQL5 = ['SELECT * FROM [MeterDataDB].[dbo].[NEMMDF_IntervalData] ',...
                'WHERE StreamID = ''', num2str(Exp_KWH_StreamID), ''' Order by IntervalDate, IntervalNumber' ];
            SQL6 = ['SELECT * FROM [MeterDataDB].[dbo].[NEMMDF_IntervalData] ',...
                'WHERE StreamID = ''', num2str(Exp_KVARH_StreamID), ''' Order by IntervalDate, IntervalNumber' ];
            SQL7 = ['SELECT * FROM [MeterDataDB].[dbo].[NEMMDF_IntervalData] ',...
                'WHERE StreamID = ''', num2str(Imp_KWH_StreamID), ''' Order by IntervalDate, IntervalNumber' ];
            SQL8 = ['SELECT * FROM [MeterDataDB].[dbo].[NEMMDF_IntervalData] ',...
                'WHERE StreamID = ''', num2str(Imp_KVARH_StreamID), ''' Order by IntervalDate, IntervalNumber' ];
            data5 = fetch(conn2,SQL5);
            data6 = fetch(conn2,SQL6);
            data7 = fetch(conn2,SQL7);
            data8 = fetch(conn2,SQL8);
            
            IMD.Net_KWH = nan(size(MDC.TS));
            IMD.KW = nan(size(MDC.TS));
            IMD.KVA = nan(size(MDC.TS));
            IMD.Exp_KWH = nan(size(MDC.TS));
            IMD.Imp_KWH = nan(size(MDC.TS));
            IMD.KW15 = nan(size(MDC.TS));
            IMD.KVA15 = nan(size(MDC.TS));
            IMD.Exp_KVARH = nan(size(MDC.TS));
            IMD.Exp_KVA15 = nan(size(MDC.TS));
            IMD.Method = zeros(size(MDC.TS));
            
            if data5.IntervalLength(1) == 15
                TS2 = Round2Sec(datenum(data5.IntervalDate, 'yyyy-mm-dd') + data5.IntervalNumber/96);
                
                % Reshape into 30min data
                tmp2 = reshape(TS2, 2, [])';
                TS30 = tmp2(:,2);
                [Lia,Locb] = ismember(MDC.TS, TS30);
                
                Exp_KVA15 = sqrt(data5.Value.^2 + data6.Value.^2) .*4;
                Exp_KVA15 = nanmax(reshape(Exp_KVA15,2,[]))';
                
                Imp_KVA15 = sqrt(data7.Value.^2 + data8.Value.^2) .*4;
                Imp_KVA15 = nanmax(reshape(Imp_KVA15,2,[]))';
                
                Net_KVA15 = Exp_KVA15 - Imp_KVA15;
                Net_KWH = data5.Value + data7.Value;
                
                IMD.Exp_KVA15(Lia) = Exp_KVA15(Locb(find(Locb)));
                
                tmp3 = sum(reshape(data5.Value, 2, [])', 2);
                tmp4 = sum(reshape(data7.Value, 2, [])', 2);
                tmp5 = sum(reshape(Net_KWH, 2, [])', 2);
                IMD.Exp_KWH(Lia) = tmp3(Locb(find(Locb)));
                IMD.Imp_KWH(Lia) = tmp4(Locb(find(Locb)));
                IMD.Net_KWH(Lia) = tmp5(Locb(find(Locb)));
                                
                IMD.KW = IMD.Net_KWH .* 2;
                IMD.KW15 = IMD.KW;
                                
                IMD.KVA15(Lia) = Net_KVA15(Locb(find(Locb)));
                IMD.KVA(Lia) = Net_KVA15(Locb(find(Locb)));

                tmp6 = sum(reshape(data6.Value, 2, [])', 2);
                IMD.Exp_KVARH(Lia) = tmp6(Locb(find(Locb)));
                
            elseif data5.IntervalLength(1) == 30
                TS2 = Round2Sec(datenum(data5.IntervalDate, 'yyyy-mm-dd') + data5.IntervalNumber/48);  
                [Lia,Locb] = ismember(MDC.TS, TS2);
                
                Exp_KVA15 = sqrt(data5.Value.^2 + data6.Value.^2) .*2;                
                Imp_KVA15 = sqrt(data7.Value.^2 + data8.Value.^2) .*2;                
                Net_KVA15 = Exp_KVA15 - Imp_KVA15;                
                Net_KWH = data5.Value + data7.Value;
                
                IMD.Exp_KVA15(Lia) = Exp_KVA15(Locb(find(Locb)));
                
                IMD.Exp_KWH(Lia) = data5.Value(Locb(find(Locb)));
                IMD.Imp_KWH(Lia) = data7.Value(Locb(find(Locb)));
                IMD.Net_KWH(Lia) = Net_KWH(Locb(find(Locb)));
                
                IMD.KW = IMD.Net_KWH .* 2;
                IMD.KW15 = IMD.KW;
                
                IMD.KVA15(Lia) = Net_KVA15(Locb(find(Locb)));
                IMD.KVA(Lia) = Net_KVA15(Locb(find(Locb)));
                
                IMD.Exp_KVARH(Lia) = data6.Value(Locb(find(Locb)));                
                
            end
           
            % Forecast Data
            IMD = forecastIMD_SameDayPreviousYear(MDC, IMD, MDC.HHD, 10);
            IMD = forecastIMD_SameDayPreviousWeek(MDC, IMD, MDC.HHD, 2);
            IMD = forecastIMD_CycleAvailableDays(MDC, IMD, MDC.HHD, 365);
            
            MDC.IMD = IMD;
            MDC.IMD.SD = Meter.SD;
        end
        
        
        function [x,cmp] = calculateUsage(MDC,usage_code, start_date, end_date)
            
            [x,cmp] = actualUsage(MDC, usage_code, start_date, end_date );
            if cmp < MDC.MinDataPct
                x = NaN;
            end
        end
        
    end
    
end

