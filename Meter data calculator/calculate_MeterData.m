clearvars

%% Method parameters
Method.Method = 'MOST_RECENT_YEAR';
Method.MinDataPct = 0.3;
Method.AcceptableDataQualFlags = {'A','E','I','S','F','Z','X'};

%% Database parameters
DB.DSN = 'MeterDataDB';
DB.Usr = '';
DB.Pwd = '';

%% Date range parameters,
%  The further back the better for 12 month rolling history
HistStartDate = datenum(2015,1,1);      
% HistEndDate = datenum(2017,7,1);
HistEndDate = datenum(2018,7,1);
% HistEndDate = datenum(2023,7,1);


%% Create MDC
MDC = MeterDataCalculator(DB, Method, HistStartDate,HistEndDate)


%% Meter list
% XL_FILE = 'S:\Consulting\CSR\Invoice Validation\1704\Calc.xlsm';
% XL_FILE = 'C:\Users\james.cheong\Desktop\Projects\Wilson Parking\NTR 2017-03\Calc.xlsm';
% XL_FILE = 'C:\Users\james.cheong\Desktop\Projects\Wilson Parking\2017-05 Budget\Wilson Parking Budget (Large sites only) 2017-05-22.xlsm';
XL_FILE = 'T:\Hin Cheng\Invoice Calculator\Invoice Calculator - 2017-08-09 v2.xlsm';



% Meter List
% [n,t,r] = xlsread(XL_FILE,'Meter list','A:N');
[n,t,r] = xlsread(XL_FILE,'Meter list','A:Q');
% lastRow = find(cellfun(@(x)(ischar(x)||(isscalar(x)&&~isnan(x))),r(:,2)),1,'last');
lastRow = find(cellfun(@(x)(ischar(x)||(isscalar(x)&&~isnan(x))),r(:,9)),1,'last');
r = r(2:lastRow,:);

% Meter.ServicePointID = cell2mat(r(:,1));
% Meter.MeterRef = cellfun(@num2str,r(:,2),'UniformOutput',false);
% Meter.NumMeters = cell2mat(r(:,13));

tmp1 = cell2mat(r(:,2));
tmp2 = cellfun(@num2str,r(:,9),'UniformOutput',false);
tmp3 = cell2mat(r(:,12));
tmp4 = cell2mat(r(:,17));

[Meter.MeterRef,ia,ic] = unique(tmp2);
Meter.ServicePointID = tmp1(ia);
Meter.NumMeters = tmp3(ia);
Meter.SD = tmp4(ia);


% Consumption Definitions
[n,t,r] = xlsread(XL_FILE,'Tariffs','L1:L1000');
CD = unique(r(find(cellfun(@(x)(ischar(x)),r(2:end)))+1));
nCD = length(CD);
%nCD = find(cellfun(@(x)(isscalar(x) && isnan(x)),r),1,'first') - 5;
%CD = r(5:4+nCD);

%%
conn = database.ODBCConnection(DB.DSN, DB.Usr, DB.Pwd);
curs = exec(conn, 'SELECT ID, MeterRef FROM MeterDataDB.dbo.IMD_MeterPoint');
curs = fetch(curs);
IMD_List = curs.Data;

count = 0;

ps = datenum(2017,6,1);
nPeriods = 2
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
    M.SD = Meter.SD(i);

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
        res{count,3} = datestr(PerEnd(m),'dd/mm/yyyy');
        res{count,4} = '';
        for cd = 1:nCD
            [x,cmp] = calculateUsage(MDC,CD{cd}, PerStart(m), PerEnd(m));
            res{count,cd+4} = x;
        end
    end
end
res2 = [{'NMI'} {'Start Date'} {'End Date'} {'Scenario'} CD(:)'; res];    % add headings


% xlswrite('S:\Consulting\Tasmanian Water and Sewerage Corporation\Accrual Report\201702\MeterData_TasWater_20170301.xlsx', res2, 'Sheet1');
% xlswrite('C:\Users\james.cheong\Desktop\MeterData_Client_yyyy-mm-dd.xlsx', res2, 'Sheet1');
% xlswrite('C:\Users\james.cheong\Desktop\Projects\Wilson Parking\2017-05 Budget\MeterData_Large_2017-05-26.xlsx', res2, 'Sheet1');
xlswrite('T:\Hin Cheng\Invoice Calculator\Output.xlsx', res2, 'Sheet1');




