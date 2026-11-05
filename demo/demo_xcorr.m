% DEMO_XCORR  Voxelwise lagged cross-correlation with fMRI data
%
% Demonstrates fmri_xcorr by computing the cross-correlation between a
% double-gamma HRF regressor and simulated fMRI data across a range of
% temporal lags. The peak lag map reveals which voxels show haemodynamic
% delays relative to the regressor.
%
% Functions demonstrated:
%   fmri_xcorr, fmri_doublegamma, fmri_regionmask, fmri_effdf, fmri_p2r,
%   fmri_showslices
%
% See also: fmri_xcorr, fmri_corregressor, fmri_doublegamma, fmri_partcorr

fmritoolbox_setup;

%% --- Simulate fMRI data ---------------------------------------------------
T      = 200;                          % number of timepoints
TR     = 2;                            % repetition time (seconds)

% Create a block design stimulus and convolve with HRF
stim          = zeros(T, 1);
stim(20:40)   = 1;
stim(80:100)  = 1;
stim(140:160) = 1;

% fmri_doublegamma takes a TIME VECTOR, not a scalar. Passing TR alone returns
% the HRF at the single time point t = 2 s, and conv(stim, scalar) is then just
% a scalar multiply - leaving the raw box-car with no haemodynamic shape.
hrf    = fmri_doublegamma(0:TR:30)';   % canonical double-gamma HRF, 16 samples
regr   = conv(stim, hrf);
regr   = regr(1:T);                    % causal convolution, trimmed to T
regr   = (regr - mean(regr)) ./ std(regr);

% Simulate brain data: 3 clusters with different lags, rest is noise.
% Voxel count and region names come from the toolbox, not from hardcoded values
% and comments that can drift out of step with the atlas.
rng(11);                               % reproducible
load standard_brain % supplies br, the 91x109x91 binary brain mask
n_voxels = nnz(br);

true_lags = [0 2 -2];                  % scans
[m1, name1] = fmri_regionmask(57, 1);
[m2, name2] = fmri_regionmask(37, 1);
[m3, name3] = fmri_regionmask(67, 1);
clusters  = {m1 > 0, m2 > 0, m3 > 0};
names     = {name1{1}, name2{1}, name3{1}};

data = randn(n_voxels, T) * 0.3;
for k = 1:3
    % Lag k means the response at time t follows the regressor at t-k. Done by
    % indexing rather than circshift: circshift wraps the end of the series
    % round to the start, injecting an edge that the cross-correlation would
    % then report as real structure.
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
% Peak over the ABSOLUTE correlation, then read the signed value back.
% max(c, [], 2) would return the largest POSITIVE correlation, so a strongly
% ANTI-correlated voxel would report a small positive peak and disappear from
% the map - half the possible results discarded silently.
[~, peak_lag_idx] = max(abs(c), [], 2);
lin_idx  = sub2ind(size(c), (1:size(c,1))', peak_lag_idx);
peak_r   = c(lin_idx);                    % SIGNED correlation at the peak lag
peak_lag = peak_lag_idx - (maxlag + 1);   % convert index to signed lag

%% --- Validate against the injected lags -----------------------------------
% The demo checks itself rather than printing what the reader should expect.
%
% THE THRESHOLD IS DERIVED, NOT GUESSED. A round number such as |r| > 0.3 is
% too lenient here for two compounding reasons: the regressor is HRF-smoothed,
% so the effective df is well below T and chance correlations are larger than
% 1/sqrt(T) suggests; and peak_r takes the maximum over 2*maxlag+1 lags, giving
% every voxel that many chances. The threshold is therefore built from the
% effective df, with a Bonferroni-style correction for the lag search.
df_eff  = median(arrayfun(@(v) fmri_effdf(regr, data(v,:)'), randperm(n_voxels, 200)));
n_lags  = 2*maxlag + 1;
p_want  = 0.001 / n_lags;                      % correct for searching over lags
r_show  = fmri_p2r(p_want, df_eff);
fprintf('\nThreshold: effective df = %.0f, %d lags searched, p < %.3g per voxel\n', ...
        df_eff, n_lags, p_want);
fprintf('  => |r| >= %.3f\n', r_show);

fprintf('\nRecovered lags (median over each cluster, |r| >= %.2f voxels only):\n', r_show);
for k = 1:3
    sel = clusters{k} & abs(peak_r) > r_show;
    if any(sel)
        fprintf('  %-34s %+0.1f scans (injected %+d), %d/%d voxels above r\n', ...
                names{k}, median(peak_lag(sel)), true_lags(k), nnz(sel), nnz(clusters{k}));
    else
        fprintf('  %-34s no voxels above r = %.2f\n', names{k}, r_show);
    end
end

%% --- Display results -------------------------------------------------------
% Both maps pass an explicit THRESHOLD with CLIMITS(1) strictly below it.
% Signed map, so symmetric limits and the default diverging colormap: red for
% positive correlation, blue for negative, grey for near zero.
figure('Name', 'Peak correlation map');
fmri_showslices(peak_r, 1, 2, [-1 1], [], [], 1, [], r_show);
title(sprintf('Peak correlation across lags, signed (|r| >= %.2f)', r_show));

% THE LAG MAP NEEDS NaN MASKING, NOT THE ZEROING IDIOM.
%
% The usual pattern - map .* (peak_r > r_show) - fails here, because ZERO IS A
% REAL LAG. A voxel with no haemodynamic delay is exactly as meaningful as one
% at +2, so zero cannot also stand for "not significant": the two become
% indistinguishable, and with a positive THRESHOLD the lag-0 cluster vanishes
% from the figure altogether.
%
% Setting the non-significant voxels to NaN separates the two meanings, and
% THRESHOLD = 0 selects the isfinite rule: every finite voxel is drawn, zero
% included, and the NaNs are left as plain anatomy. Compare fmri_voxdist's
% distance map, which has the same property for the same reason.
%
% THE COLORMAP ALSO HAS TO CHANGE. The default diverging map is grey at its
% midpoint, and the anatomical template is also grey - so lag-0 voxels are drawn
% but are indistinguishable from the background, which is no better than hiding
% them. A blue-GREEN-red map gives zero a colour that appears nowhere in the
% anatomy, so all three states are legible: leading, simultaneous, delayed.
lagmap_cmap = interp1([1 32.5 64], [0 0 1; 0 0.75 0.2; 1 0 0], 1:64);

lag_map = peak_lag;
lag_map(abs(peak_r) <= r_show) = NaN;

% COLOUR LIMITS FOLLOW THE OBSERVED LAGS, NOT MAXLAG. The search window is
% +/-5 scans but the lags present are only +/-2, so scaling to [-maxlag maxlag]
% would put +2 about 70% of the way up the ramp and render it olive rather than
% red. The 95th percentile rather than the outright maximum, because a few
% surviving noise voxels have arbitrary peak lags and a single one at +/-maxlag
% would drag the limits back out.
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

fprintf('\nDone. Lags are reported in SCANS; multiply by TR = %g s for seconds.\n', TR);
fprintf(['In the lag map: red = delayed, blue = leading, GREEN = lag 0.\n' ...
    'Green is used rather than the default grey because the anatomical ' ...
    'template is\nalso grey - a grey-centred colormap draws the lag-0 voxels ' ...
    'but makes them\nindistinguishable from the background.\n']);
