function D = fmri_csdist(acf_vol, si_alpha, n_perm, calib)
% FMRI_CSDIST  Null cluster-size distribution from a smoothing kernel.
%
% Generates the null distribution of cluster sizes at one or more
% statistical thresholds by convolving the estimated smoothing kernel with
% Gaussian noise and recording the resulting cluster sizes. This is the
% second step of the Ledberg et al. (1998) cluster-size correction
% procedure.
%
% Usage:
%   D = fmri_csdist(acf_vol)
%   D = fmri_csdist(acf_vol, si_alpha)
%   D = fmri_csdist(acf_vol, si_alpha, n_perm)
%   D = fmri_csdist(acf_vol, si_alpha, n_perm, calib)
%
% Inputs:
%   ACF_VOL   - Cell array {1 x R} of kernel volumes, one per regressor, as
%               returned by fmri_acfestimate. Each cell holds a 902629 x 1
%               vector, i.e. the full 91x109x91 grid. A single volume may be
%               passed outside a cell.
%   SI_ALPHA  - Voxel-level threshold(s) as alpha PER TAIL. Null maps are
%               thresholded at abs(z) > -norminv(SI_ALPHA), so both tails are
%               retained and the total two-sided voxel rate is 2*SI_ALPHA. A map
%               thresholded with a two-tailed p must therefore pass p/2 here.
%               Default: [0.01 0.001 0.0001]
%   N_PERM    - Number of random images to generate. Default: 1000, matching
%               Alluri et al. (2012). The critical size is fixed by wherever
%               the survival curve crosses the FWER level, so only about
%               alpha*N_PERM images actually determine it. Simulated standard
%               deviation of the resulting threshold:
%
%                 N_PERM    SD (voxels)   as % of a 22-voxel threshold
%                    100         13              59%
%                    500          6              27%
%                   1000          4              18%
%                   2000          3              14%
%
%               The previous default of 100 gave an SD of roughly half the
%               threshold itself for the small thresholds typical at strict SI
%               alphas. Ledberg et al. used 9000, which is what their own
%               Eq. 11 requires for the confidence half-width to fall within
%               10% of alpha. A warning is issued below 500.
%   CALIB     - The second output of fmri_acfestimate when called with
%               CALIBRATE true. Passing it suppresses the kernel truncation
%               warning, which does not apply to a calibrated kernel: the
%               calibration fits the width using the same 11x11x11 crop, so a
%               high boundary value is already accounted for. Default: [].
%
% Outputs:
%   D         - Cluster-size distribution as a cell array {1 x R}.
%               D{r} is a (500 x length(SI_ALPHA)) matrix. D{r}(k, zi) is the
%               empirical probability that a null image contains at least one
%               cluster LARGER THAN k voxels at threshold zi. The row index is
%               therefore an exclusive bound, which is what fmri_csthreshold
%               expects.
%
%               Sizes above 500 are not tabulated. A warning is issued if the
%               distribution has not decayed by then, since thresholds derived
%               from a truncated distribution are underestimates.
%
% DEPENDENCY
%   standard_brain.mat, which ships with the toolbox and holds BR, the
%   91 x 109 x 91 binary brain mask. fmritoolbox_setup puts it on the path.
%   Clusters are counted inside that mask only, so the null distribution is
%   built over the same search volume the real analysis used.
%
% Examples:
%   % Steps one and two of the correction, publication settings
%   acf = fmri_acfestimate('/data/vectorized', regr, 10);
%   D   = fmri_csdist(acf, [0.01 0.001 0.0001], 1000);
%
%   % Calibrated kernel: passing CALIB skips the truncation check
%   [acf, calib] = fmri_acfestimate('/data/vectorized', regr, 10, true);
%   D = fmri_csdist(acf, [0.01 0.001 0.0001], 1000, calib);
%
%   % A quick, deliberately noisy run while setting a pipeline up
%   D = fmri_csdist(acf, 0.001, 100);   % warns: threshold SD ~13 voxels
%
% References:
%   Ledberg, A., Akerman, S., & Roland, P.E. (1998). NeuroImage, 8, 113-128.
%
% See also: fmri_acfestimate, fmri_csthreshold, fmri_cleanclusters

if nargin < 4, calib = []; end
if nargin < 3 || isempty(n_perm),   n_perm   = 1000;                 end
if nargin < 2 || isempty(si_alpha), si_alpha = [0.01 0.001 0.0001];  end

load standard_brain   % supplies br, the 91x109x91 binary brain mask

% Per-tail z-threshold, applied to both tails below through abs(CUvol).
% equivalent to -norminv(si_alpha), without the Statistics dependency
Z = sqrt(2) * erfcinv(2 * si_alpha);

% Wrap single volume in cell for uniform processing
if ~iscell(acf_vol), acf_vol = {acf_vol}; end
R = numel(acf_vol);

D = cell(1, R);

