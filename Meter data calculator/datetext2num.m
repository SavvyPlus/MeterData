function dn = datetext2num( date_cellstr, default_val )
%DATETEXT2NUM Summary of this function goes here
%   Detailed explanation goes here
m = strcmp(date_cellstr,'null');
dn = nan(size(m));
dn(~m) = datenum(date_cellstr,'yyyy-mm-dd HH:MM:SS');
if nargin > 1
    dn(m) = default_val;
end
end

