function SNR = fmri_snri(v)
% FMRI_SNRI  Image-domain signal-to-noise ratio (SNR-i) for each fMRI scan.
%
% Computes the image SNR for each time point as the ratio of the mean signal
% across all brain voxels to its standard deviation:
%
%  SNR-i = mean(S_t) / std(S_t)
%
% A high SNR-i indicates that signal variation across voxels within a
% scan is small relative to the mean, suggesting low inter-voxel noise.
%
% Usage:
%   SNR = fmri_snri(v)
%
% Inputs:
%   V    - fMRI data, vectorized (228453 x T) or volume (91 x 109 x 91 x T).
%
% Outputs:
%   SNR  - Image SNR per time point (T x 1).
%
% Examples:
%   snr = fmri_snri(data);
%   plot(snr); xlabel('Scan'); ylabel('SNR-i')
%
% See also: fmri_snrt, fmri_cnr

if ndims(v) > 2, v = fmri_vol2vect(v); end

% Compute image SNR for each scan as the mean divided by the standard
% deviation across brain voxels, ignoring NaN values. Return one value per
% scan as a column vector.
SNR = (mean(v, 1, 'omitnan') ./ std(v, 0, 1, 'omitnan'))';
% For SNR in decibels instead of a raw ratio:
%   SNR = 20 * log10(mean(v, 1, 'omitnan') ./ std(v, 0, 1, 'omitnan'))';

end