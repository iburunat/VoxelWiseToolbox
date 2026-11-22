function [acf_vol, calib] = fmri_acfestimate(datapath, regr, n_perm, calibrate)
% FMRI_ACFESTIMATE  Estimates the spatial smoothing KERNEL of the data.
%
% Estimates the mean smoothing kernel of pseudo-normal statistical images
% (pn-SI) by correlating phase-randomised regressors with brain data. This is
% the first step of the cluster-size correction procedure (Ledberg et al.,
% 1998).
%
% The ACF of the statistical image P has Fourier transform |P_hat|^2 
% (Wiener-Khinchin); white noise filtered by K gives an image whose ACF has 
% Fourier transform |K_hat|^2. Requiring the two to match gives 
% |K_hat| = |P_hat|, hence K = IFT|FFT(P)|, which is why the code takes
% abs(fftn(.)) and not abs(fftn(.)).^2.
%
% fmri_csdist convolves white noise with this output, so it requires the
% KERNEL. 
%
% Usage:
%   acf_vol = fmri_acfestimate(datapath, regr, n_perm)
%   [acf_vol, calib] = fmri_acfestimate(datapath, regr, n_perm, calibrate)
%
% Inputs:
%   DATAPATH - Path to directory containing vectorized fMRI data (.mat files).
%              Each file should contain one variable: a (228453 x T) matrix;
%              If a file holds several, the first variable is used. 
%   REGR     - Regressor matrix (T x R) for R regressors of interest.
%   N_PERM   - Number of phase-randomisations per subject per regressor.
%              Default: 10. More = better ACF estimate but slower.
%   CALIBRATE - Logical. Default FALSE, which reproduces the behaviour of the
%              original implementation exactly.
%
%              When TRUE, the kernel is replaced by an isotropic Gaussian
%              tuned so that images simulated from it are as smooth as the
%              data. This corrects a known bias: the estimated kernel comes
%              out too narrow, so "the size threshold will be too liberal"
%              (Ledberg et al., p. 116). They inflate the kernel "by adding
%              a constant at small lags", and note that this "needs to be
%              further investigated" (p. 125).
%
%              The bias is larger here because the statistical image is zero
%              outside the brain, and that step edge is broadband and narrows
%              the kernel. On synthetic data, the uncalibrated kernel gives
%              simulated images 15-20% less smooth than the data.
%
%              OFF by default: turning it on changes cluster-size thresholds,
%              and therefore results.
% 
% Outputs:
%   ACF_VOL  - Cell array (1 x R), one KERNEL volume per regressor: a
%              902629 x 1 vector on the full 91x109x91 grid (fmri_csdist 
%              reshapes it into a 3D kernel. Each is the mean kernel over 
%              subjects and permutations, centred at (46,55,46). Only its 
%              shape matters, not its scale: fmri_csdist z-scores every 
%              simulated image.
%    CALIB    - Struct array (1 x R) reporting the calibration, empty when
%              CALIBRATE is false. Fields: data_fwhm (measured smoothness of
%              the statistical images), sim_fwhm (smoothness achieved by the
%              returned kernel), sigma (the fitted Gaussian width), and ratio
%              (sim_fwhm / data_fwhm, which should be near 1).
%
% Examples:
%   % Step one of the cluster-size correction
%   acf = fmri_acfestimate('/data/vectorized', regr, 10);
%
%   % Calibrated, with a check on how well the kernel matched the data
%   [acf, calib] = fmri_acfestimate('/data/vectorized', regr, 10, true);
%   fprintf('ratio %.3f (1.0 = simulated smoothness matches data)\n', ...
%           calib(1).ratio);
%
% References:
%   Ledberg, A., Akerman, S., & Roland, P.E. (1998). Estimation of the
%   probabilities of 3D clusters in functional brain images. NeuroImage, 8, 113-128.
%   Ebisuzaki, W. (1997). J. Climate, 10(6), 2147-2153.
%
% See also: fmri_csdist, fmri_csthreshold, fmri_scramblephases, fmri_corregressor

if nargin < 3 || isempty(n_perm),    n_perm    = 10;    end
if nargin < 4 || isempty(calibrate), calibrate = false; end
calib = [];

if ~isfolder(datapath)
    error('fmri_acfestimate:noDir', ...
          ['DATAPATH ''%s'' is not a folder.\n' ...
           'It should contain one .mat file per subject, each holding a ' ...
           '228453 x T matrix.'], datapath);
end

% X    = zscore(regr);
X = (regr - mean(regr)) ./ std(regr);
R    = size(X, 2);
dirls = dir(fullfile(datapath, '*.mat'));

if isempty(dirls)
    error('fmri_acfestimate:noData', ...
          ['No .mat files found in ''%s''.\n' ...
           'Each file should contain one 228453 x T matrix.'], datapath);
end

% Initialise ACF accumulator per regressor
acf_vol = cell(1, R);
meas    = cell(1, R);      % measured ACF of the statistical images
for r = 1:R
    acf_vol{r} = zeros(91*109*91, 1);
    meas{r}    = zeros(91*109*91, 1);
end

fprintf('Estimating mean ACF (%d subjects, %d regressors, %d perm each)...\n', ...
        length(dirls), R, n_perm);

for s = 1:length(dirls)
    tmp      = load(fullfile(datapath, dirls(s).name));
    fname    = fieldnames(tmp);
    voldata  = tmp.(fname{1});

    if size(voldata, 1) ~= 228453
        error('fmri_acfestimate:badData', ...
              ['''%s'' holds a %d x %d matrix; expected 228453 rows.\n' ...
               'Vectorize with fmri_vol2vect before saving.'], ...
              dirls(s).name, size(voldata,1), size(voldata,2));
    end
    if size(voldata, 2) ~= size(X, 1)
        error('fmri_acfestimate:lengthMismatch', ...
              ['''%s'' has %d time points but REGR has %d rows.\n' ...
               'The regressor must be sampled at the same TRs as the data.'], ...
              dirls(s).name, size(voldata,2), size(X,1));
    end

    for r = 1:R
        reg = X(:, r);
        for p = 1:n_perm
            % reg is a T x 1 column, so DIM = 1 is the time axis.
            ph_reg  = fmri_scramblephases(reg, 1);
            corr_map = fmri_corregressor(ph_reg, voldata);
            corr_map(isnan(corr_map)) = 0;
            z_vol   = fmri_vect2vol(atanh(corr_map));

            % Ledberg et al. (1998), Eq. 7:  K = IFT|FFT(P)|
            % This is the filter KERNEL
            fft_vol = fftn(z_vol);
            acf_raw = real(fftshift(ifftn(abs(fft_vol))));

            acf_vol{r} = acf_vol{r} + acf_raw(:);

            if calibrate
                a2 = real(fftshift(ifftn(abs(fft_vol).^2)));
                meas{r} = meas{r} + a2(:);
            end
        end
    end
    fprintf('  Subject %d/%d done.\n', s, length(dirls));
end

% Ledberg Eq. 9: the kernel is the MEAN of the individual estimates, which is
% how the variance of the estimator is controlled.
nobs = length(dirls) * n_perm;
for r = 1:R
    acf_vol{r} = acf_vol{r} / nobs;
    meas{r}    = meas{r} / nobs;
end

if calibrate
    calib = repmat(struct('data_fwhm', NaN, 'sim_fwhm', NaN, ...
                          'sigma', NaN, 'ratio', NaN), 1, R);
    for r = 1:R
        target_fwhm = local_fwhm(local_profile(reshape(meas{r}, 91, 109, 91)));

        lo = 0.5; hi = 8;
        for it = 1:12
            mid = (lo + hi) / 2;
            f   = local_simulated_fwhm(mid);
            if f < target_fwhm, lo = mid; else, hi = mid; end
        end
        sigma_fit = (lo + hi) / 2;

        [xx, yy, zz] = ndgrid(-45:45, -54:54, -45:45);
        Kg = exp(-(xx.^2 + yy.^2 + zz.^2) / (2 * sigma_fit^2));
        acf_vol{r} = Kg(:) / max(Kg(:));

        calib(r).data_fwhm = target_fwhm;
        calib(r).sim_fwhm  = local_simulated_fwhm(sigma_fit);
        calib(r).sigma     = sigma_fit;
        calib(r).ratio     = calib(r).sim_fwhm / target_fwhm;

        fprintf(['  Regressor %d calibrated: data FWHM %.2f, simulated %.2f ' ...
                 '(ratio %.3f), kernel sigma %.2f\n'], ...
                r, calib(r).data_fwhm, calib(r).sim_fwhm, ...
                calib(r).ratio, calib(r).sigma);
    end
end
end

% --- helpers -----------------------------------------------------------

function p = local_profile(A)
% Normalised autocorrelation profile along x, lags 0..19.
A = A / max(A(:));
p = zeros(1, 20);
for d = 0:19
    p(d+1) = A(46+d, 55, 46);
end
end

function f = local_fwhm(p)
i = find(p < 0.5, 1);
if isempty(i) || i < 2
    f = NaN;
else
    t = (p(i-1) - 0.5) / (p(i-1) - p(i));
    f = 2 * (i - 2 + t);
end
end

function f = local_simulated_fwhm(sigma, ntrial)
% Smoothness actually achieved by convolving white noise with an isotropic
% Gaussian kernel of the given width, measured the same way as for the data.
if nargin < 2, ntrial = 3; end
ax = -5:5;
[xx, yy, zz] = ndgrid(ax, ax, ax);
K = exp(-(xx.^2 + yy.^2 + zz.^2) / (2 * sigma^2));
K = K / sum(K(:));

acc = zeros(1, 20);
for k = 1:ntrial
    S = convn(randn(91, 109, 91), K, 'same');
    %S = fmri_vect2vol(zscore(fmri_vol2vect(S)));
    Sv = fmri_vol2vect(S);
    S  = fmri_vect2vol((Sv - mean(Sv)) ./ std(Sv)); % zscore equiv
    S = S - mean(S(:));
    A = real(fftshift(ifftn(abs(fftn(S)).^2)));
    acc = acc + local_profile(A);
end
f = local_fwhm(acc / ntrial);
end