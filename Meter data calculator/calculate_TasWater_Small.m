clear all

%% Database parameters
DB.DSN = 'InvoiceLoader';
DB.Usr = '';
DB.Pwd = '';

%% Date range parameters
HistStartDate = datenum(2015,7,1);
HistEndDate = datenum(2017,7,1);

%% Create MDC
% MDC = MeterDataCalculator(DB, Method, HistStartDate,HistEndDate)


%% Meter list
XL_FILE = 'S:\Consulting\Tasmanian Water and Sewerage Corporation\1608 BI Implementation\Historical Invoice Validation\Small sites\Invoice Calculator - Small Sites (v0.001).xlsm';

% Meter List
[n,t,r] = xlsread(XL_FILE,'Meter list','B:I');
lastRow = find(cellfun(@(x)(ischar(x)||(isscalar(x)&&~isnan(x))),r(:,2)),1,'last');
r = r(2:lastRow,:);

Meter.ServicePointID = cell2mat(r(:,1));
Meter.MeterRef = cellfun(@num2str,r(:,2),'UniformOutput',false);
% Meter.NumMeters = cell2mat(r(:,12));

% Consumption Definitions
[n,t,r] = xlsread(XL_FILE,'Tariffs','J1:J1000');
CD = unique(r(find(cellfun(@(x)(ischar(x)),r(2:end)))+1));
% CD = [CD; {'KWH_METERDATA_DAYS'}; {'KWH_METERDATA_TOTAL'}];

nCD = length(CD);
%nCD = find(cellfun(@(x)(isscalar(x) && isnan(x)),r),1,'first') - 5;
%CD = r(5:4+nCD);


count = 0;



for i = 1:length(Meter.ServicePointID)    
    
    invoices = getInvoices(Meter.ServicePointID(i), Meter.MeterRef{i}, HistStartDate, HistEndDate);
    
    for j = 1:length(invoices)
        count = count+1;
        inv = invoices{i};
        res{count,1} = Meter.MeterRef{i};
        res{count,2} = inv.StartDate;
        res{count,3} = inv.EndDate;
        for cd = 1:nCD
            calculateInvoiceUsage(inv, CD{cd})
    end
    
    
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
xlswrite('MeterDataTasWater.xlsx', res2, 'Sheet1');