% The number of permutations affects how reliable the estimated
% cluster-size threshold is. With too few simulations, the threshold
% can vary considerably between runs. For example, its standard
% deviation is approximately 13 voxels with 100 permutations, 6 with
% 500, and 3 with 2000. Ledberg et al. used 9000 permutations, while
% Alluri et al. (2012) used 1000. The calculation below estimates
% the uncertainty in the threshold.
hw_05 = 2 * sqrt(0.05 * 0.95 / n_perm);
if n_perm < 500
    warning('fmri_csdist:fewPermutations', ...
            ['n_perm = %d gives a noisy cluster-size threshold. At FWER 0.05 ' ...
             'the 95%% interval on the exceedance probability is +/-%.3f, ' ...
             'i.e. %.0f%% of alpha.\n' ...
             'Ledberg et al. used 9000 simulations and Alluri et al. (2012) ' ...
             '1000. Use at least 1000 for anything to be published.'], ...
            n_perm, hw_05, 100*hw_05/0.05);
end

MAXCS = 500;   % largest cluster size tabulated; see the saturation check below

for r = 1:R
    kernel = reshape(acf_vol{r}, 91, 109, 91);
    DIST   = zeros(MAXCS, length(Z));

    % The kernel is cropped to an 11x11x11 box centred on the volume centre
    % (46,55,46), which is where fmri_acfestimate places the kernel peak. Check
    % that the kernel has actually decayed by the edge of that box: if it has not,
    % the crop discards real spatial correlation, the simulated maps are less
    % smooth than the data, and the resulting threshold is too low.
    C = kernel(41:51, 50:60, 41:51);

    % Skip the truncation check for a calibrated kernel. Calibration fits the
    % kernel width using this same 11x11x11 crop, so a high value at the
    % boundary is already accounted for and the warning would be misleading.
    is_calibrated = ~isempty(calib);
    if max(abs(C(:))) > 0 && ~is_calibrated
        edge_frac = max(abs([reshape(C([1 end],:,:),[],1); ...
                             reshape(C(:,[1 end],:),[],1); ...
                             reshape(C(:,:,[1 end]),[],1)])) / max(abs(C(:)));
        if edge_frac > 0.05
            warning('fmri_csdist:kernelTruncated', ...
                    ['Regressor %d: the kernel is still at %.0f%% of its peak at ' ...
                     'the edge of the 11x11x11 kernel window.\n' ...
                     'The crop is discarding real spatial correlation, which ' ...
                     'makes the simulated maps too rough and the resulting ' ...
                     'cluster-size threshold too low (anti-conservative).'], ...
                    r, 100*edge_frac);
        end
    end

    % Display progress every 10% so users can monitor the simulation and
    % get an estimate of the remaining time.
    t_start = tic;
    step    = max(1, round(n_perm/10));

    for p = 1:n_perm
        if mod(p, step) == 0 || p == n_perm
            el  = toc(t_start);
            eta = el * (n_perm - p) / p;
            fprintf('    permutation %d/%d (%.0f%%), %.0fs elapsed, ~%.0fs remaining\n', ...
                    p, n_perm, 100*p/n_perm, el, eta);
        end
        % Convolve noise with the kernel, then z-score within the mask
        noise = randn(91, 109, 91);
        CU    = convn(noise, C, 'same');
        % z-score within the mask; equivalent to zscore(), without the
        % Statistics dependency.
        CUv   = fmri_vol2vect(CU);
        CUvol = fmri_vect2vol((CUv - mean(CUv)) ./ std(CUv));
    
        for zi = 1:length(Z)
            brain_thresh = (abs(CUvol) > Z(zi)) .* br;
            [L, NUM]     = fmri_bwlabel(brain_thresh, 18);
            if NUM == 0, continue; end

            % Cluster sizes in one pass rather than a full-volume scan each.
            lab_v = L(:);
            c     = accumarray(lab_v(lab_v > 0), 1, [NUM 1]);

            % DIST(cs) counts permutations with any cluster larger than cs.
            % any(c > cs) is true exactly when max(c) > cs, so the whole
            % 1:MAXCS loop reduces to incrementing the first max(c)-1 entries.
            m = min(max(c) - 1, MAXCS);
            if m >= 1
                DIST(1:m, zi) = DIST(1:m, zi) + 1;
            end
        end
    end

    D{r} = DIST / n_perm;   % counts to probabilities

    % If the distribution has not decayed by MAXCS, any threshold taken from it
    % is a lower bound rather than the real critical size.
    for zi = 1:length(Z)
        if D{r}(MAXCS, zi) > 0.01
            warning('fmri_csdist:notDecayed', ...
                    ['Regressor %d, SI alpha %g: %.1f%% of null images still ' ...
                     'contain a cluster larger than %d voxels.\n' ...
                     'The distribution is truncated there, so cluster-size ' ...
                     'thresholds from it will be underestimates. Consider a ' ...
                     'stricter SI alpha.'], ...
                    r, si_alpha(zi), 100*D{r}(MAXCS, zi), MAXCS);
        end
    end
end