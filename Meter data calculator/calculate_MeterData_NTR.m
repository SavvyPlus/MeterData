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
HistEndDate = datenum(2018,7,1);

%% Create MDC
MDC = MeterDataCalculator(DB, Method, HistStartDate,HistEndDate)


%% Meter list
% XL_FILE = 'C:\Users\james.cheong\Desktop\Projects\PA NTR\2017\Powercor NTR 2016-12-20.xlsm';
% XL_FILE = 'C:\Users\james.cheong\Desktop\Projects\PA NTR\2017\Citipower NTR 2016-12-22.xlsm';
% XL_FILE = 'C:\Users\james.cheong\Desktop\Projects\PA NTR\2017\Ausnet NTR 2016-12-24.xlsm';
% XL_FILE = 'C:\Users\james.cheong\Desktop\Projects\PA NTR\2017\United NTR 2016-12-27.xlsm';
% XL_FILE = 'C:\Users\james.cheong\Desktop\Projects\PA NTR\2017\United NTR 2016-12-27 - Test.xlsm';
% XL_FILE = 'C:\Users\james.cheong\Desktop\Projects\Vicinity Centres\1701 NTR\Ausnet NTR 2017-01-16.xlsm';
% XL_FILE = 'C:\Users\james.cheong\Desktop\Projects\Vicinity Centres\1701 NTR\Citipower NTR 2017-01-16.xlsm';
% XL_FILE = 'C:\Users\james.cheong\Desktop\Projects\Vicinity Centres\1701 NTR\Powercor NTR 2017-01-16.xlsm';
% XL_FILE = 'C:\Users\james.cheong\Desktop\Projects\Vicinity Centres\1701 NTR\United NTR 2017-01-16.xlsm';
% XL_FILE = 'C:\Users\james.cheong\Desktop\Projects\PA NTR\2017\Jemena NTR 2017-01-11.xlsm';
% XL_FILE = 'C:\Users\james.cheong\Desktop\Projects\Vicinity Centres\1701 NTR\Citipower NTR 2017-01-31.xlsm';
% XL_FILE = 'C:\Users\james.cheong\Desktop\Projects\Vicinity Centres\1701 NTR\Jemena NTR 2017-02-01.xlsm';
% XL_FILE = 'C:\Users\james.cheong\Desktop\Projects\Vicinity Centres\1701 NTR\Powercor NTR 2017-02-01.xlsm';
% XL_FILE = 'C:\Users\james.cheong\Desktop\Projects\Vicinity Centres\1701 NTR\United NTR 2017-02-01.xlsm';
% XL_FILE = 'C:\Users\james.cheong\Desktop\Projects\Vicinity Centres\1701 NTR\AusGrid NTR 2017-02-02.xlsm';
% XL_FILE = 'C:\Users\james.cheong\Desktop\Projects\Vicinity Centres\1701 NTR\Energex NTR 2017-02-02.xlsm';
% XL_FILE = 'C:\Users\james.cheong\Desktop\Projects\Vicinity Centres\1701 NTR\Ergon NTR 2017-02-02.xlsm';
% XL_FILE = 'C:\Users\james.cheong\Desktop\Projects\Vicinity Centres\1701 NTR\Essential NTR 2017-02-02.xlsm';
% XL_FILE = 'C:\Users\james.cheong\Desktop\Projects\Vicinity Centres\1701 NTR\SA Power NTR 2017-02-02.xlsm';
% XL_FILE = 'C:\Users\james.cheong\Desktop\Projects\Vicinity Centres\1701 NTR\TasNetworks NTR 2017-02-02.xlsm';
% XL_FILE = 'C:\Users\james.cheong\Desktop\Projects\Vicinity Centres\1701 NTR\Jemena NTR 2017-02-06 - 6001396918.xlsm';
% XL_FILE = 'C:\Users\james.cheong\Desktop\Projects\Wilson Parking\NTR 2017-03\NTR Results\Citipower NTR 2017-04-19.xlsm';
% XL_FILE = 'C:\Users\james.cheong\Desktop\Projects\Wilson Parking\NTR 2017-03\NTR Results\United NTR 2017-04-19.xlsm';
% XL_FILE = 'C:\Users\james.cheong\Desktop\Projects\Wilson Parking\NTR 2017-03\NTR Results\SA Power NTR 2017-04-20';
% XL_FILE = 'C:\Users\james.cheong\Desktop\Projects\Wilson Parking\NTR 2017-03\NTR Results\ActewAGL NTR 2017-04-20';
% XL_FILE = 'C:\Users\james.cheong\Desktop\Projects\Wilson Parking\NTR 2017-03\NTR Results\AusGrid NTR 2017-04-20';
% XL_FILE = 'C:\Users\james.cheong\Desktop\Projects\Wilson Parking\NTR 2017-03\NTR Results\Endeavour NTR 2017-04-20';
% XL_FILE = 'C:\Users\james.cheong\Desktop\Projects\Wilson Parking\NTR 2017-03\NTR Results\Incomplete\ActewAGL NTR 2017-06-07';
% XL_FILE = 'C:\Users\james.cheong\Desktop\Projects\TasWater\NTR 20170613\TasWater NTR 20170613 - Non Specified Demand.xlsm';
% XL_FILE = 'C:\Users\james.cheong\Desktop\Projects\DoE\NTR 201706\DoE NTR 20170619 - Non Specified Demand.xlsm';
% XL_FILE = 'C:\Users\james.cheong\Desktop\Projects\TasWater\NTR 20170613\TasWater NTR 20170613 - Check.xlsm';
% XL_FILE = 'C:\Users\james.cheong\Desktop\Projects\TasWater\NTR 20170613\TasWater NTR 20170619 - Non Specified Demand.xlsm';
% XL_FILE = 'C:\Users\james.cheong\Desktop\Projects\Procurement Australia\2017 NTR\GMW Powercor NTR 2017-06-21.xlsm';
% XL_FILE = 'C:\Users\james.cheong\Desktop\Projects\Procurement Australia\2017 NTR\GWM Ausnet NTR 2017-06-21.xlsm';
% XL_FILE = 'C:\Users\james.cheong\Desktop\Projects\DoE\NTR 201706\DoE NTR 20170626 - Specified Demand Sites.xlsm';
% XL_FILE = 'C:\Users\james.cheong\Desktop\Projects\OneCare\201709 NTR\OneCare NTR 20170901.xlsm';
% XL_FILE = 'C:\Users\james.cheong\Desktop\Projects\Tas Advanced Minerals\201709 NTR\TAM NTR 20170905.xlsm';
% XL_FILE = 'C:\Users\james.cheong\Desktop\Projects\OneCare\201709 NTR\OneCare NTR 20170905.xlsm';
XL_FILE = 'C:\Users\james.cheong\Desktop\Projects\OneCare\201709 NTR\OneCare NTR 20170905 Consolidated.xlsm';


