clear all

%% Method parameters
Method.Method = 'MOST_RECENT_YEAR';
Method.MinDataPct = 0.3;
Method.AcceptableDataQualFlags = {'A','E','I','S','F','Z','X'};

%% Database parameters
DB.DSN = 'MeterDataDB';
DB.Usr = '';
DB.Pwd = '';

%% Date range parameters
HistStartDate = datenum(2015,1,1);
HistEndDate = datenum(2018,4,1);

%% Create MDC
MDC = MeterDataCalculator(DB, Method, HistStartDate,HistEndDate)


%% Meter list
%XL_FILE = 'S:\Consulting\CSR\1607 BoY Forecast\CSR forecast Invoice calculator 20160721.xlsm';
%XL_FILE = 'S:\Consulting\CSR\1607 BoY Forecast\CSR forecast Invoice calculator 20160721.xlsm';
%XL_FILE = 'S:\Consulting\CSR\Invoice Validation\1608\Elec\Invoice Calculator - Re-run all.xlsm';
% XL_FILE = 'S:\Consulting\CSR\Cost Outlook & Accrual\16-08\Cost Calc.xlsm';
XL_FILE = 'S:\Consulting\CSR\Cost Outlook & Accrual\16-09\Budget Calc YEM17.xlsm';

% Meter List
[n,t,r] = xlsread(XL_FILE,'Meter list','A:N');
lastRow = find(cellfun(@(x)(ischar(x)||(isscalar(x)&&~isnan(x))),r(:,2)),1,'last');
r = r(2:lastRow,:);

Meter.ServicePointID = cell2mat(r(:,1));
Meter.MeterRef = cellfun(@num2str,r(:,2),'UniformOutput',false);
Meter.NumMeters = cell2mat(r(:,13));

% Consumption Definitions
[n,t,r] = xlsread(XL_FILE,'Tariffs','F1:F1000');
CD = unique(r(find(cellfun(@(x)(ischar(x)),r(2:end)))+1));
CD = [CD; {'KWH_METERDATA_DAYS'}; {'KWH_METERDATA_TOTAL'}];

nCD = length(CD);
%nCD = find(cellfun(@(x)(isscalar(x) && isnan(x)),r),1,'first') - 5;
%CD = r(5:4+nCD);

conn = database.ODBCConnection(DB.DSN, DB.Usr, DB.Pwd);
curs = exec(conn, 'SELECT ID, MeterRef FROM MeterDataDB.dbo.IMD_MeterPoint');
curs = fetch(curs);
IMD_List = curs.Data;

count = 0;

ps = datenum(2016,10,1);
nPeriods = 18
for m = 1:nPeriods
    PerStart(m,1) = ps;
    PerEnd(m,1) = addtodate(ps, 1, 'month')-1;
    ps = addtodate(ps, 1, 'month');
end

for i = 1:length(Meter.ServicePointID)
    i
    
    %M.MeterPointID = Meter.MeterPointID(i);
    
    M.MeterRef = Meter.MeterRef{i};
    M.NumMeters = Meter.NumMeters(i);
    f = find(strcmp(M.MeterRef,IMD_List.MeterRef));
    if isempty(f)
        continue
    end
    M.MeterPointID = IMD_List.ID(f);
    
    M.MeterOpen = NaN;
    M.MeterClose = NaN;
    
    ScenarioParams = [];
    StartDate = []; EndDate = [];
    
    prepareMeterData(MDC,M,ScenarioParams,StartDate,EndDate)
    if all(isnan(MDC.IMD.Net_KWH))
        error('all blank')
    end
    
    
    for m = 1:nPeriods
        count = count+1;
        res{count,1} = M.MeterRef;
        res{count,2} = datestr(PerStart(m),'dd/mm/yyyy');
        res{count,3} = '';
        for cd = 1:nCD
            [x,cmp] = calculateUsage(MDC,CD{cd}, PerStart(m), PerEnd(m));
            res{count,cd+3} = x;
        end
    end
end
res2 = [{'NMI'} {'Month'} {'Scenario'} CD(:)'; res];    % add headings
xlswrite('MeterDataCSR3.xlsx', res2, 'Sheet1');