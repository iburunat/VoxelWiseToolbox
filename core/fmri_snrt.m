function SNR = fmri_snrt(v)
% FMRI_SNRT  Temporal signal-to-noise ratio (tSNR) for each brain voxel.
%
% Computes the temporal SNR for each voxel as the ratio of the mean signal
% across time to its temporal standard deviation:
%
%   tSNR = mean(S_v) / std(S_v)
%
% A high tSNR voxelwise map indicates stable signal; low values indicate
% noisy or artefact-prone voxels. Standard quality metric for fMRI data.
%
% Usage:
%   SNR = fmri_snrt(v)
%
% Inputs:
%   V    - fMRI data, vectorized (228453 x T) or volume (91 x 109 x 91 x T).
%
% Outputs:
%   SNR  - Temporal SNR map (228453 x 1). Visualise with fmri_showslices.
%
% Examples:
%   tsnr = fmri_snrt(data);
%   fmri_showslices(tsnr, 1, 2, [0 100])
%
% See also: fmri_snri, fmri_cnr

if ndims(v) > 2, v = fmri_vol2vect(v); end

% Compute temporal SNR for each voxel as its mean divided by its standard
% deviation across time, ignoring NaN values. Voxels with zero temporal
% variance return Inf or NaN, indicating that tSNR is undefined.
SNR = mean(v, 2, 'omitnan') ./ std(v, 0, 2, 'omitnan'); % dependency-free
% For SNR in decibels instead of a raw ratio:
%   SNR = 20 * log10(mean(v, 2, 'omitnan') ./ std(v, 0, 2, 'omitnan'));
end