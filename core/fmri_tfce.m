function tfce = fmri_tfce(data, E, H, N)
% FMRI_TFCE  Threshold-free cluster enhancement (TFCE) of a statistical map.
%
% Computes a TFCE score at each voxel by combining signal height with the
% spatial extent of the cluster containing it across a range of thresholds.
% This avoids selecting a single cluster-forming threshold. High scores
% indicate strong values supported by spatially extensive signal.
%
% The TFCE statistic is defined as:
%
%   TFCE(v) = integral[ e(h)^E * h^H dh ]
%
% where e(h) is the cluster extent at threshold h, E weights cluster extent
% (default 0.5), and H weights peak height (default 2).
%
% Usage:
%   tfce = fmri_tfce(data)
%   tfce = fmri_tfce(data, E, H, N)
%
% Inputs:
%   DATA  - Statistical map, vectorized (228453 x 1). Must be non-negative;
%           run separately for positive and negative tails if needed.
%   E     - Extent exponent. Default: 0.5 (Smith & Nichols recommendation).
%   H     - Height exponent. Default: 2   (Smith & Nichols recommendation).
%   N     - Number of threshold bins for numerical integration. Default: 
%           50. More bins = more accurate but slower.
%
% Outputs:
%   TFCE  - TFCE map, vectorized (228453 x 1)
%
% Examples:
%   % Positive tail
%   tfce_pos = fmri_tfce(max(zmap, 0));
%   % Negative tail
%   tfce_neg = fmri_tfce(max(-zmap, 0));
%   % Visualize
%   fmri_showslices(tfce_pos, 1, 2, [0 max(tfce_pos)])
%
% Implementation notes (relative to Smith & Nichols, 2009):
%   - Form, exponents and lower limit follow Eq. 1 with h0 = 0 and the
%     recommended E = 0.5, H = 2.
%   - The integral is evaluated by the midpoint rule over N threshold bins.
%   - Clusters are formed with 18-connectivity, matching the rest of this
%     toolbox (fmri_findclusters, fmri_cleanclusters, fmri_csdist). FSL's TFCE
%     uses 26-connectivity, so TFCE scores here will not match FSL voxel for
%     voxel. This does not affect validity: the connectivity is part of the
%     statistic's definition and only needs to be consistent between the
%     observed map and any permutation null built from it.
%   - The raw TFCE map is not a p-value. To obtain inference, build a null
%     distribution of the maximum TFCE score over sign-flips or phase-scrambled
%     regressors and threshold against it.
%
% References:
%   Smith, S.M. & Nichols, T.E. (2009). Threshold-free cluster enhancement:
%   addressing problems of smoothing, threshold dependence and localisation
%   in cluster inference. NeuroImage, 44(1), 83-98.
%
% See also: fmri_cleanclusters, fmri_csthreshold, fmri_findclusters

if nargin < 4 || isempty(N), N = 50;  end
if nargin < 3 || isempty(H), H = 2;   end
if nargin < 2 || isempty(E), E = 0.5; end

if size(data, 2) > 1
    error('fmri_tfce:badInput', ...
          'DATA must be a column vector (228453 x 1); got %d columns.', ...
          size(data, 2));
end
if any(~isfinite(data))
    error('fmri_tfce:nonFinite', ...
          ['DATA contains NaN or Inf.\n' ...
           'Remove or zero non-finite voxels before calling fmri_tfce.']);
end
if any(data < 0)
    error('fmri_tfce:negative', ...
          ['DATA has negative values, which TFCE does not integrate.\n' ...
           'Run each tail separately: fmri_tfce(max(z,0)) and ' ...
           'fmri_tfce(max(-z,0)).']);
end

% --- build threshold bins ---------------------------------------------
hmin  = 0;
hmax  = max(data);
if hmax == 0
    tfce = zeros(size(data));
    return
end
hlim  = linspace(hmin, hmax, N + 1);
dh    = hlim(2) - hlim(1);
h     = hlim(2:end) - dh/2;   % bin centres (1 x N)

% --- THRESHOLD STACK AND TFCE INTEGRATION -----------------------------
% At each threshold, assign every suprathreshold voxel the size of its
% connected cluster. A voxel contributes at every threshold up to its value.
%
% fmri_bin is not used because it assigns each voxel to a single value bin,
% whereas TFCE requires cumulative thresholded maps.
%
% Accumulate the integral one threshold at a time to avoid storing an
% nvox x N extent matrix. This reduces peak memory from about 91 MB to
% 1.8 MB for 228453 voxels and N = 50, without changing the calculation.
nvox   = numel(data);
tfce   = zeros(nvox, 1);
extent = zeros(nvox, 1);
for k = 1:N
    above        = data >= h(k);
    [label, num] = fmri_bwlabel(fmri_vect2vol(double(above)), 18);
    if num == 0
        continue                      % no suprathreshold cluster: term is zero
    end
    labelvect    = fmri_vol2vect(label);
    sizes        = accumarray(labelvect(labelvect > 0), 1);
    nz           = labelvect > 0;
    extent(:)    = 0;
    extent(nz)   = sizes(labelvect(nz));
    tfce         = tfce + (extent .^ E) * (h(k) ^ H) * dh;
end