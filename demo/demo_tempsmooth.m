% DEMO_TEMPSMOOTH  Temporal Gaussian smoothing of fMRI time series
%
% Demonstrates fmri_tempsmooth by applying temporal smoothing to a simulated
% fMRI time series with different sigma values and comparing the effect on
% signal quality and frequency content.
%
% Functions demonstrated:
%   fmri_tempsmooth, fmri_doublegamma, fmri_corrmat
%
% NOTE ON UNITS: fmri_tempsmooth's SIGMA is in SECONDS, not scans. Always pass
% TR explicitly so the conversion is unambiguous.
%
% See also: fmri_tempsmooth, fmri_bandpassfilter, fmri_detrend

fmritoolbox_setup;

%% --- Simulate a noisy fMRI time series ------------------------------------
TR  = 2;
T   = 200;
t   = 0:TR:30;

% Neural signal: block design convolved with HRF
stim       = zeros(T, 1);
stim(20:40)  = 1;
stim(80:100) = 1;
stim(140:160)= 1;
hrf        = fmri_doublegamma(t)';
bold       = conv(stim, hrf);
bold       = bold(1:T);
bold       = (bold - mean(bold)) ./ std(bold);

% Three synthetic voxels demonstrate the usual voxels-by-time input layout; the
% figures and the table below show the first voxel.
%
% A 3 x 200 matrix is an ambiguous layout, so the toolbox warns once that it is
% assuming voxels x time. That is correct here, so the notice is suppressed and
% the warning state restored at the end.
warn_state = warning('off', 'fmri:ambiguousOrientation');

rng(3);                       % reproducible
noise_level = 2;
data        = repmat(bold', [3 1]) + noise_level * randn(3, T);

%% --- Apply temporal smoothing with different sigma values -----------------
% SIGMA is in SECONDS - at TR = 2 s these are 1, 2.5, 5 and 15 scans. It sets
% the temporal spread of the Gaussian kernel, not the width of a window with
% hard edges. The largest value is included to make the temporal blurring
% produced by strong smoothing clearly visible.
sigma_values = [2 5 10 30];

figure('Name', 'Temporal smoothing comparison');

subplot(length(sigma_values)+1, 1, 1);
plot(bold, 'k', 'LineWidth', 2); hold on;
plot(data(1,:), 'Color', [0.7 0.7 0.7]);
title('Original: clean signal (black) vs noisy voxel (gray)');
xlabel('Scan'); ylabel('Amplitude'); axis tight;

for k = 1:length(sigma_values)
    smoothed = fmri_tempsmooth(data, sigma_values(k), TR);
    subplot(length(sigma_values)+1, 1, k+1);
    plot(bold, 'k', 'LineWidth', 2); hold on;
    plot(smoothed(1,:), 'b');
    title(sprintf('\\sigma = %g s (%.1f scans), r with clean signal = %.3f', ...
          sigma_values(k), sigma_values(k)/TR, ...
          fmri_corrmat(smoothed(1,:)', bold)));
    xlabel('Scan'); ylabel('Amplitude'); axis tight;
end

%% --- Effect on frequency content ------------------------------------------
% abs(fft(...)) is the MAGNITUDE spectrum; power would be the squared magnitude.
figure('Name', 'Magnitude spectra before and after smoothing');
freq_hz = (0:T/2) / (T * TR);   % Hz

raw_fft      = abs(fft(data(1,:)));
smooth5_fft  = abs(fft(fmri_tempsmooth(data(1,:), 5,  TR)));
smooth10_fft = abs(fft(fmri_tempsmooth(data(1,:), 10, TR)));

plot(freq_hz, raw_fft(1:T/2+1),      'Color', [0.7 0.7 0.7]); hold on;
plot(freq_hz, smooth5_fft(1:T/2+1),  'b');
plot(freq_hz, smooth10_fft(1:T/2+1), 'r');
legend('Raw', 'sigma = 5 s', 'sigma = 10 s');
title('Magnitude spectrum: effect of temporal smoothing');
xlabel('Frequency (Hz)'); ylabel('Magnitude'); axis tight;
fprintf('\n  sigma (s)   r with clean signal\n');

for k = 1:length(sigma_values)
    sm = fmri_tempsmooth(data, sigma_values(k), TR);
    r_values(k) = fmri_corrmat(sm(1,:)', bold);
    fprintf('  %6.1f      %.3f\n', sigma_values(k), r_values(k));
end

fprintf('  %6s      %.3f  (unsmoothed)\n', '-', fmri_corrmat(data(1,:)', bold));

[~, best_idx] = max(r_values);

fprintf(['\nAmong the values tested, agreement with the clean signal is highest ' ...
'at sigma =\n%g s. The largest value blurs the temporal structure and ' ...
'reduces agreement.\nThe useful sigma depends on the temporal scale of ' ...
'the signal and noise.\n'], sigma_values(best_idx));

warning(warn_state);          % restore the ambiguous-orientation notice