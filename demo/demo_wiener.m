%% DEMO_WIENER  Wiener deconvolution of a simulated BOLD signal
%
% Builds a known neural signal, convolves it with the HRF to make a
% synthetic BOLD response, then recovers the neural signal with fmri_wiener and
% compares the result against the ground truth.
%
% The demo is in two parts:
%
%   PART 1  The call itself: one line, and a before/after figure. This is all
%           you need to use the function.
%
%   PART 2  (optional) How to choose the regularisation parameter, and why the
%           correlation with the truth is a poor criterion for choosing it.
%           Skip it on a first read; come back when a recovery looks wrong.
%
% Functions demonstrated:
%   fmri_wiener, fmri_doublegamma, fmri_corrmat
%
% See also: fmri_wiener, fmri_doublegamma, fmri_xcorr

clear; close all;
if exist('fmritoolbox_setup', 'file')
    fmritoolbox_setup;
else
    error('Please run fmritoolbox_setup.m from the toolbox root first.');
end
fprintf('=== VoxelWise Toolbox Wiener deconvolution demo ===\n\n');

%% =========================================================================
%  PART 1: Basic Wiener deconvolution
%  =========================================================================

%% --- Parameters and a known neural signal --------------------------------
TR  = 2;          % repetition time (seconds)
T   = 200;        % number of timepoints
t   = 0:TR:30;    % time vector for the HRF

% Include isolated brief events, a closely spaced pair and a sustained block.
% The HRF preserves the slower block and attenuates the brief events; the pair
% at scans 60 and 68 is close enough to merge if the recovery is over-smoothed.
neural_true          = zeros(T, 1);
neural_true(20:22)   = 1;    % brief event 1
neural_true(60:62)   = 1;    % brief event 2
neural_true(100:110) = 1;    % sustained block
neural_true(150:152) = 1;    % brief event 3

%% --- Make the synthetic BOLD signal --------------------------------------
hrf  = fmri_doublegamma(t)';           % HRF at TR = 2 s
bold = conv(neural_true, hrf);
bold = bold(1:T);                      % causal convolution, trimmed to T
rng(5);                                % reproducible
noise_sd = 0.3;
bold = bold + noise_sd * randn(T, 1);

%% --- Recover the neural signal -------------------------------------------
% Supply the measured BOLD signal, the HRF and a regularisation value. The
% value used here is illustrative; Part 2 shows how changing it affects recovery.
reg        = 0.3;
neural_est = fmri_wiener(bold, hrf, reg);

% The raw BOLD correlation is the baseline that makes the result meaningful:
% deconvolution is not automatically an improvement over doing nothing.
r_est  = fmri_corrmat(neural_est(:), neural_true);
r_bold = fmri_corrmat(bold, neural_true);

fprintf('--- Recovery at regularisation = %g ---\n', reg);
fprintf('  r(recovered, true neural) : %.3f\n', r_est);
fprintf('  r(raw BOLD,  true neural) : %.3f   <- the baseline to beat\n\n', r_bold);

%% --- Before and after ----------------------------------------------------
figure('Name', 'Wiener deconvolution', 'Position', [80 80 900 500]);

subplot(2, 1, 1);
plot(neural_true, 'r', 'LineWidth', 1.5); hold on;
plot(bold ./ max(abs(bold)), 'k');     % normalised, for visual comparison
hold off;
title('Before: neural (red) vs BOLD (black) — note the haemodynamic lag');
legend('Neural', 'BOLD (normalised)', 'Location', 'best');
xlabel('Scan'); ylabel('Amplitude'); axis tight;

subplot(2, 1, 2);
plot(neural_true, 'r', 'LineWidth', 1.5); hold on;
plot(neural_est, 'b');
hold off;
title(sprintf('After: recovered neural signal (reg = %g, r = %.3f)', reg, r_est));
legend('Ground truth', 'Recovered', 'Location', 'best');
xlabel('Scan'); ylabel('Amplitude'); axis tight;

%% =========================================================================
%  Part 2: effect of regularisation
%  =========================================================================
% REG controls how far the deconvolution trusts the data at frequencies where
% the HRF has little power. fmri_wiener computes
%
%     W(f) = conj(H) |S|^2 / ( |H|^2 |S|^2 + |N|^2 ),   |N| = reg * mean|S|
%
% so REG scales the assumed noise magnitude against the observed signal
% amplitude - it is not the noise SD, and not an absolute power. Small REG
% approaches the exact inverse 1/H: sharper, but it amplifies noise where the
% HRF has no power. Large REG suppresses that noise but smooths and attenuates
% the estimate. Start at the order of the noise level and sweep; the three
% values below span both ends and the middle.
reg_levels = [0.001 0.3 10];

figure('Name', 'Part 2: effect of the regularisation', 'Position', [100 60 900 650]);

r_rec = zeros(size(reg_levels));
for k = 1:length(reg_levels)
    est      = fmri_wiener(bold, hrf, reg_levels(k));
    r_rec(k) = fmri_corrmat(est(:), neural_true);

    subplot(length(reg_levels), 1, k);
    plot(est, 'b'); hold on;
    plot(neural_true, 'r--', 'LineWidth', 1.5);
    hold off;
    title(sprintf('reg = %g, r = %.3f', reg_levels(k), r_rec(k)));
    legend('Estimated', 'Ground truth', 'Location', 'best');
    xlabel('Scan'); ylabel('Amplitude'); axis tight;
end

fprintf('--- Part 2: sweeping the regularisation ---\n');
fprintf('  regularisation   r with true neural signal\n');
for k = 1:length(reg_levels)
    fprintf('  %10.3f       %.3f\n', reg_levels(k), r_rec(k));
end
fprintf('  %10s       %.3f  (BOLD itself, no deconvolution)\n', '-', r_bold);

[best_r, ib] = max(r_rec);
n_worse      = nnz(r_rec < r_bold);

fprintf('\nHighest correlation: reg = %g (r = %.3f).\n', reg_levels(ib), best_r);
if n_worse > 0
    fprintf('%d/%d settings scored below raw BOLD.\n', n_worse, numel(r_rec));
end
fprintf(['\nCorrelation is an unreliable selection criterion because it is ' ...
    'scale-\ninvariant. It cannot see that reg = 10 recovers the events at a ' ...
    'small\nfraction of their true amplitude. Compare the panels, not the ' ...
    'r values.\n']);

fprintf('\n=== Wiener deconvolution demo complete ===\n');