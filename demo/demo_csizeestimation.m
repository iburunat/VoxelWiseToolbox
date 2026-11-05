% DEMO_CSIZEESTIMATION  Cluster-size correction by the Ledberg method
%
% Demonstrates the cluster-extent correction of Ledberg et al. (1998) in four
% steps:
%
% ------------------------------------------------------------------------
% 1. fmri_acfestimate     Estimate the spatial smoothing kernel from the data
%            |
%            v
% 2. fmri_csdist          Simulate null maps and record their cluster sizes
%            |
%            v
% 3. fmri_csthreshold     Extract the critical size at the chosen FWER
%            |
%            v 
% 4. fmri_cleanclusters   Remove clusters smaller than the critical size
% ------------------------------------------------------------------------
%
% The size a chance cluster can reach depends on how spatially smooth the data
% is, which varies with acquisition, preprocessing and the analysis itself.
% This workflow measures that smoothness and derives a threshold from it.
%
% Functions demonstrated:
%   fmri_acfestimate, fmri_csdist, fmri_csthreshold, fmri_cleanclusters
%
% RUNTIME AND MEMORY. fmri_acfestimate reads participants from disk, so this
% demo writes temporary files and removes them at the end. Simulating one
% participant allocates the full 91x109x91xT grid before masking, which at
% T = 100 is about 720 MB in memory for roughly 180 MB on disk. Step 2 is the
% slow one - it convolves and cluster-labels a whole volume per null map, and
% reports its own progress and ETA. Every setting below is small; real use
% needs far more permutations at each stage.
%
% References:
%   Ledberg, A., Akerman, S. & Roland, P.E. (1998). Estimation of the
%   probabilities of 3D clusters in functional brain images. NeuroImage 8(2).
%
% See also: fmri_acfestimate, fmri_csdist, fmri_csthreshold,
%           fmri_cleanclusters, fmri_tfce

clear; close all;
fmritoolbox_setup;
fprintf('=== VoxelWise Toolbox: cluster-size correction demo ===\n\n');

%% --- Parameters -----------------------------------------------------------
n_subj      = 3;              % simulated subjects
T           = 100;            % timepoints per subject
R           = 2;              % regressors of interest
n_perm_acf  = 3;              % phase-randomisations per subject per regressor
n_perm_dist = 100;            % null maps for the cluster-size distribution
si_alpha    = [0.01 0.001];   % voxel-level alpha IN EACH TAIL (see step 4)
cs_alpha    = 0.05;           % cluster-level FWER target
rng(7);

% With 100 null maps, probabilities are resolved in steps of 0.01. This
% demo therefore requests only FWER = 0.05. 100 is below the number
% fmri_csdist recommends, so it will warn. Use substantially more null maps
% for final inference.

% Voxel count from the template rather than hardcoded.
load standard_brain
n_vox = nnz(br);

fprintf(['Settings: %d subjects, T = %d, %d regressors, ' ...
         'n_perm = %d (kernel) / %d (null maps)\n'],...
        n_subj, T, R, n_perm_acf, n_perm_dist);
fprintf('These are SMALL for speed. Real use needs far more permutations.\n\n');

%% --- Simulate a dataset on disk -------------------------------------------
% fmri_acfestimate takes a DIRECTORY of .mat files, each holding one
% n_vox x T matrix. A temporary directory is used and removed at the end of the
% demo, so nothing is left behind in the working directory.
datapath = fullfile(tempdir, sprintf('vw_csize_demo_%d', feature('getpid')));
if ~exist(datapath, 'dir'), mkdir(datapath); end

% The noise is SPATIALLY SMOOTHED before saving. Cluster-size correction is a
% response to spatial autocorrelation, so independent voxel noise - whose ACF
% is a spike at the origin - would leave the procedure with nothing to do. Real
% fMRI is smooth, from acquisition, registration and any explicit smoothing.
%
% The Gaussian is applied as three 1D convolutions, one per axis, rather than
% as one 3D kernel.
fwhm_vox = 3;                                  % smoothing FWHM in voxels
sig      = fwhm_vox / sqrt(8*log(2));
kw       = ceil(3*sig);
k1       = exp(-((-kw:kw).^2) / (2*sig^2));
k1       = k1 / sum(k1);

fprintf('Setup: Writing %d simulated subjects (FWHM %g voxels)...\n', ...
        n_subj, fwhm_vox);
for s = 1:n_subj
    vol4 = zeros(91, 109, 91, T);
    for t = 1:T
        v = randn(91, 109, 91);
        v = convn(v, reshape(k1, [], 1, 1), 'same');
        v = convn(v, reshape(k1, 1, [], 1), 'same');
        v = convn(v, reshape(k1, 1, 1, []), 'same');
        vol4(:,:,:,t) = v;
    end
    voldata = fmri_vol2vect(vol4);
    save(fullfile(datapath, sprintf('subj_%02d.mat', s)), 'voldata');
    fprintf('  subject %d/%d\n', s, n_subj);
    clear vol4