% Meter List
[n,t,r] = xlsread(XL_FILE,'Meter list','A:P');
lastRow = find(cellfun(@(x)(ischar(x)||(isscalar(x)&&~isnan(x))),r(:,2)),1,'last');
r = r(2:lastRow,:);

Meter.ServicePointID = cell2mat(r(:,1));
Meter.MeterRef = cellfun(@num2str,r(:,2),'UniformOutput',false);
Meter.NumMeters = cell2mat(r(:,5));
Meter.SD = cell2mat(r(:,16));

% Consumption Definitions
[n,t,r] = xlsread(XL_FILE,'Tariffs','F1:F1000');
CD = unique(r(find(cellfun(@(x)(ischar(x)),r(2:end)))+1));
CD = [CD; cellstr('ENERGY_ANYTIME_AEST'); cellstr('MAX_CAPACITY_ANYTIME_AELT'); ...
          cellstr('MAX_DEMAND_ANYTIME_AELT'); cellstr('KWH_METERDATA_DAYS'); cellstr('KWH_METERDATA_TOTAL');...
          cellstr('ENERGY_ANYTIME_AELT');];
nCD = length(CD);
%nCD = find(cellfun(@(x)(isscalar(x) && isnan(x)),r),1,'first') - 5;
%CD = r(5:4+nCD);

