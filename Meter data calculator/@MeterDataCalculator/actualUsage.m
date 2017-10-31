function [x,cmp] = actualUsage(MDC,usage_code, start_date, end_date)

TS = MDC.TS;
LTS = MDC.HHD.AELT.TS;

AEST = MDC.HHD.AEST;
AELT = MDC.HHD.AELT;
CST = MDC.HHD.CST;

TS_CST = Round2Sec(TS - 1/24);

% calculate month proportion
[s.y,s.m,s.d] = datevec(start_date);
[e.y,e.m,e.d] = datevec(end_date);
if s.y~=e.y || s.m~=e.m
    error('Can''t calculate for periods that overlap month boundaries');
end

monthprop = (end_date-start_date+1) ./ eomday(s.y,s.m);

switch usage_code
    case {'NONE'}
        x = 1; cmp = 1;
    case {'DAYS'}
        x = end_date - start_date + 1;
        cmp = 1;
    case {'MONTHS'}
        x = sum(MDC.HHD.AEST.monthProportion(TS > start_date & TS <= end_date+1));
        cmp = 1;
    case {'METER_MONTHS'}
        % TODO: multiply by number of meters
        x = MDC.NumMeters .* sum(MDC.HHD.AEST.monthProportion(TS > start_date & TS <= end_date+1));
        cmp = 1;        
    case {'METER_DAYS'}
        x = MDC.NumMeters .* (end_date+1 - start_date);
        cmp = 1;
    case {'YEARS'}
        x = sum(MDC.HHD.AEST.yearProportion(TS > start_date & TS <= end_date+1));
        cmp = 1;
    case {'KWH_METERDATA_DAYS'}
        % days with method<=5 (meter data)
        mask = true(size(TS)) & TS > start_date & TS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask & MDC.IMD.Method<=5);
        x = sum(~isnan(d))/48;
        cmp = 1;
    case {'KWH_METERDATA_TOTAL'}
        % total kwh with method<=5 (meter data)
        mask = true(size(TS)) & TS > start_date & TS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask & MDC.IMD.Method<=5);
        x = nansum(d);
        cmp = 1;
    case {'ENERGY_ANYTIME_AEST','ENERGY_ANYTIME_KWH'}
        mask = true(size(TS)) & TS > start_date & TS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        x = nansum(d);
        cmp = mean(~isnan(d));
    case {'ENERGY_EXPORT_ANYTIME_AEST'}
        mask = true(size(TS)) & TS > start_date & TS <= end_date+1;
        d = MDC.IMD.Exp_KWH(mask);
        x = nansum(d);
        cmp = mean(~isnan(d));        
    case {'ENERGY_ANYTIME_AELT'}
        mask = true(size(LTS)) & LTS > start_date & LTS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        x = nansum(d);
        cmp = mean(~isnan(d));
    case {'MAX_DEMAND_ANYTIME_AELT'}
        mask = true(size(LTS)) & LTS > start_date & LTS <= end_date+1;
        d = MDC.IMD.KW(mask);
        x = nanmax(d);
        cmp = mean(~isnan(d));
    case {'MAX_CAPACITY_ANYTIME_AELT'}
        mask = true(size(LTS)) & LTS > start_date & LTS <= end_date+1;
        d = MDC.IMD.KVA(mask);
        x = nanmax(d);
        cmp = mean(~isnan(d));
    case {'ENERGY_ANYTIME_CST'}
        mask = true(size(CST.TS)) & CST.TS > start_date & CST.TS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        x = nansum(d);
        cmp = mean(~isnan(d));
    case {'ENERGY_M-F_07-23_OP'}
        mask = ~(AEST.isWeekday & AEST.HH >= 15 & AEST.HH <= 46) & TS > start_date & TS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        if isempty(d)
            x = 0;
            cmp = 1;
        else
            x = nansum(d);
            cmp = mean(~isnan(d));            
        end        
    case {'ENERGY_M-F_7-23_PK'}
        mask = AEST.isWeekday & AEST.HH >= 15 & AEST.HH <= 46 & TS > start_date & TS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        if isempty(d)
            x = 0;
            cmp = 1;
        else
            x = nansum(d);
            cmp = mean(~isnan(d));            
        end        
    
    % ------------------------ WHOLESALE DEFINITIONS ---------------------
    case {'ENERGY_AFMA_VIC_PK'}
        mask = AEST.isWorkday_Melbourne & AEST.HH >= 15 & AEST.HH <= 44 & TS > start_date & TS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        if isempty(d)
            x = 0;
            cmp = 1;
        else
            x = nansum(d);
            cmp = mean(~isnan(d));            
        end        
    case {'ENERGY_AFMA_VIC_OP'}
        mask = (~AEST.isWorkday_Melbourne | AEST.HH < 15 | AEST.HH > 44) & TS > start_date & TS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        if isempty(d)
            x = 0;
            cmp = 1;
        else
            x = nansum(d);
            cmp = mean(~isnan(d));            
        end        
    case {'ENERGY_AFMA_NSW_PK'}
        mask = AEST.isWorkday_Sydney & AEST.HH >= 15 & AEST.HH <= 44 & TS > start_date & TS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        if isempty(d)
            x = 0;
            cmp = 1;
        else
            x = nansum(d);
            cmp = mean(~isnan(d));            
        end        
    case {'ENERGY_AFMA_NSW_OP'}
        mask = (~AEST.isWorkday_Sydney | AEST.HH < 15 | AEST.HH > 44) & TS > start_date & TS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        if isempty(d)
            x = 0;
            cmp = 1;
        else
            x = nansum(d);
            cmp = mean(~isnan(d));            
        end        
    case {'ENERGY_AFMA_QLD_PK'}
        mask = AEST.isWorkday_Brisbane & AEST.HH >= 15 & AEST.HH <= 44 & TS > start_date & TS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        if isempty(d)
            x = 0;
            cmp = 1;
        else
            x = nansum(d);
            cmp = mean(~isnan(d));            
        end        
    case {'ENERGY_AFMA_QLD_OP'}
        mask = (~AEST.isWorkday_Brisbane | AEST.HH < 15 | AEST.HH > 44) & TS > start_date & TS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        if isempty(d)
            x = 0;
            cmp = 1;
        else
            x = nansum(d);
            cmp = mean(~isnan(d));            
        end        
    case {'ENERGY_AFMA_SA_PK'}
        mask = AEST.isWorkday_Adelaide & AEST.HH >= 15 & AEST.HH <= 44 & TS > start_date & TS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        if isempty(d)
            x = 0;
            cmp = 1;
        else
            x = nansum(d);
            cmp = mean(~isnan(d));            
        end        
    case {'ENERGY_AFMA_SA_OP'}
        mask = (~AEST.isWorkday_Adelaide | AEST.HH < 15 | AEST.HH > 44) & TS > start_date & TS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        if isempty(d)
            x = 0;
            cmp = 1;
        else
            x = nansum(d);
            cmp = mean(~isnan(d));            
        end        
    case {'ENERGY_AFMA_TAS_PK'}
        mask = AEST.isWorkday_Hobart & AEST.HH >= 15 & AEST.HH <= 44 & TS > start_date & TS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        if isempty(d)
            x = 0;
            cmp = 1;
        else
            x = nansum(d);
            cmp = mean(~isnan(d));            
        end        
    case {'ENERGY_AFMA_TAS_OP'}
        mask = (~AEST.isWorkday_Hobart | AEST.HH < 15 | AEST.HH > 44) & TS > start_date & TS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        if isempty(d)
            x = 0;
            cmp = 1;
        else
            x = nansum(d);
            cmp = mean(~isnan(d));            
        end        
        
        
    % --------------------- STANDARD RETAIL DEFINITIONS ------------------
    case {'ENERGY_NSW_STDRETAIL_PEAK'}
        mask = AELT.isWorkday_Sydney & ismember(AELT.HH,[15:18 35:40]) & LTS > start_date & LTS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        x = nansum(d);
        cmp = mean(~isnan(d));        
    case {'ENERGY_NSW_STDRETAIL_SHOULDER'}
        mask = AELT.isWorkday_Sydney & ismember(AELT.HH,[19:34 41:44]) & LTS > start_date & LTS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        x = nansum(d);
        cmp = mean(~isnan(d));        
    case {'ENERGY_NSW_STDRETAIL_OFFPEAK'}
        mask = ((AELT.isWorkday_Sydney & ~ismember(AELT.HH,[15:44])) | ~AELT.isWorkday_Sydney) & LTS > start_date & LTS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        x = nansum(d);
        cmp = mean(~isnan(d));            
    case {'ENERGY_ACT_STDRETAIL_PEAK'}
        mask = AELT.isWorkday_Canberra & ismember(AELT.HH,[15:18 35:40]) & LTS > start_date & LTS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        x = nansum(d);
        cmp = mean(~isnan(d));        
    case {'ENERGY_ACT_STDRETAIL_SHOULDER'}
        mask = AELT.isWorkday_Canberra & ismember(AELT.HH,[19:34 41:44]) & LTS > start_date & LTS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        x = nansum(d);
        cmp = mean(~isnan(d));
    case {'ENERGY_ACT_STDRETAIL_OFFPEAK'}
        mask = ((AELT.isWorkday_Canberra & ~ismember(AELT.HH,15:44)) | ~AELT.isWorkday_Canberra) & LTS > start_date & LTS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        x = nansum(d);
        cmp = mean(~isnan(d));
    case {'ENERGY_QLD_STDRETAIL_PEAK'}
        mask = AEST.isWorkday_Brisbane & ismember(AEST.HH,15:46) & TS > start_date & TS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        x = nansum(d);
        cmp = mean(~isnan(d));                
    case {'ENERGY_QLD_STDRETAIL_OFFPEAK'}
        mask = ~(AEST.isWorkday_Brisbane & ismember(AEST.HH,15:46)) & TS > start_date & TS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        x = nansum(d);
        cmp = mean(~isnan(d));
    case {'ENERGY_SA_STDRETAIL_PEAK'}
        % peak should be HHs 15:42 Central Local Time
        mask = AELT.isWeekday & ismember(AELT.HH,16:43) & LTS > start_date & LTS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        x = nansum(d);
        cmp = mean(~isnan(d));
    case {'ENERGY_SA_STDRETAIL_OFFPEAK'}
        % peak should be HHs 15:42 Central Local Time        
        mask = ~(AELT.isWeekday & ismember(AELT.HH,16:43)) & LTS > start_date & LTS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        x = nansum(d);
        cmp = mean(~isnan(d));
    case {'ENERGY_VIC_STDRETAIL_PEAK'}
        mask = AELT.isWeekday & ismember(AELT.HH,15:46) & LTS > start_date & LTS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        x = nansum(d);
        cmp = mean(~isnan(d));
    case {'ENERGY_VIC_STDRETAIL_OFFPEAK'}
        mask = ~(AELT.isWeekday & ismember(AELT.HH,15:46)) & LTS > start_date & LTS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        x = nansum(d);
        cmp = mean(~isnan(d));
    case {'ENERGY_TAS_STDRETAIL_PEAK'}
        mask = AEST.isWorkday_Hobart & ismember(AEST.HH,15:44) & TS > start_date & TS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        x = nansum(d);
        cmp = mean(~isnan(d));                
    case {'ENERGY_TAS_STDRETAIL_OFFPEAK'}
        mask = ~(AEST.isWorkday_Hobart & ismember(AEST.HH,15:44)) & TS > start_date & TS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        x = nansum(d);
        cmp = mean(~isnan(d));
        
    % ------------------------- ERGON DEFINITIONS ------------------------        
    case {'DEMAND_ERGON_ACTUAL'}
        mask = TS > start_date & TS <= end_date+1;
        d = MDC.IMD.KW(mask);
        if isempty(d)
            x = 0;
            cmp = 1;
        else
            x = nanmax(d);
            cmp = mean(~isnan(d));
        end
    case {'CAPACITY_ERGON'}
        % TODO: should be Authorised Demand if known, or annual max demand
        % otherwise. From 2014/15, maybe not used now?
        [s.y,s.m,s.d] = datevec(start_date);
        [e.y,e.m,e.d] = datevec(end_date);
        e = datenum(e.y,e.m+1,1)-1;
        s = addtodate(e,-1,'year')+1;
        mask = TS > s & TS <= e+1;
        d = MDC.IMD.KW(mask);
        
        x = nanmax(d) * monthprop;                
        cmp = mean(~isnan(d));
    case {'ENERGY_ERG_ANYTIME_SEASONAL_PK'}
        mask = ismember(AEST.MM,[12,1:2]) & TS > start_date & TS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        x = nansum(d);
        cmp = mean(~isnan(d));        
    case {'ENERGY_ERG_ANYTIME_SEASONAL_OP'}
        mask = ~ismember(AEST.MM,[12,1:2]) & TS > start_date & TS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        x = nansum(d);
        cmp = mean(~isnan(d));
    case {'DEMAND_ERGON_SEASONAL_PK'}
        mask = ismember(AEST.MM,[12,1,2]) & AEST.isWeekday & AEST.HH >= 21 & AEST.HH <= 40 & TS > start_date & TS <= end_date+1;
        d = MDC.IMD.KW(mask);
        if isempty(d)
            x = 0;
            cmp = 1;
        else
            x = nanmax(d);
            cmp = mean(~isnan(d));
        end
    case {'DEMAND_ERGON_SEASONAL_OP'}
        mask = ~ismember(AEST.MM,[12,1,2]) & TS > start_date & TS <= end_date+1;
        d = MDC.IMD.KW(mask);
        if isempty(d)
            x = 0;
            cmp = 1;
        else
            x = nanmax(d);
            cmp = mean(~isnan(d));
        end
    % ------------------------ ENERGEX DEFINITIONS -----------------------        
    case {'DEMAND_ENERGEX'}        
        % Prior to 1 Jul 2015 used a KW demand, now KVA
        clear s; clear e;
        [s.y,s.m,s.d] = datevec(start_date);
        [e.y,e.m,e.d] = datevec(end_date);
        s = datenum(e.y,e.m,1);        
        e = datenum(e.y,e.m+1,1)-1;        
        mask = TS > s & TS <= e+1;
        d = MDC.IMD.KVA(mask);
        
        x = nanmax(d) * monthprop;                
        cmp = mean(~isnan(d));
        
    case {'CAPACITY_ENERGEX'}
        % straight rolling 12-month max KVA
        clear s; clear e;        
        [s.y,s.m,s.d] = datevec(start_date);
        [e.y,e.m,e.d] = datevec(end_date);
        e = datenum(e.y,e.m+1,1)-1;
        s = addtodate(e,-1,'year')+1;
        mask = TS > s & TS <= e+1;
        d = MDC.IMD.KVA(mask);
        
        x = nanmax(d) * monthprop;                
        cmp = mean(~isnan(d));
        
        
    % ------------------------ JEMENA DEFINITIONS ------------------------
    case {'DEMAND_JEMENA'}
        % Actually contracted demand, but for new sites, estimate using rolling 12-month max KW.  
        clear s; clear e;        
        [s.y,s.m,s.d] = datevec(start_date);
        [e.y,e.m,e.d] = datevec(end_date);
        e = datenum(e.y,e.m+1,1)-1;
