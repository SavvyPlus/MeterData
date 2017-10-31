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
HistStartDate = datenum(2016,1,1);      
HistEndDate = datenum(2018,1,1);


%% Create MDC
MDC = MeterDataCalculator(DB, Method, HistStartDate,HistEndDate)


%% Meter list
XL_FILE = 'C:\Users\james.cheong\Desktop\Projects\Wilson Parking\NTR 2017-03\Calc.xlsm';


% Meter List
[n,t,r] = xlsread(XL_FILE,'Meter list','A:N');
% lastRow = find(cellfun(@(x)(ischar(x)||(isscalar(x)&&~isnan(x))),r(:,2)),1,'last');
lastRow = find(cellfun(@(x)(ischar(x)||(isscalar(x)&&~isnan(x))),r(:,9)),1,'last');
r = r(2:lastRow,:);

% Meter.ServicePointID = cell2mat(r(:,1));
% Meter.MeterRef = cellfun(@num2str,r(:,2),'UniformOutput',false);
% Meter.NumMeters = cell2mat(r(:,13));

tmp1 = cell2mat(r(:,2));
tmp2 = cellfun(@num2str,r(:,9),'UniformOutput',false);
tmp3 = cell2mat(r(:,12));

[Meter.MeterRef,ia,ic] = unique(tmp2);
Meter.ServicePointID = tmp1(ia);
Meter.NumMeters = tmp3(ia);

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

% StartDate = datenum(2016,4,1,0,30,0); 
% EndDate = datenum(2017,4,1,0,0,0);
StartDate = datenum(2017,1,1,0,30,0); 
EndDate = datenum(2018,1,1,0,0,0); 
TS = Round2Sec(StartDate:1/48:EndDate);

res = cell(length(TS)+1, length(Meter.ServicePointID));

for i = 1:length(Meter.ServicePointID)
% for i = 12:length(Meter.ServicePointID)
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
    
    
    prepareMeterData(MDC,M,ScenarioParams, [], [])
    if all(isnan(MDC.IMD.Net_KWH))
        error('all blank')
    end
    
    
    KWH = NaN(size(TS));

    res{1,i} = M.MeterRef;
   
    [Lia,Locb] = ismember(TS, MDC.TS);
    KWH(Lia) = MDC.IMD.Net_KWH(Locb(find(Locb)));
    
    res(2:end,i) = num2cell(KWH);
    
    keyboard
    
end



xlswrite('C:\Users\james.cheong\Desktop\Projects\Wilson Parking\NTR 2017-03\MeterData_2017-04-13.xlsx', res, 'Sheet1');



%%


figure

plot(TS,x )
ylabel('kWh')
grid on
title('Wilson Parking Large Sites')
% legend('NSW','VIC','SA','ACT')
legend('NCCC003564','NCCCNREG42','4103579420')
datetick2
zoom xon