%%
conn = database(DB.DSN, DB.Usr, DB.Pwd);
curs = exec(conn, 'SELECT ID, MeterRef FROM MeterDataDB.dbo.IMD_MeterPoint');
curs = fetch(curs);
IMD_List = curs.Data;

count = 0;

ps = datenum(2017,7,1);
nPeriods = 12
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
    f = find(strcmp(M.MeterRef(1:10),IMD_List.MeterRef));
    if isempty(f)
        continue
    end
    M.MeterPointID = IMD_List.ID(f);
    
    M.MeterOpen = NaN;
    M.MeterClose = NaN;
    M.SD = Meter.SD(i);
    
    ScenarioParams = [];
    StartDate = []; EndDate = [];
    
    isSubMeter = strfind(M.MeterRef, '-');
    if ~isempty(isSubMeter) && isSubMeter == 11
        prepareMultiMeterData(MDC,M,ScenarioParams,StartDate,EndDate)
    else
        prepareMeterData(MDC,M,ScenarioParams,StartDate,EndDate)
    end
    
    
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

% xlswrite('C:\Users\james.cheong\Desktop\Projects\PA NTR\2017\MeterData_Powercor_20161221_Forecast4.xlsx', res2, 'Sheet1');
% xlswrite('C:\Users\james.cheong\Desktop\Projects\PA NTR\2017\MeterData_Citipower_20161222_Forecast2.xlsx', res2, 'Sheet1');
% xlswrite('C:\Users\james.cheong\Desktop\Projects\PA NTR\2017\MeterData_Ausnet_20161226_Forecast1.xlsx', res2, 'Sheet1');
% xlswrite('C:\Users\james.cheong\Desktop\Projects\PA NTR\2017\MeterData_United_20170109_Actual.xlsx', res2, 'Sheet1');
% xlswrite('C:\Users\james.cheong\Desktop\Projects\Vicinity Centres\1701 NTR\MeterData_Ausnet_20170113_Forecast.xlsx', res2, 'Sheet1');
% xlswrite('C:\Users\james.cheong\Desktop\Projects\Vicinity Centres\1701 NTR\MeterData_Citipower_20170113_Actual.xlsx', res2, 'Sheet1');
% xlswrite('C:\Users\james.cheong\Desktop\Projects\Vicinity Centres\1701 NTR\MeterData_Powercor_20170113_Forecast.xlsx', res2, 'Sheet1');
% xlswrite('C:\Users\james.cheong\Desktop\Projects\Vicinity Centres\1701 NTR\MeterData_United_20170113_Actual.xlsx', res2, 'Sheet1');
% xlswrite('C:\Users\james.cheong\Desktop\Projects\PA NTR\2017\MeterData_Jemena_20170117_Forecast.xlsx', res2, 'Sheet1');
% xlswrite('C:\Users\james.cheong\Desktop\Projects\Vicinity Centres\1701 NTR\MeterData_Citipower_20170131_Actual.xlsx', res2, 'Sheet1');
% xlswrite('C:\Users\james.cheong\Desktop\Projects\Vicinity Centres\1701 NTR\MeterData_Jemena_20170203_Forecast.xlsx', res2, 'Sheet1');
% xlswrite('C:\Users\james.cheong\Desktop\Projects\Vicinity Centres\1701 NTR\MeterData_Powercor_20170201_Actual.xlsx', res2, 'Sheet1');
% xlswrite('C:\Users\james.cheong\Desktop\Projects\Vicinity Centres\1701 NTR\MeterData_United_20170203_Forecast.xlsx', res2, 'Sheet1');
% xlswrite('C:\Users\james.cheong\Desktop\Projects\Vicinity Centres\1701 NTR\MeterData_Ausgrid_20170202_Forecast.xlsx', res2, 'Sheet1');
% xlswrite('C:\Users\james.cheong\Desktop\Projects\Vicinity Centres\1701 NTR\MeterData_Energex_20170202_Actual.xlsx', res2, 'Sheet1');
% xlswrite('C:\Users\james.cheong\Desktop\Projects\Vicinity Centres\1701 NTR\MeterData_Ergon_20170202_Forecast.xlsx', res2, 'Sheet1');
% xlswrite('C:\Users\james.cheong\Desktop\Projects\Vicinity Centres\1701 NTR\MeterData_Essential_20170202_Actual.xlsx', res2, 'Sheet1');
% xlswrite('C:\Users\james.cheong\Desktop\Projects\Vicinity Centres\1701 NTR\MeterData_SA_Power_20170202_Forecast.xlsx', res2, 'Sheet1');
% xlswrite('C:\Users\james.cheong\Desktop\Projects\Vicinity Centres\1701 NTR\MeterData_TasNetworks_20170202_Actual.xlsx', res2, 'Sheet1');
% xlswrite('C:\Users\james.cheong\Desktop\Projects\Vicinity Centres\1701 NTR\MeterData_Jemena-6001396918_20170206_Forecast.xlsx', res2, 'Sheet1');
% xlswrite('C:\Users\james.cheong\Desktop\Projects\Wilson Parking\NTR 2017-03\NTR Results\MeterData_CitiPower_2017-04-19.xlsx', res2, 'Sheet1');
% xlswrite('C:\Users\james.cheong\Desktop\Projects\Wilson Parking\NTR 2017-03\NTR Results\MeterData_United_2017-04-19.xlsx', res2, 'Sheet1');
% xlswrite('C:\Users\james.cheong\Desktop\Projects\Wilson Parking\NTR 2017-03\NTR Results\MeterData_SA_Power_2017-04-19.xlsx', res2, 'Sheet1');
% xlswrite('C:\Users\james.cheong\Desktop\Projects\Wilson Parking\NTR 2017-03\NTR Results\MeterData_ActewAGL_2017-04-20.xlsx', res2, 'Sheet1');
% xlswrite('C:\Users\james.cheong\Desktop\Projects\Wilson Parking\NTR 2017-03\NTR Results\MeterData_Ausgrid_2017-04-20.xlsx', res2, 'Sheet1');
% xlswrite('C:\Users\james.cheong\Desktop\Projects\Wilson Parking\NTR 2017-03\NTR Results\MeterData_Endeavour_2017-04-20.xlsx', res2, 'Sheet1');
% xlswrite('C:\Users\james.cheong\Desktop\Projects\Wilson Parking\NTR 2017-03\NTR Results\MeterData_ActewAGL_2017-06-07.xlsx', res2, 'Sheet1');
% xlswrite('C:\Users\james.cheong\Desktop\Projects\TasWater\NTR 20170613\MeterData_TASWATER_2017-06-12.xlsx', res2, 'Sheet1');
% xlswrite('C:\Users\james.cheong\Desktop\Projects\DoE\NTR 201706\MeterData_DoE_2017-06-19.xlsx', res2, 'Sheet1');
% xlswrite('C:\Users\james.cheong\Desktop\Projects\TasWater\NTR 20170613\MeterData_TASWATER_2017-06-19.xlsx', res2, 'Sheet1');
% xlswrite('C:\Users\james.cheong\Desktop\Projects\Procurement Australia\2017 NTR\MeterData_GMW_Powercor_2017-06-21_ACTUAL.xlsx', res2, 'Sheet1');
% xlswrite('C:\Users\james.cheong\Desktop\Projects\Procurement Australia\2017 NTR\MeterData_GMW_AusNet_2017-06-21.xlsx', res2, 'Sheet1');
% xlswrite('C:\Users\james.cheong\Desktop\Projects\DoE\NTR 201706\MeterData_DoE_SD Only_2017-06-26.xlsx', res2, 'Sheet1');

% xlswrite('C:\Users\james.cheong\Desktop\Projects\OneCare\201709 NTR\MeterData_OneCare_2017-09-05.xlsx', res2, 'Sheet1');
% xlswrite('C:\Users\james.cheong\Desktop\Projects\Tas Advanced Minerals\201709 NTR\MeterData_TAM_2017-09-05.xlsx', res2, 'Sheet1');
xlswrite('C:\Users\james.cheong\Desktop\Projects\OneCare\201709 NTR\MeterData_OneCare_2017-09-05 Consolidated.xlsx', res2, 'Sheet1');

