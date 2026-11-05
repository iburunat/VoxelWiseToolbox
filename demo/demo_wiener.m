% DEMO_WIENER  Wiener deconvolution of a simulated BOLD signal
%
% Builds a known neural signal, convolves it with the canonical HRF to make a
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

fmritoolbox_setup;

%% =========================================================================
%  PART 1: the basic call
%  =========================================================================

%% --- Parameters and a known neural signal --------------------------------
TR  = 2;          % repetition time (seconds)
T   = 200;        % number of timepoints
t   = 0:TR:30;    % time vector for the HRF

% Brief events and one sustained block, so the demo covers both the easy case
% (a block, whose low frequencies survive the HRF) and the hard one (brief
% events, whose high frequencies the HRF attenuates most).
neural_true          = zeros(T, 1);
neural_true(20:22)   = 1;    % brief event 1
neural_true(60:62)   = 1;    % brief event 2
neural_true(100:110) = 1;    % sustained block
neural_true(150:152) = 1;    % brief event 3

%% --- Make the synthetic BOLD signal --------------------------------------
hrf  = fmri_doublegamma(t)';           % canonical HRF at TR = 2 s
bold = conv(neural_true, hrf);
bold = bold(1:T);                      % causal convolution, trimmed to T
rng(5);                                % reproducible
noise_sd = 0.3;
bold = bold + noise_sd * randn(T, 1);

%% --- Recover the neural signal -------------------------------------------
% Three arguments: the measured time series, the HRF it was convolved with, and
% a REGULARISATION value. The value used here is a starting point of the same
% order as the noise level - Part 2 shows why that is only a starting point.
reg        = 0.3;
neural_est = fmri_wiener(bold, hrf, reg);

% The raw BOLD correlation is the baseline that makes the result meaningful:
% deconvolution is not automatically an improvement over doing nothing.
r_est  = fmri_corrmat(neural_est(:), neural_true);
r_bold = fmri_corrmat(bold, neural_true);

fprintf('\n--- Recovery at regularisation = %g ---\n', reg);
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
%  PART 2 (optional): choosing the regularisation
%  =========================================================================
% Everything above is the usage. What follows explains the one parameter that
% has to be chosen, and the trap in choosing it by correlation alone.
%
% REG IS A REGULARISATION, not the noise level. It controls how much the
% deconvolution trusts the data at frequencies where the HRF has little power.
% Writing the Wiener filter in the frequency domain,
%
%     W(f) = conj(H(f)) / ( |H(f)|^2 + reg )
%
% shows what the two limits mean:
%
%   reg -> 0    W -> 1/H, the exact inverse. It undoes the HRF perfectly on
%               noiseless data and amplifies noise without limit on real data.
%   reg -> inf  W -> conj(H)/reg, a scaled MATCHED FILTER. This correlates the
%               data with the HRF rather than inverting it: the haemodynamic
%               lag is corrected and noise is suppressed, but the temporal
%               sharpening that deconvolution is for has been given up.
%
% Three values are enough to see both ends and the middle. The low one is
% deliberately far too small: close to the exact inverse, noise at the
% frequencies where the HRF has no power is amplified without restraint, which
% is the failure the baseline comparison below exists to catch.
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

fprintf(['\nLower regularisation gives a sharper but noisier recovery; higher ' ...
    'gives a\nsmoother one. Highest r here: reg = %g (r = %.3f).\n'], ...
    reg_levels(ib), best_r);

fprintf(['\nCAUTION: r alone is a poor criterion. As reg grows the filter\n' ...
    'degenerates to a matched filter, conj(H)/reg - lag-corrected and smooth,\n' ...
    'but no longer sharpening anything. It scores well because r rewards the\n' ...
    'slow block and barely penalises smearing the brief events. Judge the\n' ...
    'panels by whether the brief events are RESOLVED: the useful setting is\n' ...
    'the sharpest one that is not yet ringing.\n']);

% Reported either way. Whether any particular setting falls below the baseline
% depends on the noise draw.
if n_worse > 0
    fprintf(['\n%d of the %d settings score BELOW the undeconvolved BOLD ' ...
        '(r = %.3f).\n'], n_worse, numel(r_rec), r_bold);
else
    fprintf(['\nAll %d settings beat the undeconvolved BOLD (r = %.3f) on this ' ...
        'noise draw,\nbut that is not something to count on.\n'], ...
        numel(r_rec), r_bold);
end
fprintf(['Deconvolution is not free: where the HRF has little power, an\n' ...
    'under-regularised inverse amplifies noise, and the amplified noise can ' ...
    'cost\nmore than the haemodynamic delay it removes.\n']);

fprintf(['\nFinally, reg is NOT the noise SD (%g here). It is a noise-to-SIGNAL ' ...
    'POWER\nratio, so it depends on the signal amplitude as well as the noise. ' ...
    'Treat the\nnoise level as an order-of-magnitude starting point and sweep ' ...
    'from there - do\nnot set reg = noise_sd.\n'], noise_sd);
