function [p_combined, stat] = fmri_combinep(pvals, method)
% FMRI_COMBINEP  Combine p-values across participants using meta-analytic methods.
%
% Takes one p-value map per participant and combines the evidence across
% participants at each voxel using a standard meta-analytic method. This is
% useful when statistical maps were computed separately for each participant
% and the question is whether a spatial location shows a consistent effect
% across the group.
%
% Stouffer's method averages the per-participant z-scores and so has the most
% power when many participants show a consistent moderate effect. Fisher's
% statistic is -2*sum(log(p)), which a single very small p-value can dominate:
% that makes it the more sensitive of the two when the effect is concentrated
% in a few participants, and, for the same reason, the more easily driven by
% one outlier. The median method sacrifices some power for resistance to
% exactly that.
%
% All three methods are ONE-SIDED and assume the input p-values are one-tailed
% and consistently directed. Passing two-tailed p-values discards the sign, so
% a voxel where half the participants show a strong positive effect and half a
% strong negative one combines to a small p-value with no interpretable
% direction. Split by sign before combining if direction matters.
% 
% Usage:
%   p_combined = fmri_combinep(pvals, method)
%   [p_combined, stat] = fmri_combinep(pvals, method)
%
% Inputs:
%   PVALS   - 228453 x N matrix of p-values (one map per participant)
%   METHOD  - combination method (default: 'fisher')
%             'fisher'   : Fisher combined probability (-2*sum(log(p)))
%             'stouffer' : Stouffer z-score method
%             'median'   : Wilkinson's method on the median order statistic,
%                          calibrated against Beta(k, N-k+1). More robust to
%                          one aberrant participant than Fisher or Stouffer.
%
% Outputs:
%   P_COMBINED - 228453 x 1 combined p-value map. Voxels with any non-finite
%                p-value across participants are returned as NaN.
%   STAT       - 228453 x 1 test statistic map (chi2, z, or the median
%                order statistic, according to METHOD)
%
% Examples:
%   p_combined = fmri_combinep(pvals)
%   [p, stat]  = fmri_combinep(pvals, 'stouffer')
%
% References:
%   Fisher (1932). Statistical Methods for Research Workers.
%   Stouffer et al. (1949). The American Soldier.
%   Wilkinson, B. (1951). A statistical consideration in psychological
%   research. Psychological Bulletin, 48(2), 156-158.
%
% See also: fmri_fisherz, fmri_fisherz2p, fmri_r2p


if nargin < 2 || isempty(method), method = 'fisher'; end

N = size(pvals, 2);

% MAX and MIN ignore NaN, so a NaN p-value would leave the clamp below as
% 1e-300, i.e. as the strongest possible evidence. Non-finite voxels are
% recorded here and returned as NaN at the end instead.
bad = any(~isfinite(pvals), 2);

% Clamp p-values away from 0 and 1: log(0) is -Inf, and erfcinv saturates at
% the endpoints.
pvals = max(pvals, 1e-300);
pvals = min(pvals, 1 - 1e-15);

switch lower(method)

    case 'fisher'
        stat       = -2 * sum(log(pvals), 2);          % chi2 statistic
        % chi2cdf(x,k) == gammainc(x/2, k/2); gammainc is base MATLAB.
        p_combined = 1 - gammainc(stat/2, N);          % df = 2N, so k/2 = N

    case 'stouffer'
        % z_i = norminv(1-p_i) = sqrt(2)*erfcinv(2*p_i). Taken from p directly
        % rather than from 1-p: for p < 1e-16 that subtraction rounds to exactly
        % 1, erfcinv(2) is -Inf, and the voxel becomes z = Inf, p_combined = 0.
        stat       = sum(sqrt(2)*erfcinv(2*pvals), 2) / sqrt(N);  % z statistic
        p_combined = 0.5 * erfc(stat / sqrt(2));             % one-tailed

    case 'median'
        % Wilkinson's method. The median of the participant p-values cannot be
        % used directly as a combined p-value. It must be adjusted to account for
        % the number of participants. This method uses the Beta distribution to
        % calculate a correctly calibrated combined p-value.

        k          = ceil(N/2);
        sorted_p   = sort(pvals, 2);
        stat       = sorted_p(:, k);                    % median order statistic
        % betacdf(x,a,b) == betainc(x,a,b); betainc is base MATLAB.
        p_combined = betainc(stat, k, N - k + 1);

    otherwise
        error('fmri_combinep:badMethod', ...
            ['METHOD must be ''fisher'', ''stouffer'' or ''median''.\n' ...
             'Got ''%s''.'], method);

end

p_combined(bad) = NaN;
stat(bad)       = NaN;