end
fprintf('  Path: %s\n\n', datapath);

regr = randn(T, R);

%% --- Step 1: estimate the spatial ACF -------------------------------------
fprintf('Step 1: Estimating the spatial ACF kernel...\n');
acf_vol = fmri_acfestimate(datapath, regr, n_perm_acf);

fprintf('  Regressors returned: %d (expect %d)\n', numel(acf_vol), R);
fprintf(['  Kernel: %d values on the FULL template grid, not the %d in-mask ' ...
         'voxels.\n\n'], size(acf_vol{1}, 1), n_vox);

%% --- Step 2: null distribution of cluster sizes ---------------------------
fprintf('Step 2: Building the null cluster-size distribution...\n');
D = fmri_csdist(acf_vol, si_alpha, n_perm_dist);
fprintf('  Regressors: %d | distribution matrix for regressor 1: %d x %d\n\n', ...
        numel(D), size(D{1}, 1), size(D{1}, 2));

% Plot the null distribution for the first regressor. Each curve shows the
% probability that the largest cluster in a null map exceeds size k.
r = 1;

% D is returned over a fixed 500-voxel range, but the probability falls to zero
% well inside it, so the x-axis follows the data.
last_nz = find(any(D{r} > 1e-6, 2), 1, 'last');
if isempty(last_nz), last_nz = size(D{r}, 1); end
x_hi = min(size(D{r},1), max(10, ceil(1.5*last_nz)));

figure('Name', 'Cluster-size null distribution');
plot(D{r}, 'LineWidth', 2);
xlim([1 x_hi]);
xlabel('Cluster size k (voxels)');
ylabel('P(maximum null cluster > k)');
title(sprintf('Null cluster-size distribution: regressor %d', r));
legend(arrayfun(@(a) sprintf('per-tail alpha = %g', a), si_alpha, ...
       'UniformOutput', false), 'Location', 'northeast');
grid on;

%% --- Step 3: extract critical cluster sizes -------------------------------
fprintf('Step 3: Extracting critical cluster sizes...\n');
[CSIZE, report] = fmri_csthreshold(D, si_alpha, cs_alpha);

fprintf(['\n  Minimum surviving cluster sizes, regressor 1' ...
         '(rows = per-tail alpha, cols = FWER):\n']);
disp(CSIZE{1});
fprintf('%s\n', report);

%% --- Step 4: apply the threshold to a statistical map ---------------------
% Create a z-map containing one planted cluster and scattered noise, then
% apply one of the cluster-size thresholds derived above.
fprintf('Step 4: Applying the threshold to a statistical map...\n');

zmap  = randn(n_vox, 1);                       % noise
[m, roi_name] = fmri_regionmask(1, 1);         % one genuine cluster
zmap(logical(m)) = zmap(logical(m)) + 5;

% Match the cluster-forming threshold used by fmri_csdist. SI_ALPHA is the
% alpha in each tail, and abs(zmap) applies that threshold to both tails.
z_crit    = fmri_p2t(si_alpha(2), 1e6, 1);
z_thresh  = abs(zmap) > z_crit;

% CSIZE contains the minimum surviving cluster size. Row 2 uses per-tail
% alpha = 0.001; column 1 uses cluster-level FWER = 0.05.
csize_use = CSIZE{1}(2, 1);

clean = fmri_cleanclusters(z_thresh, csize_use, 0);

fprintf('  Genuine cluster: %s (%d voxels)\n', roi_name{1}, nnz(m));
fprintf('  Voxel threshold |z| > %.2f  -> %d voxels survive\n', z_crit, nnz(z_thresh));
fprintf('  Minimum surviving cluster size: %d voxels\n', csize_use);
fprintf('  Voxels surviving cluster correction: %d\n', nnz(clean));
fprintf('  Recovered inside the genuine cluster: %d of %d (%.0f%%)\n', ...
        nnz(clean > 0 & logical(m)), nnz(m), 100*nnz(clean > 0 & logical(m))/nnz(m));
fprintf('  Surviving voxels OUTSIDE it: %d\n\n', nnz(clean > 0 & ~logical(m)));

% Show retained voxels in red and removed voxels in blue. Isolated removed
% voxels may be difficult to see, so the printed counts provide the clearer
% numerical comparison.
kept    = clean > 0;
removed = z_thresh & ~kept;
effect  = double(kept) - double(removed);

figure('Name', 'What cluster correction removed');
fmri_showslices(effect, 1, 2, [-1 1], [], [], 1, [], 0.5);
title(sprintf('Cluster correction (>= %d voxels): red kept (%d), blue removed (%d)', ...
      csize_use, nnz(kept), nnz(removed)));

%% --- Clean up -------------------------------------------------------------
% Remove the temporary participant files after successful completion. If
% execution stops earlier, they remain in datapath.
if exist(datapath, 'dir'), rmdir(datapath, 's'); end

fprintf('=== Cluster-size correction demo complete ===\n');
fprintf('Temporary data removed from %s\n', datapath);
