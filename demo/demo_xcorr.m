%% DEMO_XCORR  Voxelwise lagged cross-correlation with fMRI data
%
% Demonstrates voxelwise cross-correlation between an HRF-convolved regressor
% and simulated fMRI data across temporal lags. Three regions are assigned
% known lags, allowing the recovered peak correlations and lags to be checked.
%
% Steps:
%   1. Generate an HRF-convolved block-design regressor
%   2. Simulate three regions with known temporal lags
%   3. Compute voxelwise cross-correlations across lags
%   4. Extract and validate the peak correlation and lag
%   5. Display the correlation and lag maps
%
% Functions demonstrated:
%   fmri_xcorr, fmri_doublegamma, fmri_regionmask, fmri_effdf, fmri_p2r,
%   fmri_showslices
%
% See also: fmri_xcorr, fmri_corregressor, fmri_doublegamma, fmri_partcorr

clear; close all;
if exist('fmritoolbox_setup', 'file')
    fmritoolbox_setup;
else
    error('Please run fmritoolbox_setup.m from the toolbox root first.');
end
fprintf('=== VoxelWise Toolbox XCORR demo ===\n\n');
%% --- Simulate fMRI data ---------------------------------------------------
T      = 200;                          % number of timepoints
TR     = 2;                            % repetition time (seconds)

% Create a block design stimulus and convolve with HRF
stim          = zeros(T, 1);
stim(20:40)   = 1;
stim(80:100)  = 1;
stim(140:160) = 1;

% Evaluate the HRF over 30 seconds, convolve it with the stimulus and trim the
% result to the original run length.
hrf    = fmri_doublegamma(0:TR:30)';   % double-gamma HRF, 16 samples
regr   = conv(stim, hrf);
regr   = regr(1:T);                    % causal convolution, trimmed to T
regr   = (regr - mean(regr)) ./ std(regr);

% Simulate brain data: 3 clusters with different lags, rest is noise.
rng(11);                               % reproducible

true_lags = [0 2 -2];                  % scans
% Choose three non-overlapping atlas regions for the simulated effects.
[m1, name1] = fmri_regionmask(57, 1);   % hippocampus (L)
[m2, name2] = fmri_regionmask(37, 1);   % inferior frontal gyrus, orbital part (L)
[m3, name3] = fmri_regionmask(67, 1);   % superior occipital gyrus (L)
n_voxels    = numel(m1);

clusters  = {m1 > 0, m2 > 0, m3 > 0};
names     = {name1{1}, name2{1}, name3{1}};

data = randn(n_voxels, T) * 0.3;
for k = 1:3
    % Shift the regressor without wrap-around, filling unavailable time points
    % with zero. Positive lags represent delayed responses.
    idx         = (1:T)' - true_lags(k);
    ok          = idx >= 1 & idx <= T;
    shifted     = zeros(T, 1);
    shifted(ok) = regr(idx(ok));

    data(clusters{k}, :) = data(clusters{k}, :) + ...
                           repmat(shifted', [nnz(clusters{k}), 1]);
end
fprintf('Injected lags:\n');
for k = 1:3
    fprintf('  %-34s %+d scans (%+0.1f s), %d voxels\n', ...
            names{k}, true_lags(k), true_lags(k)*TR, nnz(clusters{k}));
end

%% --- Compute lagged cross-correlation -------------------------------------
maxlag = 5;
fprintf('Computing cross-correlation (maxlag = %d scans)...\n', maxlag);
c = fmri_xcorr(regr, data, maxlag);

%% --- Extract peak lag and peak correlation --------------------------------
% Find the largest absolute correlation across lags, then retain its original
% sign and convert its column index to a signed lag.
[~, peak_lag_idx] = max(abs(c), [], 2);
lin_idx  = sub2ind(size(c), (1:size(c,1))', peak_lag_idx);
peak_r   = c(lin_idx);                    % SIGNED correlation at the peak lag
peak_lag = peak_lag_idx - (maxlag + 1);   % convert index to signed lag

%% --- Validate against the injected lags -----------------------------------
% Estimate the effective sample size from the regressor and a sample of voxel
% time series, then adjust the display threshold for the lags searched. This
% does not correct for whole-brain multiple comparisons.
df_eff  = median(arrayfun(@(v) fmri_effdf(regr, data(v,:)'), randperm(n_voxels, 200)));
n_lags  = 2*maxlag + 1;
p_want  = 0.001 / n_lags;                 % conservative adjustment for the lag search
r_show  = fmri_p2r(p_want, df_eff);
fprintf('\nDisplay threshold: effective N = %.0f, %d lags, p < %.3g per lag\n', ...
        df_eff, n_lags, p_want);
fprintf('  => |r| >= %.3f\n', r_show);

fprintf('\nRecovered peak lags within each simulated region (|r| >= %.2f):\n', ...
        r_show);

for k = 1:3
    sel = clusters{k} & abs(peak_r) >= r_show;

    if any(sel)
        fprintf('  %-34s %+0.1f scans (injected %+d), %d/%d voxels above threshold\n', ...
                names{k}, median(peak_lag(sel)), true_lags(k), ...
                nnz(sel), nnz(clusters{k}));
    else
        fprintf('  %-34s no voxels above threshold\n', names{k});
    end
end

%% --- Display results -------------------------------------------------------
% Display signed peak correlations with symmetric limits and a diverging
% colormap. Only voxels reaching the display threshold are shown.
figure('Name', 'Peak correlation map');
fmri_showslices(peak_r, 1, 2, [-1 1], [], [], 1, [], r_show);
title(sprintf('Peak correlation across lags, signed (|r| >= %.2f)', r_show));

% Zero is a meaningful lag, so hide subthreshold voxels with NaN instead of 
% zero; THRESHOLD = 0 then shows every finite lag. The blue-green-red map keeps
% lag 0 visible against the grey anatomy.
lagmap_cmap = fmri_makecmap([0 0 1; 0 0.75 0.2; 1 0 0], [], 64);

lag_map = peak_lag;
lag_map(abs(peak_r) <= r_show) = NaN;

% Use the 95th percentile of displayed absolute lags for symmetric colour
% limits, reducing the influence of a few extreme noise voxels.
finite_lags = abs(lag_map(isfinite(lag_map)));
if isempty(finite_lags)
    lag_lim = 1;
else
    srt     = sort(finite_lags);
    lag_lim = max(1, srt(ceil(0.95*numel(srt))));
    fprintf('Lag map colour limits: +/-%g scans (95th percentile; max = %g)\n', ...
            lag_lim, max(finite_lags));
end

figure('Name', 'Peak lag map');
fmri_showslices(lag_map, 1, 2, [-lag_lim lag_lim], [], [], 1, lagmap_cmap, 0);
title(sprintf('Peak lag in scans (|r| >= %.2f; GREEN = lag 0, range +/-%g)', ...
      r_show, lag_lim));

fprintf('\nDone. Lags are in scans; multiply by TR = %g s for seconds.\n', TR);
fprintf('Lag map: blue = leading, green = lag 0, red = delayed.\n')

fprintf('\n=== XCORR demo complete ===\n');