%         s = datenum(s.y,s.m,1);
        s = addtodate(e,-1,'year')+1;
        mask = TS > s & TS <= e+1;
        if sum(isnan(MDC.IMD.KW15)) == length(MDC.IMD.KW15)
            d = MDC.IMD.KW(mask);
        else
            d = MDC.IMD.KW15(mask);
        end
        x = nanmax(d) * monthprop;
        cmp = mean(~isnan(d));
    case {'DEMAND_JEMENA_10-8'}
        % Assume local time and reset monthly
        mask = AELT.isWorkday_Melbourne & AELT.HH >= 21 & AELT.HH <= 40 & LTS > start_date & LTS <= end_date+1;
        d = MDC.IMD.KW(mask);
        if isempty(d)
            x = 0;
            cmp = 1;
        else
            x = nanmax(d);
            cmp = mean(~isnan(d));
        end
    case {'DEMAND_JEMENA_3-9'}
        % Assume local time
        mask = AELT.isWorkday_Melbourne & AELT.HH >= 31 & AELT.HH <= 42 & LTS > start_date & LTS <= end_date+1;
        d = MDC.IMD.KW(mask);
        if isempty(d)
            x = 0;
            cmp = 1;
        else
            x = nanmax(d);
            cmp = mean(~isnan(d));
        end
    case {'DEMAND_JEMENA_KVA'}
        % Actually contracted demand, but for new sites, estimate using rolling 12-month max kVA.  
        clear s; clear e;        
        [s.y,s.m,s.d] = datevec(start_date);
        [e.y,e.m,e.d] = datevec(end_date);
        e = datenum(e.y,e.m+1,1)-1;
        s = addtodate(e,-1,'year')+1;
        mask = TS > s & TS <= e+1;        
        if sum(isnan(MDC.IMD.KVA15)) == length(MDC.IMD.KVA15)
            d = MDC.IMD.KVA(mask);
        else
            d = MDC.IMD.KVA15(mask);
        end
        x = nanmax(d) * monthprop;
        cmp = mean(~isnan(d));                
        

    % ------------------------ TASMANIA DEFINITIONS ----------------------        
    case {'ENERGY_TASNET_TAS94_PK'}
        mask = AEST.isWeekday & AEST.HH >= 15 & AEST.HH <= 44 & TS > start_date & TS <= end_date+1;
        d = MDC.IMD.Exp_KWH(mask);
        x = nansum(d);
        cmp = mean(~isnan(d));        
    case {'ENERGY_TASNET_TAS94_SH'}
        mask = ~AEST.isWeekday & AEST.HH >= 15 & AEST.HH <= 44 & TS > start_date & TS <= end_date+1;
        d = MDC.IMD.Exp_KWH(mask);
        x = nansum(d);
        cmp = mean(~isnan(d));                
    case {'ENERGY_TASNET_TAS94_OP'}
        mask = (AEST.HH <= 14 | AEST.HH >= 45) & TS > start_date & TS <= end_date+1;
        d = MDC.IMD.Exp_KWH(mask);
        x = nansum(d);
        cmp = mean(~isnan(d));
    case {'ENERGY_TASNET_SEASONAL_PK'}
        mask = ismember(AEST.MM,4:9) & AEST.isWeekday & AEST.HH >= 15 & AEST.HH <= 44 & TS > start_date & TS <= end_date+1;
        d = MDC.IMD.Exp_KWH(mask);
        x = nansum(d);
        cmp = mean(~isnan(d));
    case {'ENERGY_TASNET_SEASONAL_SH'}
        mask = ((~ismember(AEST.MM,4:9) & AEST.isWeekday) | (ismember(AEST.MM,4:9) & ~AEST.isWeekday)) & AEST.HH >= 15 & AEST.HH <= 44 & TS > start_date & TS <= end_date+1;
        d = MDC.IMD.Exp_KWH(mask);
        x = nansum(d);
        cmp = mean(~isnan(d));
    case {'ENERGY_TASNET_SEASONAL_OP'}
        mask = (AEST.HH <= 14 | AEST.HH >= 45 | (~ismember(AEST.MM,4:9) & ~AEST.isWeekday)) & TS > start_date & TS <= end_date+1;
        d = MDC.IMD.Exp_KWH(mask);
        x = nansum(d);
        cmp = mean(~isnan(d));
    case {'DEMAND_MAX15MIN'}
        % TODO: allow to cope with multi-month date range
        [s.y,s.m,s.d] = datevec(start_date);
        [e.y,e.m,e.d] = datevec(end_date);
        e = datenum(e.y,e.m+1,1)-1;
        s = datenum(s.y,s.m,1);
        mask = TS > s & TS <= e+1;
        d = MDC.IMD.Exp_KVA15(mask);
        x = nanmax(d);
        cmp = mean(~isnan(d));
        
    case {'CAPACITY_MAX15MIN_KVADAYS'}
        % Express in KVA-days. 
        % TODO: allow to cope with multi-month date range
        [s.y,s.m,s.d] = datevec(start_date);
        [e.y,e.m,e.d] = datevec(end_date);
        e = datenum(e.y,e.m+1,1)-1;
        s = datenum(s.y,s.m,1);
        mask = TS > s & TS <= e+1;
        d = MDC.IMD.Exp_KVA15(mask);
        x = nanmax(d) * (end_date-start_date+1);
        cmp = mean(~isnan(d));
    case {'DEMAND_TASNET_SPECIFIED_DEMAND_100%'}
