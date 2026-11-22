function [beta_ppi, beta_seed, beta_psych] = fmri_ppi(data, seed_mask, psych)
% FMRI_PPI  Voxelwise psychophysiological interaction (PPI) analysis.
%
% Fits the PPI model of Friston et al. (1997) at every voxel and returns the
% interaction beta: where connectivity with a seed region CHANGES as a function
% of a psychological variable.
%
% Usage:
%   beta_ppi = fmri_ppi(data, seed_mask, psych)
%   [beta_ppi, beta_seed, beta_psych] = fmri_ppi(data, seed_mask, psych)
%
% Inputs:
%   DATA      - fMRI time series, vectorized (228453 x T).
%   SEED_MASK - Seed region, 228453 x 1, logical or binary. The seed time
%               series is the mean across its voxels.
%   PSYCH     - Psychological regressor, T x 1, ALREADY CONVOLVED with the HRF.
%               For a block design this is a boxcar convolved with the HRF; for
%               a naturalistic paradigm it is a continuous stimulus feature
%               (acoustic envelope, event-boundary density) convolved likewise.
%               Convolve with fmri_doublegamma before calling - the function
%               does not do it for you, so the same regressor can be reused
%               across analyses.
%
% Outputs:
%   BETA_PPI   - 228453 x 1, the INTERACTION beta. The quantity of interest.
%   BETA_SEED  - 228453 x 1, seed main effect (task-independent connectivity).
%   BETA_PSYCH - 228453 x 1, psychological main effect (task activation).
%
% The model:
%
%     Y = b_ppi*(seed .* psych) + b_seed*seed + b_psych*psych + b_0 + e
%
% The two main effects are included as nuisance terms so that BETA_PPI reflects
% connectivity change attributable to the interaction, over and above seed
% activity and task activation on their own. Omitting them makes the
% interaction term absorb both, and the result is not a PPI.
%
% METHODOLOGICAL NOTE
%   This function forms the interaction in the BOLD domain by multiplying the
%   measured seed time series by the HRF-convolved psychological regressor.
%   This follows the original PPI formulation but does not explicitly model
%   the underlying neural interaction. Because convolution and multiplication
%   are not interchangeable:
%
%       conv(neural_seed .* psych, hrf) ~= ...
%           conv(neural_seed, hrf) .* conv(psych, hrf)
%
%   an alternative approach is to deconvolve the seed time series, form the
%   interaction in the neural domain, and reconvolve it with the HRF
%   (Gitelman et al., 2003). The deconvolution step can be performed with
%   fmri_wiener:
%
%       seed_neural = fmri_wiener(seed_ts, hrf, reg);
%       interaction = conv(seed_neural .* psych_neural, hrf);
%
%   The difference between these approaches may be particularly relevant for
%   event-related and rapidly varying designs. Interpret results with regard
%   to the PPI formulation used.
%
% NOTE ON BETA_SEED
%   BETA_SEED estimates the association between each voxel and the mean seed
%   time series after accounting for the psychological and interaction terms.
%   Noise in the estimated seed time series may attenuate this coefficient.
%   Using a sufficiently large, anatomically appropriate seed with reliable
%   signal can reduce this problem.
%
% GROUP INFERENCE
%   BETA_PPI is a regression coefficient, not a correlation. Do NOT apply
%   fmri_fisherz to it: that is atanh, defined for correlations in [-1, 1],
%   and betas are unbounded. Collect one beta map per participant and test them
%   directly:
%
%       beta_all(:, s) = fmri_ppi(data_s, seed_mask, psych_s);
%       [t, p, df]     = fmri_ttest(beta_all);
%
% Examples:
%   % Hippocampal seed, block design
%   seed_mask  = fmri_regionmask(57);              % AAL left hippocampus
%   hrf        = fmri_doublegamma(0:TR:30)';
%   psych_conv = conv(psych_raw, hrf);
%   psych_conv = psych_conv(1:size(data, 2));      % causal, trim to T
%   beta_ppi   = fmri_ppi(data, seed_mask, psych_conv);
%
%   % Display at the threshold the analysis can actually resolve
%   fmri_showslices(beta_ppi, 1, 2, [-0.5 0.5], [], [], 1, [], 0.1);
%
% References:
%   Friston, K.J., Buechel, C., Fink, G.R., Morris, J., Rolls, E. & Dolan, R.J.
%   (1997). Psychophysiological and modulatory interactions in neuroimaging.
%   NeuroImage, 6(3), 218-229.
%
%   Gitelman, D.R., Penny, W.D., Ashburner, J. & Friston, K.J. (2003). Modeling
%   regional and psychophysiologic interactions in fMRI: the importance of
%   hemodynamic deconvolution. NeuroImage, 19(1), 200-207.
%
% See also: fmri_corregressor, fmri_partcorr, fmri_regionmask, fmri_doublegamma,
%           fmri_wiener, fmri_ttest

