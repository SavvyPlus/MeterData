function [ IMD ] = forecastIMD_CycleAvailableDays( MDC, IMD, HHD, MaxDaysBack )
%FORECASTIMD_SAMEDAYPREVIOUSYEAR Summary of this function goes here
%   Detailed explanation goes here

kwh = reshape(IMD.Net_KWH, 48, []);
nDays = size(kwh,2);

% TODO: include other variables in this assessment
good_days = all(~isnan(kwh));
last_good_day = find(good_days,1,'last');
if isempty(last_good_day)
    return
end
cycle_days = good_days & ((1:nDays)>=last_good_day-MaxDaysBack);

% TODO: get smarter about matching day-types etc.
DT = mod(0:(nDays-1),7)+1;

for dt = 1:7
    days_to_cycle{dt} = find(cycle_days & DT==dt);
    if isempty(days_to_cycle{dt})
        days_to_cycle{dt} = 0;      % For cases where there is no good days for a particular dt
    end
    counter{dt} = 1;
end

best_match = zeros(1,nDays);

for d = find(good_days,1,'first'):nDays
% for d = 1:nDays       % Use this instead if backcasting needed.
    dt = DT(d);
    if ~ismember(d, good_days)
        best_match(d) = days_to_cycle{dt}(counter{dt});
        counter{dt} = counter{dt}+1;
        if counter{dt} > length(days_to_cycle{dt})
            counter{dt} = 1;
        end
    end
end

update_days = ~good_days & best_match>0;

for v = {'Net_KWH', 'KW', 'KVA', 'Exp_KWH', 'Imp_KWH', 'KW15', 'KVA15', 'Exp_KVARH', 'Exp_KVA15'}
    
    vals = reshape(IMD.(v{1}),48,[]);
    vals(:,update_days) = vals(:,best_match(update_days));
    vals = vals(:);
    
    if strcmp(v{1},'Net_KWH')
        IMD.Method(isnan(IMD.Net_KWH) & ~isnan(vals)) = 7;
    end
    
    IMD.(v{1}) = vals(:);    
                    
end

