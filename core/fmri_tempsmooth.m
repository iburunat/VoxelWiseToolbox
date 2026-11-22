function newdata = fmri_tempsmooth(data, sigma, TR)
% FMRI_TEMPSMOOTH  Temporal Gaussian smoothing of fMRI time series.
%
% Smooths each voxel time series by convolving it with a Gaussian kernel,
% reducing rapid temporal fluctuations while retaining slower signal changes.
%
% Usage:
%   newdata = fmri_tempsmooth(data)
%   newdata = fmri_tempsmooth(data, sigma)
%   newdata = fmri_tempsmooth(data, sigma, TR)
%
% Inputs:
%   DATA  - fMRI time series, in any accepted layout:
%             228453 x T          canonical (voxels x time)
%             91 x 109 x 91 x T   volume
%   SIGMA - Standard deviation of the Gaussian kernel, in SECONDS.
%           Default: 4 s. The corresponding full width at half maximum is
%           FWHM = 2.355 * SIGMA, so sigma = 4 s gives FWHM = 9.4 s.
%   TR    - Repetition time in seconds. Default: 2.
%
% Outputs:
%   NEWDATA - Temporally smoothed data, in the same layout as DATA.
%
% Examples:
%   data = fmri_tempsmooth(data);              % sigma = 4 s, TR = 2 s
%   data = fmri_tempsmooth(data, 4, 2);        % same, stated explicitly
%   data = fmri_tempsmooth(data, 3, 0.72);     % sigma 3 s, multiband TR
%
%   % To specify smoothing by FWHM instead of sigma:
%   fwhm = 6;                                  % seconds
%   data = fmri_tempsmooth(data, fwhm / 2.355, TR);
%
% Notes:
%   SIGMA is specified in seconds, and TR determines the spacing of the
%   Gaussian kernel samples. This gives the smoothing width a consistent
%   physical duration across different sampling rates.
%
%   The kernel is normalised to sum to one, preserving constant signal levels
%   away from the run boundaries.
%
%   The kernel extends to approximately +/- 4 SIGMA. At the beginning and end
%   of the run, part of the kernel falls outside the available data, which may
%   attenuate values within approximately 4 SIGMA of each boundary.
% 
%   For frequency-domain bandpass filtering use fmri_bandpassfilter instead.
%
% See also: fmri_bandpassfilter, fmri_detrend

if nargin < 2 || isempty(sigma), sigma = 4; end   % seconds
if nargin < 3 || isempty(TR),    TR    = 2; end   % seconds

if sigma <= 0
    error('fmri_tempsmooth:badSigma', 'SIGMA must be positive (received %g).', sigma);
end
if TR <= 0
    error('fmri_tempsmooth:badTR', 'TR must be positive (received %g).', TR);
end

[data, fmt] = fmri_asvoxtime(data, 'fmri_tempsmooth');
N = size(data, 2);

% ---- build the kernel --------------------------------------------------
% Sample the Gaussian kernel at intervals of TR and truncate it at +/- 4
% SIGMA, which includes more than 99.99% of its total area.
half        = ceil(4 * sigma / TR);          % half-width, in scans
time_points = (-half:half) * TR;             % tap positions, in seconds
% g           = normpdf(time_points, 0, sigma); % Statistics Toolbox
g           = exp(-0.5 * (time_points ./ sigma).^2) ./ (sigma * sqrt(2*pi));
g           = g / sum(g);                    % unit gain: preserve amplitude
K           = numel(g);

if K > N
    warning('fmri_tempsmooth:kernelLongerThanRun', ...
        ['The kernel spans %d scans but the run is only %d scans long. ' ...
         'Smoothing will be dominated by edge effects. Consider a smaller ' ...
         'SIGMA (currently %g s at TR = %g s).'], K, N, sigma, TR);
end

% ---- convolve every voxel at once --------------------------------------
full    = conv2(data, g, 'full');            % V x (N + K - 1)
lead    = (K - 1) / 2;                       % K is odd by construction
newdata = full(:, lead + (1:N));

newdata = fmri_restoreformat(newdata, fmt);
end