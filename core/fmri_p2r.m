function r = fmri_p2r(p, df, tail)
% FMRI_P2R  Correlation magnitude corresponding to a given p-threshold.
%
% Returns the correlation magnitude associated with the specified p-value,
% degrees of freedom and tail setting. This is the inverse of fmri_r2p and can
% be used to choose a display threshold or report the sensitivity of an analysis.
% 
%
% Usage:
%   r = fmri_p2r(p, df)
%   r = fmri_p2r(p, df, tail)
%
% Inputs:
%   P     - Desired p-value threshold, e.g. 0.001. May be a vector.
%   DF    - Degrees of freedom. For a single time series this is the EFFECTIVE
%           df from fmri_effdf, not the number of time points - see below.
%   TAIL  - 2 for two-tailed (default), 1 for one-tailed.
%
% Outputs:
%   R     - The correlation magnitude at which p equals the requested value.
%
% WHY THE THRESHOLD DEPENDS ON DF
%   The significance of a correlation depends on the number of independent
%   observations. Therefore, a fixed threshold such as r > 0.3 does not
%   correspond to the same p-value across datasets. Deriving the threshold
%   from the relevant degrees of freedom gives the correlation associated
%   with the requested significance level.
%
%   For time-series data, use the effective degrees of freedom. Filtering and
%   smoothing typically introduce temporal dependence, so the nominal number
%   of time points may overestimate the independent information in the data:
%
%       df_eff = fmri_effdf(regressor, one_voxel_timeseries);
%       r_crit = fmri_p2r(0.001, df_eff);
%
% RELATION TO FMRI_R2P
%   fmri_p2r converts a p-value to its corresponding correlation threshold,
%   while fmri_r2p performs the reverse conversion:
%
%       fmri_r2p(fmri_p2r(0.001, 50), 50)  % returns 0.001
% 
% Examples:
%   r_crit = fmri_p2r(0.001, 148);           % p < 0.001, two-tailed
%   fmri_showslices(r_map, 1, 2, [0 0.8], [], [], 1, 'hot', r_crit);
%
%   % Threshold matched to the data's real information content
%   df_eff = fmri_effdf(reg, data(1,:)');
%   fmri_showslices(r_map, 1, 2, [0 0.8], [], [], 1, 'hot', fmri_p2r(0.001, df_eff));
%
% See also: fmri_r2p, fmri_p2t, fmri_effdf, fmri_fisherz, fmri_ttest

if nargin < 3 || isempty(tail), tail = 2; end
if ~ismember(tail, [1 2])
    error('fmri_p2r:badTail', ...
        ['TAIL must be 1 (one-tailed) or 2 (two-tailed).\nGot %s.'], mat2str(tail));
end
if any(p(:) <= 0) || any(p(:) >= 1)
    error('fmri_p2r:badP', ...
        ['P must be strictly between 0 and 1.\nGot %s.'], mat2str(p(:)'));
end
if ~isscalar(df) || df <= 3
    error('fmri_p2r:badDF', ...
        ['DF must be a scalar above 3 (the Fisher transform divides by ' ...
         'sqrt(DF-3)).\nGot %s. If this came from fmri_effdf on heavily ' ...
         'filtered data, the\ndata may carry too little independent ' ...
         'information to test.'], mat2str(df));
end

% Critical z under the Fisher transform, then invert it.
%   z = atanh(r)*sqrt(df-3)  =>  r = tanh(z/sqrt(df-3))

% norminv(1-q) == sqrt(2)*erfcinv(2*q); erfcinv is base MATLAB, so no
% Statistics Toolbox is needed. 
if tail == 2, q = p/2; else, q = p; end
z_crit = sqrt(2) * erfcinv(2 * q);
r = tanh(z_crit ./ sqrt(df - 3));
end