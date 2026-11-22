function data_filt = fmri_bandpassfilter(data, fs, f_low, f_high)
% FMRI_BANDPASSFILTER  Non-causal FFT-based bandpass filter for fMRI time series.
%
% Applies a sharp (brick-wall) bandpass filter in the frequency domain by
% zeroing all FFT coefficients outside the specified band. Because the filter
% is applied in the frequency domain and the result is the real part of the
% inverse FFT, it is non-causal (zero phase shift) and free of the order-
% dependent edge effects of causal digital filters. Suitable for resting-state
% fMRI (for example a 0.01-0.1 Hz band) and for task-based filtering.
%
% Usage:
%   data_filt = fmri_bandpassfilter(data, fs, f_low, f_high)
%
% Inputs:
%   DATA   - fMRI time series, in any accepted layout:
%              228453 x T          canonical (voxels x time)
%              91 x 109 x 91 x T   volume
%            A single time series (1 x T) is also accepted, which is useful for
%            filtering a stimulus regressor with the same filter as the data.
%   FS     - Sampling frequency in Hz (= 1 / TR). For TR = 2 s, fs = 0.5.
%   F_LOW  - Low cutoff in Hz; frequencies below this are removed. E.g. 0.01.
%            Set to 0 for a low-pass filter only.
%   F_HIGH - High cutoff in Hz; frequencies above this are removed. E.g. 0.10.
%            Set to Inf for a high-pass filter only.
%
% Outputs:
%   DATA_FILT - Filtered data, in the same layout as DATA.
%
% Examples:
%   % Resting-state bandpass (TR = 2 s)
%   data = fmri_bandpassfilter(data, 0.5, 0.01, 0.10);
%
%   % High-pass only: remove drift below 0.008 Hz (TR = 1.5 s)
%   data = fmri_bandpassfilter(data, 1/1.5, 0.008, Inf);
%
%   % Apply the same filter to a stimulus regressor
%   regr = fmri_bandpassfilter(regr(:).', 0.5, 0.01, 0.10);
%
% Notes:
%   Any regressor to be correlated with filtered data should be filtered with
%   the same band, so that both share the same frequency support.
%
% See also: fmri_detrend, fmri_tempsmooth, fmri_correctmovement

if nargin < 4
    error('fmri_bandpassfilter:notEnoughInputs', ...
          'Usage: fmri_bandpassfilter(data, fs, f_low, f_high)');
end
if fs <= 0
    error('fmri_bandpassfilter:badFs', 'FS must be positive (received %g).', fs);
end
if f_low >= f_high
    error('fmri_bandpassfilter:badBand', ...
          'F_LOW (%g) must be below F_HIGH (%g).', f_low, f_high);
end
if f_high ~= Inf && f_high > fs/2
    warning('fmri_bandpassfilter:aboveNyquist', ...
        ['F_HIGH (%g Hz) exceeds the Nyquist frequency (%g Hz). ' ...
         'No frequencies above Nyquist are present, so the high cutoff has ' ...
         'no effect.'], f_high, fs/2);
end

% A bare time series (1 x T or T x 1) is filtered directly; brain data goes
% through the canonical-layout helper.
isvector_input = isvector(data);
if isvector_input
    orig  = size(data);
    data  = double(data(:).');                 % 1 x T
    fmt   = [];
else
    [data, fmt] = fmri_asvoxtime(data, 'fmri_bandpassfilter');
end

N = size(data, 2);

% ---- frequency mask ----------------------------------------------------
ff  = (0:(N-1)) / N;
f   = fs * (ff - round(ff));                   % Hz, in (-fs/2, fs/2]
kill = (abs(f) < f_low) | (abs(f) > f_high);   % coefficients to zero

% ---- filter every voxel at once ---------------------------------------
Z          = fft(data.');                      % T x V
Z(kill, :) = 0;
data_filt  = real(ifft(Z)).';                  % V x T

if isvector_input
    data_filt = reshape(data_filt, orig);
else
    data_filt = fmri_restoreformat(data_filt, fmt);
end
end