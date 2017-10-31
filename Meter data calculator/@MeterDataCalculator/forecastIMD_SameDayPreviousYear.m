function [ IMD ] = forecastIMD_SameDayPreviousYear( MDC, IMD, HHD, MaxYears )
%FORECASTIMD_SAMEDAYPREVIOUSYEAR Summary of this function goes here
%   Detailed explanation goes here

kwh = reshape(IMD.Net_KWH, 48, []);

% TODO: include other variables in this assessment
good_days = all(~isnan(kwh));

% TODO: get smarter about matching day-types etc.
best_match = zeros(1,size(kwh,2));
yma = 7*round(365*[1:MaxYears]./7);

for d = 365:size(kwh,2)
    candidate_days = d-yma;
    f = find(ismember(candidate_days, find(good_days)),1,'first');
    if ~isempty(f)
        best_match(d) = candidate_days(f);
    end
end

update_days = ~good_days & best_match>0;

for v = {'Net_KWH', 'KW', 'KVA', 'Exp_KWH', 'Imp_KWH', 'KW15', 'KVA15', 'Exp_KVARH', 'Exp_KVA15'}
    
    vals = reshape(IMD.(v{1}),48,[]);
    vals(:,update_days) = vals(:,best_match(update_days));
    vals = vals(:);
    
    if strcmp(v{1},'Net_KWH')
        IMD.Method(isnan(IMD.Net_KWH) & ~isnan(vals)) = 6;
    end
    
    IMD.(v{1}) = vals(:);    
                    
end