%         [s.y,s.m,s.d] = datevec(start_date);
%         [e.y,e.m,e.d] = datevec(end_date);
%         e = datenum(e.y,e.m+1,1)-1;
%         s = datenum(s.y,s.m,1);
        mask = TS > start_date & TS <= end_date+1;
        d = MDC.IMD.Exp_KVA15(mask);
        dailymax = max(reshape(d,48,[]));
        SD = MDC.IMD.SD; SD_factor = 1;  % TODO: where do these come from?
        daily_sd = max(SD, min(SD*SD_factor,dailymax));        
        daily_sd(isnan(SD.*SD_factor.*dailymax)) = NaN;
        
        x = mean(daily_sd);
        cmp = mean(~isnan(d));
        
    case {'DEMAND_TASNET_SPECIFIED_DEMAND_EXCESS_100%'}
        mask = TS > start_date & TS <= end_date+1;
        d = MDC.IMD.Exp_KVA15(mask);
        dailymax = max(reshape(d,48,[]));
        SD = MDC.IMD.SD; SD_factor = 1;  % TODO: where do these come from?
%         daily_sd = max(SD, min(SD*SD_factor,dailymax));        
%         daily_sd(isnan(SD.*SD_factor.*dailymax)) = NaN;
%         daily_ed = dailymax - daily_sd;
%         
%         x = sum(daily_ed);
        daily_ed = max(dailymax - SD*SD_factor, 0);
        
        x = mean(daily_ed);
        cmp = mean(~isnan(d));        

    case {'DEMAND_TASNET_SPECIFIED_DEMAND_120%'}
%         [s.y,s.m,s.d] = datevec(start_date);
%         [e.y,e.m,e.d] = datevec(end_date);
%         e = datenum(e.y,e.m+1,1)-1;
%         s = datenum(s.y,s.m,1);
        mask = TS > start_date & TS <= end_date+1;
        d = MDC.IMD.Exp_KVA15(mask);
        dailymax = max(reshape(d,48,[]));
        SD = MDC.IMD.SD; SD_factor = 1.2;  % TODO: where do these come from?
        daily_sd = max(SD, min(SD*SD_factor,dailymax));        
        daily_sd(isnan(SD.*SD_factor.*dailymax)) = NaN;
        
        x = mean(daily_sd);
        cmp = mean(~isnan(d));

        
    case {'DEMAND_TASNET_SPECIFIED_DEMAND_EXCESS_120%'}
        mask = TS > start_date & TS <= end_date+1;
        d = MDC.IMD.Exp_KVA15(mask);
        dailymax = max(reshape(d,48,[]));
        SD = MDC.IMD.SD; SD_factor = 1.2;  % TODO: where do these come from?
