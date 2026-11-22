function fmri2 = fmri_downsample(fmri, factor)
% FMRI_DOWNSAMPLE  Spatially downsamples vectorized fMRI data by integer factor.
%
% Retains every Nth voxel along each spatial dimension (x, y, z), reducing
% data size for computationally expensive operations. The output is a
% sub-sampled vectorized brain (fewer voxels x T). Inverse: fmri_upsample.
%
% Usage:
%   fmri2 = fmri_downsample(fmri)
%   fmri2 = fmri_downsample(fmri, factor)
%
% Inputs:
%   FMRI    - Vectorized fMRI data (228453 x T).
%   FACTOR  - Downsampling factor (integer). Every FACTOR-th voxel is kept
%             in each dimension. Default: 2 (keeps 1/8 of voxels).
%
% Outputs:
%   FMRI2   - Downsampled vectorized data. The number of rows depends on
%             FACTOR and on the brain mask: factor 2 keeps 28542 voxels,
%             factor 3 keeps 8468.
%
% Examples:
%   small = fmri_downsample(data);         % factor 2
%   small = fmri_downsample(data, 3);      % factor 3
%   orig  = fmri_upsample(small);          % restore full resolution
%
% See also: fmri_upsample, fmri_vol2vect

if nargin < 2 || isempty(factor), factor = 2; end

if ~isscalar(factor) || factor < 1 || mod(factor,1) ~= 0
    error('fmri_downsample:badFactor', ...
          'FACTOR must be a positive whole number; got %g.', factor);
end

if size(fmri,1) ~= 228453
    error('fmri_downsample:badSize', ...
          ['FMRI must have 228453 rows (vectorized brain); got %d.\n' ...
           'Use fmri_vol2vect first if you have a volume.'], size(fmri,1));
end

mask = zeros(91,109,91);
mask(1:factor:end, 1:factor:end, 1:factor:end) = 1;
maskv = fmri_vol2vect(mask);
fmri2 = fmri(maskv > 0, :);