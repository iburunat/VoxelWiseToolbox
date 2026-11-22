function p = fmri_fisherz2p(z)
% FMRI_FISHERZ2P  Two-tailed p-value from a Fisher z-score.
%
% Usage:
%   p = fmri_fisherz2p(z)
%
% Inputs:
%   Z  - Standardised Fisher z-score(s), from fmri_fisherz. Any shape.
%
% Outputs:
%   P  - Two-tailed p-value(s), same shape as Z.
%
% Examples:
%   z = fmri_fisherz(r_map, df);
%   p = fmri_fisherz2p(z);
%
% See also: fmri_fisherz, fmri_r2p, fmri_effdf

p = erfc(abs(z) / sqrt(2)); % dependency-free
end