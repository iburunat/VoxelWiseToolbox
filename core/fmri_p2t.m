function t = fmri_p2t(p, df, tail)
% FMRI_P2T  t-value corresponding to a given p-threshold.
%
% Returns the t-value corresponding to a given p-value and degrees of freedom.
% This can be used to match a figure's display threshold to the significance
% threshold used in the analysis, avoiding the display of voxels that do not
% meet that threshold.
%
% Usage:
%   t = fmri_p2t(p, df)
%   t = fmri_p2t(p, df, tail)
%
% Inputs:
%   P     - Desired p-value threshold, e.g. 0.001. May be a vector.
%   DF    - Degrees of freedom. For a group analysis over N participants this
%           is N-1, NOT the number of time points - the observations being
%           tested are participants.
%   TAIL  - 2 for two-tailed (default), 1 for one-tailed.
%
% Outputs:
%   T     - The t magnitude at which p equals the requested value.
%
% SMALL SAMPLES ARE THE CASE TO WATCH
%   Critical t rises steeply as df falls, and the round numbers that look
%   reasonable are badly wrong at small N:
%
%       df = 100 :  p < 0.001 needs |t| >=  3.39
%       df =  14 :  p < 0.001 needs |t| >=  4.14
%       df =   7 :  p < 0.001 needs |t| >=  5.41
%       df =   2 :  p < 0.001 needs |t| >= 31.60
%
%   Drawing a df = 2 map at |t| >= 2 shows roughly 18% of the brain by chance.
%
% Note on colour limits: use a small multiple of T_CRIT instead of the largest
% absolute t-value in the map. At low degrees of freedom, a few very large
% t-values can stretch the colour scale, making the remaining significant
% values difficult to distinguish.
% 
% Examples:
%   [t_map, p_map, df] = fmri_ttest(z_maps);
%   t_crit = fmri_p2t(0.001, df);
%   fmri_showslices(t_map, 1, 2, [-3*t_crit 3*t_crit], [], [], 1, [], t_crit);
%
% See also: fmri_p2r, fmri_r2p, fmri_ttest, fmri_effdf

if nargin < 3 || isempty(tail), tail = 2; end
if ~ismember(tail, [1 2])
    error('fmri_p2t:badTail', ...
        ['TAIL must be 1 (one-tailed) or 2 (two-tailed).\nGot %s.'], mat2str(tail));
end
if any(p(:) <= 0) || any(p(:) >= 1)
    error('fmri_p2t:badP', ...
        ['P must be strictly between 0 and 1.\nGot %s.'], mat2str(p(:)'));
end
if ~isscalar(df) || df < 1
    error('fmri_p2t:badDF', ...
        ['DF must be a scalar of at least 1.\nGot %s.'], mat2str(df));
end

% Compute the inverse Student's t CDF using bisection and the incomplete beta
% function. BETAINC is included in base MATLAB, so this does not require the
% Statistics and Machine Learning Toolbox. 
if tail == 2, up = p/2; else, up = p; end     % required upper-tail probability

t = zeros(size(p));
for k = 1:numel(p)
    lo = 0; hi = 1;
    while local_upper(hi, df) > up(k) && hi < 1e6
        hi = hi * 2;                          % bracket the root
    end
    for it = 1:200
        mid = 0.5*(lo + hi);
        if local_upper(mid, df) > up(k), lo = mid; else, hi = mid; end
    end
    t(k) = 0.5*(lo + hi);
end
end

function u = local_upper(t, df)
% P(T > t) for t >= 0.
u = 0.5 * betainc(df ./ (df + t.^2), df/2, 0.5);
end