%         daily_sd = max(SD, min(SD*SD_factor,dailymax));        
%         daily_sd(isnan(SD.*SD_factor.*dailymax)) = NaN;
%         daily_ed = dailymax - daily_sd;
%         
%         x = sum(daily_ed);
        daily_ed = max(dailymax - SD*SD_factor, 0);
        
        x = mean(daily_ed);
        cmp = mean(~isnan(d));
        
        
    case {'DEMAND_TASNET_SPECIFIED_DEMAND_120%(SD-20%)'}
        mask = TS > start_date & TS <= end_date+1;
        d = MDC.IMD.Exp_KVA15(mask);
        dailymax = max(reshape(d,48,[]));
        SD = MDC.IMD.SD * 0.8; SD_factor = 1.2;
        daily_sd = max(SD, min(SD*SD_factor,dailymax));
        daily_sd(isnan(SD.*SD_factor.*dailymax)) = NaN;
        
        x = mean(daily_sd);
        cmp = mean(~isnan(d));
        
        
    case {'DEMAND_TASNET_SPECIFIED_DEMAND_EXCESS_120%(SD-20%)'}
        mask = TS > start_date & TS <= end_date+1;
        d = MDC.IMD.Exp_KVA15(mask);
        dailymax = max(reshape(d,48,[]));
        SD = MDC.IMD.SD * 0.8; SD_factor = 1.2;
        daily_ed = max(dailymax - SD*SD_factor, 0);
        
        x = mean(daily_ed);
        cmp = mean(~isnan(d));
        
    case {'DEMAND_TASNET_SPECIFIED_DEMAND_120%(SD-15%)'}
        mask = TS > start_date & TS <= end_date+1;
        d = MDC.IMD.Exp_KVA15(mask);
        dailymax = max(reshape(d,48,[]));
        SD = MDC.IMD.SD * 0.85; SD_factor = 1.2;
        daily_sd = max(SD, min(SD*SD_factor,dailymax));
        daily_sd(isnan(SD.*SD_factor.*dailymax)) = NaN;
        
        x = mean(daily_sd);
        cmp = mean(~isnan(d));
        
        
    case {'DEMAND_TASNET_SPECIFIED_DEMAND_EXCESS_120%(SD-15%)'}
        mask = TS > start_date & TS <= end_date+1;
        d = MDC.IMD.Exp_KVA15(mask);
        dailymax = max(reshape(d,48,[]));
        SD = MDC.IMD.SD * 0.85; SD_factor = 1.2;
        daily_ed = max(dailymax - SD*SD_factor, 0);
        
        x = mean(daily_ed);
        cmp = mean(~isnan(d));
        
    case {'DEMAND_TASNET_SPECIFIED_DEMAND_120%(SD-10%)'}
        mask = TS > start_date & TS <= end_date+1;
        d = MDC.IMD.Exp_KVA15(mask);
        dailymax = max(reshape(d,48,[]));
        SD = MDC.IMD.SD * 0.9; SD_factor = 1.2;
        daily_sd = max(SD, min(SD*SD_factor,dailymax));
        daily_sd(isnan(SD.*SD_factor.*dailymax)) = NaN;
        
        x = mean(daily_sd);
        cmp = mean(~isnan(d));
                
    case {'DEMAND_TASNET_SPECIFIED_DEMAND_EXCESS_120%(SD-10%)'}
        mask = TS > start_date & TS <= end_date+1;
        d = MDC.IMD.Exp_KVA15(mask);
        dailymax = max(reshape(d,48,[]));
        SD = MDC.IMD.SD * 0.9; SD_factor = 1.2;
        daily_ed = max(dailymax - SD*SD_factor, 0);
        
        x = mean(daily_ed);
        cmp = mean(~isnan(d));
        
    case {'DEMAND_TASNET_SPECIFIED_DEMAND_120%(SD-5%)'}
        mask = TS > start_date & TS <= end_date+1;
        d = MDC.IMD.Exp_KVA15(mask);
        dailymax = max(reshape(d,48,[]));
        SD = MDC.IMD.SD * 0.95; SD_factor = 1.2;
        daily_sd = max(SD, min(SD*SD_factor,dailymax));
        daily_sd(isnan(SD.*SD_factor.*dailymax)) = NaN;
        
        x = mean(daily_sd);
        cmp = mean(~isnan(d));
                
    case {'DEMAND_TASNET_SPECIFIED_DEMAND_EXCESS_120%(SD-5%)'}
        mask = TS > start_date & TS <= end_date+1;
        d = MDC.IMD.Exp_KVA15(mask);
        dailymax = max(reshape(d,48,[]));
        SD = MDC.IMD.SD * 0.95; SD_factor = 1.2;
        daily_ed = max(dailymax - SD*SD_factor, 0);
        
        x = mean(daily_ed);
        cmp = mean(~isnan(d));
        
    case {'DEMAND_TASNET_SPECIFIED_DEMAND_120%(SD+5%)'}
        mask = TS > start_date & TS <= end_date+1;
        d = MDC.IMD.Exp_KVA15(mask);
        dailymax = max(reshape(d,48,[]));
        SD = MDC.IMD.SD * 1.05; SD_factor = 1.2;
        daily_sd = max(SD, min(SD*SD_factor,dailymax));
        daily_sd(isnan(SD.*SD_factor.*dailymax)) = NaN;
        
        x = mean(daily_sd);
        cmp = mean(~isnan(d));
                
    case {'DEMAND_TASNET_SPECIFIED_DEMAND_EXCESS_120%(SD+5%)'}
        mask = TS > start_date & TS <= end_date+1;
        d = MDC.IMD.Exp_KVA15(mask);
        dailymax = max(reshape(d,48,[]));
        SD = MDC.IMD.SD * 1.05; SD_factor = 1.2;
        daily_ed = max(dailymax - SD*SD_factor, 0);
        
        x = mean(daily_ed);
        cmp = mean(~isnan(d));

    case {'DEMAND_TASNET_SPECIFIED_DEMAND_120%(SD+10%)'}
        mask = TS > start_date & TS <= end_date+1;
        d = MDC.IMD.Exp_KVA15(mask);
        dailymax = max(reshape(d,48,[]));
        SD = MDC.IMD.SD * 1.1; SD_factor = 1.2;
        daily_sd = max(SD, min(SD*SD_factor,dailymax));
        daily_sd(isnan(SD.*SD_factor.*dailymax)) = NaN;
        
        x = mean(daily_sd);
        cmp = mean(~isnan(d));
                
    case {'DEMAND_TASNET_SPECIFIED_DEMAND_EXCESS_120%(SD+10%)'}
        mask = TS > start_date & TS <= end_date+1;
        d = MDC.IMD.Exp_KVA15(mask);
        dailymax = max(reshape(d,48,[]));
        SD = MDC.IMD.SD * 1.1; SD_factor = 1.2;
        daily_ed = max(dailymax - SD*SD_factor, 0);
        
        x = mean(daily_ed);
        cmp = mean(~isnan(d));
    
    case {'DEMAND_TASNET_SPECIFIED_DEMAND_120%(SD+15%)'}
        mask = TS > start_date & TS <= end_date+1;
        d = MDC.IMD.Exp_KVA15(mask);
        dailymax = max(reshape(d,48,[]));
        SD = MDC.IMD.SD * 1.15; SD_factor = 1.2;
        daily_sd = max(SD, min(SD*SD_factor,dailymax));
        daily_sd(isnan(SD.*SD_factor.*dailymax)) = NaN;
        
        x = mean(daily_sd);
        cmp = mean(~isnan(d));
                
    case {'DEMAND_TASNET_SPECIFIED_DEMAND_EXCESS_120%(SD+15%)'}
        mask = TS > start_date & TS <= end_date+1;
        d = MDC.IMD.Exp_KVA15(mask);
        dailymax = max(reshape(d,48,[]));
        SD = MDC.IMD.SD * 1.15; SD_factor = 1.2;
        daily_ed = max(dailymax - SD*SD_factor, 0);
        
        x = mean(daily_ed);
        cmp = mean(~isnan(d));
        
    case {'DEMAND_TASNET_SPECIFIED_DEMAND_120%(SD+20%)'}
        mask = TS > start_date & TS <= end_date+1;
        d = MDC.IMD.Exp_KVA15(mask);
        dailymax = max(reshape(d,48,[]));
        SD = MDC.IMD.SD * 1.2; SD_factor = 1.2;
        daily_sd = max(SD, min(SD*SD_factor,dailymax));
        daily_sd(isnan(SD.*SD_factor.*dailymax)) = NaN;
        
        x = mean(daily_sd);
        cmp = mean(~isnan(d));
                
    case {'DEMAND_TASNET_SPECIFIED_DEMAND_EXCESS_120%(SD+20%)'}
        mask = TS > start_date & TS <= end_date+1;
        d = MDC.IMD.Exp_KVA15(mask);
        dailymax = max(reshape(d,48,[]));
        SD = MDC.IMD.SD * 1.2; SD_factor = 1.2;
        daily_ed = max(dailymax - SD*SD_factor, 0);
        
        x = mean(daily_ed);
        cmp = mean(~isnan(d));        
        
        
    case {'CAPACITY_TASNET_PEAK'}
        mask = (AEST.isWeekday & ismember(AEST.HH,[15:20, 33:42])) & TS > start_date & TS <= end_date+1;
        d = sqrt(MDC.IMD.Exp_KWH(mask).^2 + MDC.IMD.Exp_KVARH(mask).^2) .*2;        
        x = nanmax(d);
        cmp = mean(~isnan(d));
    case {'CAPACITY_TASNET_OFFPEAK'}
        mask = ~(AEST.isWeekday & ismember(AEST.HH,[15:20, 33:42])) & TS > start_date & TS <= end_date+1;
        d = sqrt(MDC.IMD.Exp_KWH(mask).^2 + MDC.IMD.Exp_KVARH(mask).^2) .*2;
        x = nanmax(d);
        cmp = mean(~isnan(d));
    case {'DEMAND_TASNET_PEAK'}
        mask = (AEST.isWeekday & ismember(AEST.HH,[15:20, 33:42])) & TS > start_date & TS <= end_date+1;
        d = MDC.IMD.Exp_KWH(mask) .* 2;
        x = nanmax(d);
        cmp = mean(~isnan(d));
    case {'DEMAND_TASNET_OFFPEAK'}
        mask = ~(AEST.isWeekday & ismember(AEST.HH,[15:20, 33:42])) & TS > start_date & TS <= end_date+1;
        d = MDC.IMD.Exp_KWH(mask) .* 2;
        x = nanmax(d);
        cmp = mean(~isnan(d));
        
    % ----------------------- ACTEW ACT DEFINITIONS ----------------------
    case {'ENERGY_ACTEW_TOU_BUSINESS_PK'}
        mask = AEST.isWeekday & ismember(AEST.HH,[15:34]) & TS > start_date & TS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        x = nansum(d);
        cmp = mean(~isnan(d));                
    case {'ENERGY_ACTEW_TOU_EVENING_SH'}
        mask = AEST.isWeekday & ismember(AEST.HH,[35:44]) & TS > start_date & TS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        x = nansum(d);
        cmp = mean(~isnan(d));                
    case {'ENERGY_ACTEW_TOU_OP'}
        mask = (~AEST.isWeekday | AEST.HH<=14 | AEST.HH>=45) & TS > start_date & TS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        x = nansum(d);
        cmp = mean(~isnan(d));                
    case {'DEMAND_ACTEW'}
        % TODO: deal with multi-month & part-month ranges
        mask = TS > start_date & TS <= end_date+1;
        d = MDC.IMD.KVA(mask);
        x = nanmax(d);
        cmp = mean(~isnan(d));
    case {'CAPACITY_ACTEW'}
        % rolling 12-month maximum KVA. Express in KVA-months. 
        % TODO: allow to calc correctly for a multi-month date range        
        [s.y,s.m,s.d] = datevec(start_date);
        [e.y,e.m,e.d] = datevec(end_date);
        e = datenum(e.y,e.m+1,1)-1;
        s = addtodate(e,-1,'year')+1;
        mask = TS > s & TS <= e+1;
        d = MDC.IMD.KVA(mask);
        
        x = nanmax(d) * monthprop;                
        cmp = mean(~isnan(d));
        
    case {'DEMAND_ACTEW_7-5'}
        mask = (AEST.isWeekday & ismember(AEST.HH,[15:34])) & TS > start_date & TS <= end_date+1;
        d = MDC.IMD.KW(mask);
        x = nanmax(d) * monthprop;
        cmp = mean(~isnan(d));
        
    % -------------------- ESSENTIAL ENERGY DEFINITIONS ------------------
    case {'ENERGY_ESS_PK'}
        mask = AELT.isWeekday & ismember(AELT.HH,[15:18 35:40]) & LTS > start_date & LTS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        x = nansum(d);
        cmp = mean(~isnan(d));        
    case {'ENERGY_ESS_SH'}
        mask = AELT.isWeekday & ismember(AELT.HH,[19:34 41:44]) & LTS > start_date & LTS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        x = nansum(d);
        cmp = mean(~isnan(d));        
    case {'ENERGY_ESS_OP'}
        mask = ((AELT.isWeekday & ~ismember(AELT.HH,[15:44])) | ~AELT.isWeekday) & LTS > start_date & LTS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        x = nansum(d);
        cmp = mean(~isnan(d));            
    case {'DEMAND_ESSENTIAL_THREE_RATE_PK_MTHLY'}
        mask = AELT.isWeekday & ismember(AELT.HH,[15:18 35:40]) & LTS > start_date & LTS <= end_date+1;
        d = MDC.IMD.KVA(mask);
        x = nanmax(d);
        cmp = mean(~isnan(d));
    case {'DEMAND_ESSENTIAL_THREE_RATE_SH_MTHLY'}
        mask = AELT.isWeekday & ismember(AELT.HH,[19:34 41:44]) & LTS > start_date & LTS <= end_date+1;
        d = MDC.IMD.KVA(mask);
        x = nanmax(d);
        cmp = mean(~isnan(d));
    case {'DEMAND_ESSENTIAL_THREE_RATE_OP_MTHLY'}
        mask = ((AELT.isWeekday & ~ismember(AELT.HH,[15:44])) | ~AELT.isWeekday) & LTS > start_date & LTS <= end_date+1;
        d = MDC.IMD.KVA(mask);
        x = nanmax(d);
        cmp = mean(~isnan(d));
    case {'CAPACITY_ESS'}
        % rolling 12-month maximum KVA. Express in KVA-months. 
        % TODO: allow to calc correctly for a multi-month date range        
        [s.y,s.m,s.d] = datevec(start_date);
        [e.y,e.m,e.d] = datevec(end_date);
        e = datenum(e.y,e.m+1,1)-1;
        s = addtodate(e,-1,'year')+1;
        mask = TS > s & TS <= e+1;
        d = MDC.IMD.KVA(mask);
        rounded = [20,40,60,80,100,150,200:100:10000];
        x = rounded(find(rounded >= nanmax(d),1,'first')) * monthprop;                
        cmp = mean(~isnan(d));
    case {'DEMAND_ESSENTIAL_MAXIMUM'}
        mask = LTS > start_date & LTS <= end_date+1;
        d = MDC.IMD.KVA(mask);
        x = nanmax(d);
        cmp = mean(~isnan(d));    
    % ---------------------- AUSGRID NSW DEFINITIONS ---------------------
    case {'ENERGY_AUSGRID_PK'}
        mask = AELT.isWorkday_Sydney & ismember(AELT.HH,[29:40]) & LTS > start_date & LTS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        x = nansum(d);
        cmp = mean(~isnan(d));                
    case {'ENERGY_AUSGRID_SH'}
        mask = AELT.isWorkday_Sydney & ismember(AELT.HH,[15:28 41:44]) & LTS > start_date & LTS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        x = nansum(d);
        cmp = mean(~isnan(d));                
    case {'ENERGY_AUSGRID_OP'}
        mask = (AELT.HH<=14 | AELT.HH>=45 | ~AELT.isWorkday_Sydney) & LTS > start_date & LTS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        x = nansum(d);
        cmp = mean(~isnan(d));                
    case {'ENERGY_AUSGRID_PK_<40MWH'}
        mask = AELT.isWorkday_Sydney & ismember(AELT.HH,[29:40]) & LTS > start_date & LTS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        x = nansum(d);
        cmp = mean(~isnan(d));                
    case {'ENERGY_AUSGRID_SH_<40MWH'}
        mask = (AELT.isWorkday_Sydney & ismember(AELT.HH,[15:28 41:44]) | ~AELT.isWorkday_Sydney & ismember(AELT.HH,15:44)) & LTS > start_date & LTS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        x = nansum(d);
        cmp = mean(~isnan(d));                
    case {'ENERGY_AUSGRID_OP_<40MWH'}
        mask = (AELT.HH<=14 | AELT.HH>=45) & LTS > start_date & LTS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        x = nansum(d);
        cmp = mean(~isnan(d));                
    case {'DEMAND_AUSGRID'}
        % rolling 12-month maximum KW 2-8pm wwd. Express in KW-months. 
        % TODO: allow to calc correctly for a multi-month date range        
        [s.y,s.m,s.d] = datevec(start_date);
        [e.y,e.m,e.d] = datevec(end_date);
        e = datenum(e.y,e.m+1,1)-1;
        s = addtodate(e,-1,'year')+1;
        mask = AELT.isWorkday_Sydney & AELT.TS > s & AELT.TS <= e+1 & AELT.HH >= 29 & AELT.HH <= 40;
        d = MDC.IMD.KW(mask);
        
        x = nanmax(d) * monthprop;                
        cmp = mean(~isnan(d));
        
    case {'CAPACITY_AUSGRID'}
        % rolling 12-month maximum KVA 2-8pm wwd. Express in KVA-months. 
        % TODO: allow to calc correctly for a multi-month date range        
        [s.y,s.m,s.d] = datevec(start_date);
        [e.y,e.m,e.d] = datevec(end_date);
        e = datenum(e.y,e.m+1,1)-1;
        s = addtodate(e,-1,'year')+1;
        mask = AELT.isWorkday_Sydney & AELT.TS > s & AELT.TS <= e+1 & AELT.HH >= 29 & AELT.HH <= 40;
        d = MDC.IMD.KVA(mask);
        
        x = nanmax(d) * monthprop;                
        cmp = mean(~isnan(d));
    
    % --------------------- ENDEAVOUR NSW DEFINITIONS --------------------
    case {'ENERGY_ENDEAV_PK'}
        mask = AELT.isWorkday_Sydney & ismember(AELT.HH,[27:40]) & LTS > start_date & LTS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        x = nansum(d);
        cmp = mean(~isnan(d));                
    case {'ENERGY_ENDEAV_SH'}
        mask = AELT.isWorkday_Sydney & ismember(AELT.HH,[15:26 41:44]) & LTS > start_date & LTS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        x = nansum(d);
        cmp = mean(~isnan(d));                
    case {'ENERGY_ENDEAV_OP'}
        mask = (~AELT.isWorkday_Sydney | AELT.HH<=14 | AELT.HH>=45) & LTS > start_date & LTS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        x = nansum(d);
        cmp = mean(~isnan(d));                
    case {'DEMAND_ENDEAV_SEASONAL_HIGH'}
        % TODO: adapt to cope with multi-month & part-month ranges
        mask = ismember(AELT.MM,[11:12 1:3 6:8]) & ismember(AELT.HH,27:40) & LTS > start_date & LTS <= end_date+1;
        d = MDC.IMD.KVA(mask);
        if isempty(d)
            x = 0;
            cmp = 1;
        else
            x = nanmax(d);
            cmp = mean(~isnan(d));            
        end
        
        
    case {'DEMAND_ENDEAV_SEASONAL_LOW'}
        % TODO: adapt to cope with multi-month & part-month ranges
        mask = ismember(AELT.MM,[4:5 9:10]) & ismember(AELT.HH,27:40) & LTS > start_date & LTS <= end_date+1;
        d = MDC.IMD.KVA(mask);
        if isempty(d)
            x = 0;
            cmp = 1;
        else
            x = nanmax(d);
            cmp = mean(~isnan(d));            
        end
    case {'DEMAND_ENDEAVOUR'}
        % TODO: adapt to cope with multi-month & part-month ranges
        mask = ismember(AELT.MM,[4:5 9:10]) & LTS > start_date & LTS <= end_date+1;
        d = MDC.IMD.KVA(mask);
        if isempty(d)
            x = 0;
            cmp = 1;
        else
            x = nanmax(d);
            cmp = mean(~isnan(d));
        end
        
    % ----------------------- UNITED VIC DEFINITIONS ---------------------
    case {'ENERGY_UNI_ALL_TIMES_SUMMER_PK'}
        mask = ismember(AELT.MM,[11:12,1:3]) & LTS > start_date & LTS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        if isempty(d)
            x = 0;
            cmp = 1;
        else
            x = nansum(d);
            cmp = mean(~isnan(d));            
        end
    case {'ENERGY_UNI_ALL_TIMES_NONSUMMER_PK'}
        mask = ~ismember(AELT.MM,[11:12,1:3]) & LTS > start_date & LTS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        if isempty(d)
            x = 0;
            cmp = 1;
        else
            x = nansum(d);
            cmp = mean(~isnan(d));            
        end    
    case {'ENERGY_7-23_SUMMER_PK'}
        mask = ismember(AELT.MM,[11:12,1:3]) & AELT.HH >= 31 & AELT.HH <= 46 & LTS > start_date & LTS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        if isempty(d)
            x = 0;
            cmp = 1;
        else
            x = nansum(d);
            cmp = mean(~isnan(d));            
        end
    case {'ENERGY_7-23_NONSUMMER_PK'}
        mask = ~ismember(AELT.MM,[11:12,1:3]) & AELT.HH >= 31 & AELT.HH <= 46 & LTS > start_date & LTS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        if isempty(d)
            x = 0;
            cmp = 1;
        else
            x = nansum(d);
            cmp = mean(~isnan(d));            
        end
    
    case {'ENERGY_UNI_SEASONAL_SUMMER_PK'}
        mask = ismember(AELT.MM,[11:12,1:3]) & AELT.isWorkday_Melbourne & AELT.HH >= 31 & AELT.HH <= 46 & LTS > start_date & LTS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        if isempty(d)
            x = 0;
            cmp = 1;
        else
            x = nansum(d);
            cmp = mean(~isnan(d));            
        end
    case {'ENERGY_UNI_SEASONAL_NON-SUMMER_PK'}
        mask = ~ismember(AELT.MM,[11:12,1:3]) & AELT.isWorkday_Melbourne & AELT.HH >= 31 & AELT.HH <= 46 & LTS > start_date & LTS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        if isempty(d)
            x = 0;
            cmp = 1;
        else
            x = nansum(d);
            cmp = mean(~isnan(d));            
        end
    case {'ENERGY_UNI_SEASONAL_SUMMER_SH'}
        mask = ismember(AELT.MM,[11:12,1:3]) & AELT.isWorkday_Melbourne & AELT.HH >= 15 & AELT.HH <= 30 & LTS > start_date & LTS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        if isempty(d)
            x = 0;
            cmp = 1;
        else
            x = nansum(d);
            cmp = mean(~isnan(d));            
        end
    case {'ENERGY_UNI_SEASONAL_NON-SUMMER_SH'}
        mask = ~ismember(AELT.MM,[11:12,1:3]) & AELT.isWorkday_Melbourne & AELT.HH >= 15 & AELT.HH <= 30 & LTS > start_date & LTS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        if isempty(d)
            x = 0;
            cmp = 1;
        else
            x = nansum(d);
            cmp = mean(~isnan(d));            
        end
    case {'ENERGY_UNI_7-23_OP'}
        mask = ~(AELT.isWorkday_Melbourne & AELT.HH >= 15 & AELT.HH <= 46) & LTS > start_date & LTS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        x = nansum(d);
        cmp = mean(~isnan(d));

    case {'ENERGY_UNI_SEASONAL_9PM_SUMMER_PK'}
        mask = ismember(AELT.MM,[11:12,1:3]) & AELT.isWorkday_Melbourne & AELT.HH >= 31 & AELT.HH <= 42 & LTS > start_date & LTS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        if isempty(d)
            x = 0;
            cmp = 1;
        else
            x = nansum(d);
            cmp = mean(~isnan(d));            
        end
    case {'ENERGY_UNI_SEASONAL_9PM_SUMMER_SH'}
        mask = ismember(AELT.MM,[11:12,1:3]) & AELT.isWorkday_Melbourne & AELT.HH >= 15 & AELT.HH <= 30 & LTS > start_date & LTS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        if isempty(d)
            x = 0;
            cmp = 1;
        else
            x = nansum(d);
            cmp = mean(~isnan(d));            
        end        
    case {'ENERGY_UNI_SEASONAL_9PM_OP'}
        mask = ~(AELT.isWorkday_Melbourne & AELT.HH >= 15 & AELT.HH <= 42) & LTS > start_date & LTS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        if isempty(d)
            x = 0;
            cmp = 1;
        else
            x = nansum(d);
            cmp = mean(~isnan(d));            
        end  
    case {'ENERGY_UNI_SEASONAL_9PM_NON-SUMMER_PK'}
        mask = ~ismember(AELT.MM,[11:12,1:3]) & AELT.isWorkday_Melbourne & AELT.HH >= 31 & AELT.HH <= 42 & LTS > start_date & LTS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        if isempty(d)
            x = 0;
            cmp = 1;
        else
            x = nansum(d);
            cmp = mean(~isnan(d));            
        end
    case {'ENERGY_UNI_SEASONAL_9PM_NON-SUMMER_SH'}
        mask = ~ismember(AELT.MM,[11:12,1:3]) & AELT.isWorkday_Melbourne & AELT.HH >= 15 & AELT.HH <= 30 & LTS > start_date & LTS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        if isempty(d)
            x = 0;
            cmp = 1;
        else
            x = nansum(d);
            cmp = mean(~isnan(d));            
        end        

    case {'ENERGY_UNI_SEASONAL_RESI_SUMMER_PK'}
        % TODO: Summer Period is strictly when daylight savings begin to daylight savings end
        mask = ismember(AELT.MM,[10:12,1:3]) & AELT.isWeekday & AELT.HH >= 31 & AELT.HH <= 42 & LTS > start_date & LTS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        if isempty(d)
            x = 0;
            cmp = 1;
        else
            x = nansum(d);
            cmp = mean(~isnan(d));            
        end    
    case {'ENERGY_UNI_SEASONAL_RESI_NON-SUMMER_PK'}
        % TODO: Summer Period is strictly when daylight savings begin to daylight savings end
        mask = ~ismember(AELT.MM,[10:12,1:3]) & AELT.isWeekday & AELT.HH >= 31 & AELT.HH <= 42 & LTS > start_date & LTS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        if isempty(d)
            x = 0;
            cmp = 1;
        else
            x = nansum(d);
            cmp = mean(~isnan(d));            
        end          
    case {'ENERGY_UNI_SEASONAL_RESI_SUMMER_SH'}
        % TODO: Summer Period is strictly when daylight savings begin to daylight savings end
        mask = ismember(AELT.MM,[10:12,1:3]) & ((~AELT.isWeekday & AELT.HH >= 15 & AELT.HH <= 44) | (AELT.isWeekday & ismember(AELT.HH,[15:30 43:44]))) & LTS > start_date & LTS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        if isempty(d)
            x = 0;
            cmp = 1;
        else
            x = nansum(d);
            cmp = mean(~isnan(d));            
        end    
    case {'ENERGY_UNI_SEASONAL_RESI_NON-SUMMER_SH'}
        % TODO: Summer Period is strictly when daylight savings begin to daylight savings end
        mask = ~ismember(AELT.MM,[10:12,1:3]) & ((~AELT.isWeekday & AELT.HH >= 15 & AELT.HH <= 44) | (AELT.isWeekday & ismember(AELT.HH,[15:30 43:44]))) & LTS > start_date & LTS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        if isempty(d)
            x = 0;
            cmp = 1;
        else
            x = nansum(d);
            cmp = mean(~isnan(d));            
        end          
    case {'ENERGY_UNI_SEASONAL_RESI_OP'}
        mask = (AELT.HH <= 14 | AELT.HH >= 45) & LTS > start_date & LTS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        x = nansum(d);
        cmp = mean(~isnan(d));
    case {'ENERGY_WORKDAY_7-23_OP'}
        mask = (~AELT.isWorkday_Melbourne | AELT.HH <= 14 | AELT.HH >= 47) & LTS > start_date & LTS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        x = nansum(d);
        cmp = mean(~isnan(d));        
    case {'ENERGY_WORKDAY_7-23_SUMMER_PK'}
        mask = ismember(AELT.MM,[11:12,1:3]) & AELT.isWorkday_Melbourne & AELT.HH >= 15 & AELT.HH <= 46 & LTS > start_date & LTS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        if isempty(d)
            x = 0;
            cmp = 1;
        else
            x = nansum(d);
            cmp = mean(~isnan(d));            
        end        
    case {'ENERGY_WORKDAY_7-23_NONSUMMER_PK'}
        mask = ~ismember(AELT.MM,[11:12,1:3]) & AELT.isWorkday_Melbourne & AELT.HH >= 15 & AELT.HH <= 46 & LTS > start_date & LTS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        if isempty(d)
            x = 0;
            cmp = 1;
        else
            x = nansum(d);
            cmp = mean(~isnan(d));            
        end
    case {'ENERGY_UNI_7-19_OP'}
        mask = (~AELT.isWorkday_Melbourne | AELT.HH <= 14 | AELT.HH >= 39) & LTS > start_date & LTS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        x = nansum(d);
        cmp = mean(~isnan(d));        
    case {'ENERGY_UNI_7-19_SUMMER_PK'}
        mask = ismember(AELT.MM,[11:12,1:3]) & AELT.isWorkday_Melbourne & AELT.HH >= 15 & AELT.HH <= 38 & LTS > start_date & LTS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        if isempty(d)
            x = 0;
            cmp = 1;
        else
            x = nansum(d);
            cmp = mean(~isnan(d));            
        end        
    case {'ENERGY_UNI_7-19_NON-SUMMER_PK'}
        mask = ~ismember(AELT.MM,[11:12,1:3]) & AELT.isWorkday_Melbourne & AELT.HH >= 15 & AELT.HH <= 38 & LTS > start_date & LTS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        if isempty(d)
            x = 0;
            cmp = 1;
        else
            x = nansum(d);
            cmp = mean(~isnan(d));            
        end
    case {'ENERGY_UNI_M-F_7-23_SUMMER_PK'}
        mask = ismember(AELT.MM,[11:12,1:3]) & AELT.isWeekday & AELT.HH >= 15 & AELT.HH <= 46 & LTS > start_date & LTS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        if isempty(d)
            x = 0;
            cmp = 1;
        else
            x = nansum(d);
            cmp = mean(~isnan(d));            
        end
    case {'ENERGY_UNI_M-F_7-23_NONSUMMER_PK'}
        mask = ismember(AELT.MM,4:10) & AELT.isWeekday & AELT.HH >= 15 & AELT.HH <= 46 & LTS > start_date & LTS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        if isempty(d)
            x = 0;
            cmp = 1;
        else
            x = nansum(d);
            cmp = mean(~isnan(d));            
        end
    case {'ENERGY_UNI_M-F_7-23_OP'}
        mask = ~(AELT.isWeekday & AELT.HH >= 15 & AELT.HH <= 46) & LTS > start_date & LTS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        if isempty(d)
            x = 0;
            cmp = 1;
        else
            x = nansum(d);
            cmp = mean(~isnan(d));            
        end
        
        
    case {'CAPACITY_UNI_ROLLING_DEMAND'}        
        % TODO: allow to calc correctly for a multi-month date range
        [s.y,s.m,s.d] = datevec(start_date);
        [e.y,e.m,e.d] = datevec(end_date);
        e = datenum(e.y,e.m+1,1)-1;
        s = addtodate(e,-1,'year')+1;
        mask = AELT.isWorkday_Melbourne & AELT.HH>=15 & AELT.HH <= 38 & LTS > s & LTS <= e+1;
        
        c = MDC.IMD.KVA(mask);
        d = MDC.IMD.KW(mask);
        ind = find(nanmax(d)==d, 1);       % KVA at max KW
        if ~isempty(ind)
            x = c(ind) * monthprop;
            cmp = mean(~isnan(d));
        else
            x = 0;
            cmp = 1;
        end        
    case {'CAPACITY_UNI'}
        % TODO: adapt to cope with multi-month & part-month ranges
        mask = ismember(AELT.MM,[11,12,1,2,3]) & AELT.isWorkday_Melbourne & AELT.HH >= 31 & AELT.HH <= 36 & LTS > start_date & LTS <= end_date+1;
        c = MDC.IMD.KVA(mask);
        d = MDC.IMD.KW(mask);
        if isempty(d)
            x = 0;
            cmp = 1;
        else
            ind = find(nanmax(d)==d, 1);       % KVA at max KW
            if ~isempty(ind)
                x = c(ind);
            else
                x = 0;
            end
            cmp = mean(~isnan(d));
        end
    case {'DEMAND_UNI_SEASONAL_SUMMER'}
        mask = ismember(AELT.MM,[12,1,2,3]) & AELT.isWorkday_Melbourne & AELT.HH >= 31 & AELT.HH <= 42 & LTS > start_date & LTS <= end_date+1;
        d = MDC.IMD.KW(mask);
        if isempty(d)
            x = 0;
            cmp = 1;
        else
            x = nanmax(d);
            cmp = mean(~isnan(d));
        end
    case {'DEMAND_UNI_SEASONAL_NONSUMMER'}
        mask = ismember(AELT.MM,[4:11]) & AELT.isWorkday_Melbourne & AELT.HH >= 31 & AELT.HH <= 42 & LTS > start_date & LTS <= end_date+1;
        d = MDC.IMD.KW(mask);
        if isempty(d)
            x = 0;
            cmp = 1;
        else
            x = nanmax(d);
            cmp = mean(~isnan(d));
        end
    case {'DEMAND_UNI_SUMMER_LVMKWTOU'}
        mask = ismember(AELT.MM,[12,1,2,3]) & AELT.isWorkday_Melbourne & AELT.HH >= 21 & AELT.HH <= 36 & LTS > start_date & LTS <= end_date+1;
        d = MDC.IMD.KW(mask);
        if isempty(d)
            x = 0;
            cmp = 1;
        else
            x = nanmax(d);
            cmp = mean(~isnan(d));
        end
    case {'DEMAND_UNI_NONSUMMER_LVMKWTOU'}
        mask = ismember(AELT.MM,[4:11]) & AELT.isWorkday_Melbourne & AELT.HH >= 21 & AELT.HH <= 36 & LTS > start_date & LTS <= end_date+1;
        d = MDC.IMD.KW(mask);
        if isempty(d)
            x = 0;
            cmp = 1;
        else
            x = nanmax(d);
            cmp = mean(~isnan(d));
        end
    case {'DEMAND_UNI_TOU'}
        % TODO: adapt to cope with multi-month & part-month ranges
        mask = ismember(AELT.MM,[11,12,1,2,3]) & AELT.HH >= 29 & AELT.HH <= 38 & LTS > start_date & LTS <= end_date+1;
        d = MDC.IMD.KW(mask);
        if isempty(d)
            x = 0;
            cmp = 1;
        else
            x = nanmax(d);
            cmp = mean(~isnan(d));
        end           
    case {'DEMAND_UNI_SUMMER_LVKWTOU'}
        mask = ismember(AELT.MM,[11,12,1,2,3]) & AELT.isWorkday_Melbourne & AELT.HH >= 31 & AELT.HH <= 36 & LTS > start_date & LTS <= end_date+1;
        d = MDC.IMD.KW(mask);
        if isempty(d)
            x = 0;
            cmp = 1;
        else
            x = nanmax(d);
            cmp = mean(~isnan(d));
        end
        
    % ---------------------- SP AUSNET DEFINITIONS --------------------
    
    case {'ENERGY_SPAUS_8-20_7_DAY_PK'}
        mask = AEST.isWeekday & AEST.HH >= 17 & AEST.HH <= 40 & TS > start_date & TS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        if isempty(d)
            x = 0;
            cmp = 1;
        else
            x = nansum(d);
            cmp = mean(~isnan(d));            
        end
    case {'ENERGY_SPAUS_8-20_7_DAY_OP'}
        mask = ~(AEST.isWeekday & AEST.HH >= 17 & AEST.HH <= 40) & TS > start_date & TS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        if isempty(d)
            x = 0;
            cmp = 1;
        else
            x = nansum(d);
            cmp = mean(~isnan(d));            
        end
    case {'ENERGY_SPAUS_LV_SEASONAL_OP'}
        mask1 = ismember(AELT.MM,[6,7,8]) & AEST.isWeekday & AEST.HH >= 33 & AEST.HH <= 40 & TS > start_date & TS <= end_date+1;
        mask2 = ismember(AELT.MM,[12,1,2,3]) & AEST.isWeekday & AEST.HH >= 25 & AEST.HH <= 40 & TS > start_date & TS <= end_date+1;
        mask = ~mask1 & ~mask2;
        d = MDC.IMD.Net_KWH(mask);
        if isempty(d)
            x = 0;
            cmp = 1;
        else
            x = nansum(d);
            cmp = mean(~isnan(d));            
        end
    case {'ENERGY_SPAUS_LV_SEASONAL_SUMMER_PK'}
        mask = ismember(AELT.MM,[12,1,2,3]) & AEST.isWeekday & AEST.HH >= 29 & AEST.HH <= 36 & TS > start_date & TS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        if isempty(d)
            x = 0;
            cmp = 1;
        else
            x = nansum(d);
            cmp = mean(~isnan(d));
        end
    case {'ENERGY_SPAUS_LV_SEASONAL_SUMMER_SH'}
        mask = ismember(AELT.MM,[12,1,2,3]) & AEST.isWeekday & ((AEST.HH >= 25 & AEST.HH <= 28) | (AEST.HH >= 37 & AEST.HH <= 40)) & TS > start_date & TS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        if isempty(d)
            x = 0;
            cmp = 1;
        else
            x = nansum(d);
            cmp = mean(~isnan(d));
        end
    case {'ENERGY_SPAUS_LV_SEASONAL_WINTER_PK'}
        mask = ismember(AELT.MM,[6,7,8]) & AEST.isWeekday & AEST.HH >= 33 & AEST.HH <= 40 & TS > start_date & TS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        if isempty(d)
            x = 0;
            cmp = 1;
        else
            x = nansum(d);
            cmp = mean(~isnan(d));
        end
    case {'ENERGY_SPAUS_CRITICAL_PEAK_DEMAND_PK'}
        mask = AEST.isWeekday & ismember(AEST.HH,[15:20 33:46]) & TS > start_date & TS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        if isempty(d)
            x = 0;
            cmp = 1;
        else
            x = nansum(d);
            cmp = mean(~isnan(d));            
        end                        
    case {'ENERGY_SPAUS_CRITICAL_PEAK_DEMAND_SH'}
        mask = AEST.isWeekday & ismember(AEST.HH,[21:32]) & TS > start_date & TS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        if isempty(d)
            x = 0;
            cmp = 1;
        else
            x = nansum(d);
            cmp = mean(~isnan(d));            
        end                
    case {'ENERGY_SPAUS_CRITICAL_PEAK_DEMAND_OP'}
        mask = ((AEST.isWeekday & ismember(AEST.HH,[1:14 47:48])) | ~AEST.isWeekday) & TS > start_date & TS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        if isempty(d)
            x = 0;
            cmp = 1;
        else
            x = nansum(d);
            cmp = mean(~isnan(d));            
        end                    
        
        
    case {'CAPACITY_SPAUS'}
        % 'Fixed value' -- TODO read in specified demand values
        x = 0;
        cmp = 1;
        
    case {'CAPACITY_SPAUS_CRITICAL_PEAK'}
        % CPD: 17/12/2015, 22/02/2016, 23/02/2016, 2/3/2016, 23/3/2016, 2pm to 6pm