%% --- validation -----------------------------------------------------------
if size(data, 1) ~= 228453
    error('fmri_ppi:badVoxelCount', ...
        ['DATA must be 228453 x T (vectorized MNI152 2mm).\n' ...
         'Got %s. Use fmri_vol2vect to vectorize a 4D volume.'], ...
        mat2str(size(data)));
end
T = size(data, 2);

if numel(seed_mask) ~= 228453
    error('fmri_ppi:badSeedSize', ...
        ['SEED_MASK must have 228453 elements, got %d.\n' ...
         'Use fmri_regionmask or fmri_spheremask to build one.'], numel(seed_mask));
end
seed_mask = logical(seed_mask);
if ~any(seed_mask)
    error('fmri_ppi:emptySeed', ...
        ['SEED_MASK is empty - no voxels selected.\n' ...
         'Without this check the seed time series would be all NaN and every ' ...
         'output would\nbe NaN with no error raised.']);
end

if numel(psych) ~= T
    error('fmri_ppi:psychLength', ...
        ['PSYCH must have one value per time point: expected %d, got %d.\n' ...
         'If you convolved with the HRF, remember conv() lengthens the signal - ' ...
         'trim it\nback to T.'], T, numel(psych));
end
psych = psych(:);

%% --- seed time series ------------------------------------------------------
seed_ts = mean(data(seed_mask, :), 1, 'omitnan')';      % T x 1

if all(~isfinite(seed_ts))
    error('fmri_ppi:seedAllNaN', ...
        ['The seed time series is entirely non-finite.\n' ...
         'Every voxel in SEED_MASK is NaN or Inf across all time points - ' ...
         'check that the\nmask overlaps the brain and that DATA is finite there.']);
end

%% --- build the design ------------------------------------------------------
% Centre the seed and psychological regressors before forming their product,
% so the interaction term is separated from their main effects.
seed_ts = seed_ts - mean(seed_ts);
psych   = psych   - mean(psych);
ppi     = seed_ts .* psych;
ppi     = ppi - mean(ppi);

X = [ppi, seed_ts, psych, ones(T, 1)];                  % T x 4

if rank(X) < size(X, 2)
    error('fmri_ppi:rankDeficient', ...
        ['The design matrix is rank deficient (rank %d of %d).\n' ...
         'This happens when PSYCH is constant, or when the seed time series is ' ...
         'a scaled\ncopy of PSYCH, so the interaction adds no information.'], ...
        rank(X), size(X, 2));
end

%% --- solve for every voxel at once -----------------------------------------
% Solve the full regression directly with backslash, which is more
% numerically stable than forming the normal equations (X'X)\(X'Y),
% particularly when the seed and psychological regressors are correlated.
beta = X \ data';                                       % 4 x 228453

beta_ppi   = beta(1, :)';
beta_seed  = beta(2, :)';
beta_psych = beta(3, :)';
end