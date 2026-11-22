function s = fmri_ticklabel(v)
% FMRI_TICKLABEL  Formats a colourbar endpoint for display.
%
% Formats numeric colour limits as compact, readable labels. Precision adapts
% to the value: small values retain meaningful decimal places, values below
% 100 use up to two decimals, and larger values are shown as integers.
% Unnecessary trailing zeros are removed.
%
% Used by toolbox viewers to format colourbar endpoints consistently.
%
% See also: fmri_showslices, fmri_showselectslices, fmri_showplanes

if ~isfinite(v), s = sprintf('%g', v); return, end
if v == 0,       s = '0';              return, end

a = abs(v);
if a >= 100
    d = 0;
elseif a >= 1
    d = 2;
else
    d = max(2, 2 - floor(log10(a)));   % 0.125 -> 3 dp, 0.001 -> 5 dp
end

s = sprintf('%.*f', d, v);
if any(s == '.')
    s = regexprep(s, '0+$', '');
    s = regexprep(s, '\.$', '');
end