%         CPD1 = datenum(2015,12,17);
%         CPD2 = datenum(2016,2,22);
%         CPD3 = datenum(2016,2,23);
%         CPD4 = datenum(2016,3,2);
%         CPD5 = datenum(2016,3,23);
        
        % CPD: 9/3/2017, 9/02/2017, 30/01/2017, 16/1/2017, 17/1/2017, 2pm to 6pm
        CPD1 = datenum(2017,1,17);
        CPD2 = datenum(2017,1,16);
        CPD3 = datenum(2017,1,30);
        CPD4 = datenum(2017,2,9);
        CPD5 = datenum(2017,3,9);
        
        mask1 = ismember(AEST.HH,[29:36]) & TS > CPD1 & TS <= CPD1+1;
        mask2 = ismember(AEST.HH,[29:36]) & TS > CPD2 & TS <= CPD2+1;
        mask3 = ismember(AEST.HH,[29:36]) & TS > CPD3 & TS <= CPD3+1;
        mask4 = ismember(AEST.HH,[29:36]) & TS > CPD4 & TS <= CPD4+1;
        mask5 = ismember(AEST.HH,[29:36]) & TS > CPD5 & TS <= CPD5+1;
        
        d1 = MDC.IMD.KVA(mask1);
        d2 = MDC.IMD.KVA(mask2);
        d3 = MDC.IMD.KVA(mask3);
        d4 = MDC.IMD.KVA(mask4);
        d5 = MDC.IMD.KVA(mask5);
        
        if isempty(d1)
            x1 = nan;
        else
            x1 = nanmax(d1);
        end
        if isempty(d2)
            x2 = nan;
        else
            x2 = nanmax(d2);
        end
        if isempty(d3)
            x3 = nan;
        else
            x3 = nanmax(d3);
        end
        if isempty(d4)
            x4 = nan;
        else
            x4 = nanmax(d4);
        end
        if isempty(d5)
            x5 = nan;
        else
            x5 = nanmax(d5);
        end
        
        if isnan(x1) && isnan(x2) && isnan(x3) && isnan(x4) && isnan(x5)
            x = 0;
            cmp = 1;
        else
            x = nanmean([x1,x2,x3,x4,x5]);
            cmp = mean(~isnan([d1,d2,d3,d4,d5]));
        end
    % ---------------------- POWERCOR VIC DEFINITIONS --------------------

    case {'ENERGY_M-F_07-23_PK'}
        mask = AEST.isWeekday & AEST.HH >= 15 & AEST.HH <= 46 & TS > start_date & TS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        x = nansum(d);
        cmp = mean(~isnan(d));
    case {'ENERGY_M-Sun_7-23_PK'}
        mask = AEST.HH >= 15 & AEST.HH <= 46 & TS > start_date & TS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        x = nansum(d);
        cmp = mean(~isnan(d));
    case {'ENERGY_M-Sun_7-23_OP'}
        mask = ~(AEST.HH >= 15 & AEST.HH <= 46) & TS > start_date & TS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        x = nansum(d);
        cmp = mean(~isnan(d));
    case {'ENERGY_PCOR_SEASONAL_SUMMER_PK'}
        mask = ismember(AEST.MM,[1 2 3]) & AEST.isWeekday & AEST.HH >= 15 & AEST.HH <= 38 & TS > start_date & TS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        x = nansum(d);
        cmp = mean(~isnan(d));
    case {'ENERGY_PCOR_SEASONAL_SUMMER_SH'}
        mask = ismember(AEST.MM,[1 2 3]) & ~AEST.isWeekday & AEST.HH >= 15 & AEST.HH <= 38 & TS > start_date & TS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        x = nansum(d);
        cmp = mean(~isnan(d));
    case {'ENERGY_PCOR_SEASONAL_SUMMER_OP'}
        mask = ismember(AEST.MM,[1 2 3]) & (AEST.HH < 15 | AEST.HH > 38) & TS > start_date & TS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        x = nansum(d);
        cmp = mean(~isnan(d));
    case {'ENERGY_PCOR_SEASONAL_NONSUMMER_PK'}
        mask = ~ismember(AEST.MM,[1 2 3]) & AEST.isWeekday & AEST.HH >= 15 & AEST.HH <= 38 & TS > start_date & TS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        x = nansum(d);
        cmp = mean(~isnan(d));
    case {'ENERGY_PCOR_SEASONAL_NONSUMMER_SH'}
        mask = ~ismember(AEST.MM,[1 2 3]) & ~AEST.isWeekday & AEST.HH >= 15 & AEST.HH <= 38 & TS > start_date & TS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        x = nansum(d);
        cmp = mean(~isnan(d));
    case {'ENERGY_PCOR_SEASONAL_NONSUMMER_OP'}
        mask = ~ismember(AEST.MM,[1 2 3]) & (AEST.HH < 15 | AEST.HH > 38) & TS > start_date & TS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        x = nansum(d);
        cmp = mean(~isnan(d));        
    case {'ENERGY_CITI_SUMMER_PK'}
        mask = ismember(AELT.MM,[12 1 2]) & AELT.isWeekday & AELT.HH >= 15 & AELT.HH <= 38 & TS > start_date & TS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        x = nansum(d);
        cmp = mean(~isnan(d));
    case {'ENERGY_CITI_SUMMER_SH'}
        mask = ismember(AELT.MM,[12 1 2]) & ~AELT.isWeekday & AELT.HH >= 15 & AELT.HH <= 38 & TS > start_date & TS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        x = nansum(d);
        cmp = mean(~isnan(d));
    case {'ENERGY_CITI_SUMMER_OP'}
        mask = ismember(AELT.MM,[12 1 2]) & (AELT.HH < 15 | AELT.HH > 38) & TS > start_date & TS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        x = nansum(d);
        cmp = mean(~isnan(d));
    case {'ENERGY_CITI_NONSUMMER_PK'}
        mask = ~ismember(AELT.MM,[12 1 2]) & AELT.isWeekday & AELT.HH >= 15 & AELT.HH <= 38 & TS > start_date & TS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        x = nansum(d);
        cmp = mean(~isnan(d));
    case {'ENERGY_CITI_NONSUMMER_SH'}
        mask = ~ismember(AELT.MM,[12 1 2]) & ~AELT.isWeekday & AELT.HH >= 15 & AELT.HH <= 38 & TS > start_date & TS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        x = nansum(d);
        cmp = mean(~isnan(d));
    case {'ENERGY_CITI_NONSUMMER_OP'}
        mask = ~ismember(AELT.MM,[12 1 2]) & (AELT.HH < 15 | AELT.HH > 38) & TS > start_date & TS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        x = nansum(d);
        cmp = mean(~isnan(d));
    case {'ENERGY_CITI_RESI_SUMMER_PK'}
        mask = ismember(AELT.MM,[12 1 2]) & AELT.isWeekday & AELT.HH >= 31 & AELT.HH <= 42 & TS > start_date & TS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        x = nansum(d);
        cmp = mean(~isnan(d));
    case {'ENERGY_CITI_RESI_SUMMER_SH'}
        mask = ismember(AELT.MM,[12 1 2]) & ((~AELT.isWeekday & AELT.HH >= 15 & AELT.HH <= 44) | (AELT.isWeekday & AELT.HH >= 15 & AELT.HH <= 30) | (AELT.isWeekday & AELT.HH >= 43 & AELT.HH <= 44)) & TS > start_date & TS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        x = nansum(d);
        cmp = mean(~isnan(d));
    case {'ENERGY_CITI_RESI_SUMMER_OP'}
        mask = ismember(AELT.MM,[12 1 2]) & (AELT.HH < 15 | AELT.HH > 44) & TS > start_date & TS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        x = nansum(d);
        cmp = mean(~isnan(d));
    case {'ENERGY_CITI_RESI_NONSUMMER_PK'}
        mask = ~ismember(AELT.MM,[12 1 2]) & AELT.isWeekday & AELT.HH >= 31 & AELT.HH <= 42 & TS > start_date & TS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        x = nansum(d);
        cmp = mean(~isnan(d));
    case {'ENERGY_CITI_RESI_NONSUMMER_SH'}
        mask = ~ismember(AELT.MM,[12 1 2]) & ((~AELT.isWeekday & AELT.HH >= 15 & AELT.HH <= 44) | (AELT.isWeekday & AELT.HH >= 15 & AELT.HH <= 30) | (AELT.isWeekday & AELT.HH >= 43 & AELT.HH <= 44)) & TS > start_date & TS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        x = nansum(d);
        cmp = mean(~isnan(d));
    case {'ENERGY_CITI_RESI_NONSUMMER_OP'}
        mask = ~ismember(AELT.MM,[12 1 2]) & (AELT.HH < 15 | AELT.HH > 44) & TS > start_date & TS <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        x = nansum(d);
        cmp = mean(~isnan(d));
        
    case {'DEMAND_POWERCOR'}        
        % rolling 12-month maximum KW. Express in KW-months. 
        % TODO: allow to calc correctly for a multi-month date range
        [s.y,s.m,s.d] = datevec(start_date);
        [e.y,e.m,e.d] = datevec(end_date);
        e = datenum(e.y,e.m+1,1)-1;
        s = addtodate(e,-1,'year')+1;
        mask = TS > s & TS <= e+1;
        % Use 15min data if available
        if sum(isnan(MDC.IMD.KW15)) == length(MDC.IMD.KW15)
            d = MDC.IMD.KW(mask);
        else
            d = MDC.IMD.KW15(mask);
        end
        x = nanmax(d) * monthprop;
        cmp = mean(~isnan(d));
    case {'CAPACITY_POWERCOR'}
        % rolling 12-month maximum KVA. Express in KVA-months. 
        % TODO: allow to calc correctly for a multi-month date range        
        [s.y,s.m,s.d] = datevec(start_date);
        [e.y,e.m,e.d] = datevec(end_date);
        e = datenum(e.y,e.m+1,1)-1;
        s = addtodate(e,-1,'year')+1;
        mask = TS > s & TS <= e+1;        
        % Use 15min data if available
        if sum(isnan(MDC.IMD.KW15)) == length(MDC.IMD.KW15)
            d = MDC.IMD.KVA(mask);
        else
            d = MDC.IMD.KVA15(mask);
        end
        x = nanmax(d) * monthprop;
        cmp = mean(~isnan(d));
    case {'DEMAND_POWERCOR_NONSUMMER_10-18'}
        % Apr-Nov, Mon-Fri (excl pub hols) 1000-1800
        mask = ismember(AELT.MM,[4,5,6,7,8,9,10,11]) & AELT.isWorkday_Melbourne & AELT.HH >= 21 & AELT.HH <= 36 & LTS > start_date & LTS <= end_date+1;
        % Use 15min data if available
        if sum(isnan(MDC.IMD.KW15)) == length(MDC.IMD.KW15)
            d = MDC.IMD.KW(mask);
        else
            d = MDC.IMD.KW15(mask);
        end        
        if isempty(d)
            x = 0;
            cmp = 1;
        else
            x = nanmax(d);
            cmp = mean(~isnan(d));
        end
    case {'DEMAND_POWERCOR_SUMMER_10-18'}
        % Dec-Mar, Mon-Fri (excl pub hols) 1000-1800
        mask = ismember(AELT.MM,[12,1,2,3]) & AELT.isWorkday_Melbourne & AELT.HH >= 21 & AELT.HH <= 36 & LTS > start_date & LTS <= end_date+1;
        % Use 15min data if available
        if sum(isnan(MDC.IMD.KW15)) == length(MDC.IMD.KW15)
            d = MDC.IMD.KW(mask);
        else
            d = MDC.IMD.KW15(mask);
        end        
        if isempty(d)
            x = 0;
            cmp = 1;
        else
            x = nanmax(d);
            cmp = mean(~isnan(d));
        end
    case {'DEMAND_CITIPOWER'}
        % rolling 12-month maximum KW. Express in KW-months. 
        % TODO: allow to calc correctly for a multi-month date range
        [s.y,s.m,s.d] = datevec(start_date);
        [e.y,e.m,e.d] = datevec(end_date);
        e = datenum(e.y,e.m+1,1)-1;
        s = addtodate(e,-1,'year')+1;
        mask = TS > s & TS <= e+1;
        % Use 15min data if available
        if sum(isnan(MDC.IMD.KW15)) == length(MDC.IMD.KW15)
            d = MDC.IMD.KW(mask);
        else
            d = MDC.IMD.KW15(mask);
        end        
        x = nanmax(d) * monthprop;
        cmp = mean(~isnan(d));
    case {'CAPACITY_CITIPOWER'}
        % rolling 12-month maximum KVA15. Express in KVA-months. 
        % TODO: allow to calc correctly for a multi-month date range        
        [s.y,s.m,s.d] = datevec(start_date);
        [e.y,e.m,e.d] = datevec(end_date);
        e = datenum(e.y,e.m+1,1)-1;
        s = addtodate(e,-1,'year')+1;
        mask = TS > s & TS <= e+1;
        d = MDC.IMD.KVA15(mask);
        x = nanmax(d) * monthprop;
        cmp = mean(~isnan(d));
    case {'DEMAND_CITIPOWER_NONSUMMER_10-18'}
        % Apr-Nov, Mon-Fri (excl pub hols) 1000-1800
        mask = ismember(AELT.MM,[4,5,6,7,8,9,10,11]) & AELT.isWorkday_Melbourne & AELT.HH >= 21 & AELT.HH <= 36 & LTS > start_date & LTS <= end_date+1;
        % Use 15min data if available
        if sum(isnan(MDC.IMD.KW15)) == length(MDC.IMD.KW15)
            d = MDC.IMD.KW(mask);
        else
            d = MDC.IMD.KW15(mask);
        end        
        if isempty(d)
            x = 0;
            cmp = 1;
        else
            x = nanmax(d);
            cmp = mean(~isnan(d));
        end
    case {'DEMAND_CITIPOWER_SUMMER_10-18'}
        % Dec-Mar, Mon-Fri (excl pub hols) 1000-1800
        mask = ismember(AELT.MM,[12,1,2,3]) & AELT.isWorkday_Melbourne & AELT.HH >= 21 & AELT.HH <= 36 & LTS > start_date & LTS <= end_date+1;
        % Use 15min data if available
        if sum(isnan(MDC.IMD.KW15)) == length(MDC.IMD.KW15)
            d = MDC.IMD.KW(mask);
        else
            d = MDC.IMD.KW15(mask);
        end        
        if isempty(d)
            x = 0;
            cmp = 1;
        else
            x = nanmax(d);
            cmp = mean(~isnan(d));
        end
    case {'DEMAND_CITIPOWER_NONSUMMER_15-21'}
        % Apr-Nov, Mon-Fri (excl pub hols) 1500-2100
        mask = ismember(AELT.MM,[4,5,6,7,8,9,10,11]) & AELT.isWorkday_Melbourne & AELT.HH >= 31 & AELT.HH <= 42 & LTS > start_date & LTS <= end_date+1;        
        % Use 15min data if available
        if sum(isnan(MDC.IMD.KW15)) == length(MDC.IMD.KW15)
            d = MDC.IMD.KW(mask);
        else
            d = MDC.IMD.KW15(mask);
        end        
        if isempty(d)
            x = 0;
            cmp = 1;
        else
            x = nanmax(d);
            cmp = mean(~isnan(d));
        end
    case {'DEMAND_CITIPOWER_SUMMER_15-21'}
        % Dec-Mar, Mon-Fri (excl pub hols) 1500-2100
        mask = ismember(AELT.MM,[12,1,2,3]) & AELT.isWorkday_Melbourne & AELT.HH >= 31 & AELT.HH <= 42 & LTS > start_date & LTS <= end_date+1;
        % Use 15min data if available
        if sum(isnan(MDC.IMD.KW15)) == length(MDC.IMD.KW15)
            d = MDC.IMD.KW(mask);
        else
            d = MDC.IMD.KW15(mask);
        end
        if isempty(d)
            x = 0;
            cmp = 1;
        else
            x = nanmax(d);
            cmp = mean(~isnan(d));
        end
        
    % ---------------------- SA DEFINITIONS --------------------
    case {'ENERGY_BD_7-21_CST_PK'}
        % TODO: implement public holidays
        mask = CST.isWorkday_Adelaide & CST.HH >= 15 & CST.HH <= 42 & TS_CST > start_date & TS_CST <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        x = nansum(d);
        cmp = mean(~isnan(d));
    case {'ENERGY_BD_7-21_CST_OP'}
        % TODO: implement public holidays
        mask = ~(CST.isWorkday_Adelaide & CST.HH >= 15 & CST.HH <= 42) & TS_CST > start_date & TS_CST <= end_date+1;
        d = MDC.IMD.Net_KWH(mask);
        x = nansum(d);
        cmp = mean(~isnan(d));    
    case {'DEMAND_SAPOWER_AGREED'}
        % Should be contract demand
        [s.y,s.m,s.d] = datevec(start_date);
        [e.y,e.m,e.d] = datevec(end_date);
        e = datenum(e.y,e.m+1,1)-1;
        s = addtodate(e,-3,'year')+1;
        mask = CST.isWorkday_Adelaide & ismember(CST.MM,[11:12 1:3]) & CST.HH >= 23 & CST.HH <= 40 & CST.TS > s & CST.TS <= e+1;
        d = MDC.IMD.KVA(mask);
        x = nanmax(d);
        x = x * monthprop;
        cmp = mean(~isnan(d));
        
    case {'DEMAND_SAPOWER_ADDITIONAL'}    
        [s.y,s.m,s.d] = datevec(start_date);
        [e.y,e.m,e.d] = datevec(end_date);
        e = datenum(e.y,e.m+1,1)-1;
        s = addtodate(e,-3,'year')+1;
        mask = CST.TS > s & CST.TS <= e+1;
        d = MDC.IMD.KVA(mask);
        x = nanmax(d) - actualUsage(MDC,'DEMAND_SAPOWER_AGREED', start_date, end_date);        
        x = x * monthprop;
        cmp = mean(~isnan(d));
        
    case {'DEMAND_SAPOWER_PEAK'}
        % note: actually defined in Central Daylight Savings Time 1600-2100
        % TODO: adapt to cope with multi-month & part-month ranges
        mask = CST.isWorkday_Adelaide & ismember(CST.MM,[11:12 1:3]) & CST.HH >= 31 & CST.HH <= 40 & CST.TS > start_date & CST.TS <= end_date+1;
        d = MDC.IMD.KVA(mask);
        if isempty(d)
            x = 0;
            cmp = 1;
        else
            x = nanmax(d);
            cmp = mean(~isnan(d));            
        end        
        
    case {'DEMAND_SAPOWER_SHOULDER'}
        % note: actually defined in Central Daylight Savings Time 1200-1600
        % TODO: adapt to cope with multi-month & part-month ranges
        mask = CST.isWorkday_Adelaide & ((ismember(CST.MM,[11:12 1:3]) & CST.HH >= 23 & CST.HH <= 30) | (ismember(CST.MM,[4:10]) & CST.HH >= 25 & CST.HH <= 32)) & CST.TS > start_date & CST.TS <= end_date+1;
        d = MDC.IMD.KVA(mask);
        if isempty(d)
            x = 0;
            cmp = 1;
        else
            x = nanmax(d);
            cmp = mean(~isnan(d));            
        end           
    
        
        
    otherwise
        x = NaN; cmp = NaN;
        % warning(['Invalid definition: ' usage_code]);
        
end
end

