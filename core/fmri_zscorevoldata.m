function c = fmri_zscorevoldata(d)
% FMRI_ZSCOREVOLDATA  Voxelwise z-scoring of fMRI time series.
%
% Standardises each voxel time series independently to zero mean and unit
% standard deviation. Constant voxels have no temporal variation and are set
% to zero rather than NaN, making the output suitable for subsequent GLM and
% correlation analyses.
% 
% Usage:
%   c = fmri_zscorevoldata(d)
%
% Inputs:
%   D  - fMRI time series, in any accepted layout:
%          228453 x T          canonical (voxels x time)
%          T x 228453          transposed
%          91 x 109 x 91 x T   volume
%
% Outputs:
%   C  - Z-scored data, in the same layout as D. Each voxel series has
%        mean = 0 and std = 1. Constant voxels (zero variance) are set to zero.
%
% Examples:
%   data_z = fmri_zscorevoldata(data);
%
% Notes:
%   Typically applied after fmri_detrend and before correlation analyses
%   to remove voxel-level amplitude differences.
%
% See also: fmri_detrend, fmri_corregressor

% Z-score each voxel time series to zero mean and unit standard deviation.
% Dividing by the vector norm would instead produce unit-norm data, differing
% from z-scoring by a factor of sqrt(T-1).
if ~isfloat(d)
    % Integer input would round and saturate every arithmetic result silently.
    d = double(d);
end
[d, fmt] = fmri_asvoxtime(d, 'fmri_zscorevoldata');

if size(d, 2) == 1
    warning('fmri_zscorevoldata:singleTimePoint', ...
        ['D has one time point per voxel, so every series has zero variance ' ...
         'and the result\nis all zeros. This function z-scores along TIME, ' ...
         'and is not meant for a single map.']);
end

sd = std(d, 0, 2);                              % temporal std, N-1 normalisation
c  = bsxfun(@rdivide, bsxfun(@minus, d, mean(d, 2)), sd);
c(sd == 0, :) = 0;   % constant voxels contain no temporal variation;
                     % set to zero to avoid NaNs in downstream analyses

c = fmri_restoreformat(c, fmt);