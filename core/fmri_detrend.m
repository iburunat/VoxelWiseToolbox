function newdata = fmri_detrend(data, no_of_anchor_points)
% FMRI_DETREND  Removes low-frequency drift from fMRI data using spline fitting.
%
% Fits a cubic spline through a set of equally-spaced anchor points along the
% temporal dimension and subtracts it from the data. This removes slow drifts
% (scanner drift, respiratory and movement artefacts) while preserving
% higher-frequency BOLD signal. Operates voxelwise.
%
% Usage:
%   newdata = fmri_detrend(data)
%   newdata = fmri_detrend(data, no_of_anchor_points)
%
% Inputs:
%   DATA                - fMRI time series, in any accepted layout:
%                           228453 x T          canonical (voxels x time)
%                           91 x 109 x 91 x T   volume
%   NO_OF_ANCHOR_POINTS - Number of spline knots. More knots removes slower
%                         drift more thoroughly, but risks attenuating genuine
%                         slow BOLD responses. Default: 6.
%
% Outputs:
%   NEWDATA - Detrended data, in the same layout as DATA. Each voxel time
%             series is also mean-centred.
%
% Examples:
%   data = fmri_detrend(data);          % default 6 knots
%   data = fmri_detrend(data, 4);       % gentler detrending
%   data = fmri_detrend(data, 10);      % more aggressive
%
% Notes:
%   Anchor values are calculated by averaging the scans closest to each
%   knot. The first and last knots have scans on only one side, so their
%   averages are based on fewer scans than those of the interior knots
%   (for T = 150 and 6 knots: 15, 30, 30, 30, 30, 15). Consequently, the
%   estimated drift may be less reliable at the beginning and end of the
%   run. This edge effect is common to drift-removal methods and is
%   preserved here for consistency with earlier toolbox versions.
% 
%   For high-pass filtering in the frequency domain, see fmri_bandpassfilter.
%
% See also: fmri_tempsmooth, fmri_bandpassfilter, fmri_zscorevoldata

if ~isfloat(data)
    % Integer input would round and saturate every arithmetic result silently.
    data = double(data);
end

if nargin < 2 || isempty(no_of_anchor_points)
    no_of_anchor_points = 6;
end

[data, fmt] = fmri_asvoxtime(data, 'fmri_detrend');

[~, N] = size(data);
K      = no_of_anchor_points;

if K < 2
    error('fmri_detrend:tooFewKnots', ...
          'NO_OF_ANCHOR_POINTS must be at least 2 (received %d).', K);
end
if K > N
    error('fmri_detrend:tooManyKnots', ...
          ['NO_OF_ANCHOR_POINTS (%d) exceeds the number of scans (%d). ' ...
           'Use fewer knots.'], K, N);
end

% ---- knot positions, and which scans belong to each knot ---------------
xx  = linspace(1, N, K);                    % knot locations (in scans)
xxx = 1:N;
ind = interp1(xx, 1:K, xxx, 'nearest');     % nearest knot for each scan

% ---- anchor values: mean of the scans nearest each knot ----------------
% Calculate all anchor values at once using matrix multiplication,
% avoiding the need to loop over individual voxels.

A = zeros(K, N);
for k = 1:K
    m = (ind == k);
    A(k, m) = 1 / nnz(m);
end
y = data * A.';                             % V x K anchor values

% ---- spline through the anchors, then subtract -------------------------
% spline() accepts a matrix whose rows are independent datasets, so every
% voxel is fitted in a single call.
yy      = spline(xx, y, xxx);               % V x N fitted drift
df      = data - yy;
newdata = df - mean(df, 2);                 % mean-centre each voxel

newdata = fmri_restoreformat(newdata, fmt);
end