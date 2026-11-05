%% DEMO_GLM  Two-level analysis on simulated fMRI data
%
% The shortest complete path from simulated data to a thresholded, labelled
% group map: simulate a cohort, correlate a regressor with every voxel for
% each participant, test those maps across participants, clean the result and
% label it anatomically.
%
% WHAT THIS DEMO IS FOR
%   Learning the two-level workflow and the toolbox's calling conventions. It
%   answers three questions: what happens at the first level, what happens at
%   the second, and whether the result matches the signal that was planted.
%
%   It is NOT a corrected analysis. The surviving clusters come from an
%   uncorrected voxel threshold (p < 0.001) plus a fixed minimum extent. For
%   the correction methods see demo_csizeestimation (Ledberg cluster extent)
%   and demo_tfce (threshold-free cluster enhancement). For quantitative
%   recovery scoring - precision, recall, source leakage - see
%   validate_glm_recovery.
%
% Steps:
%   1. Simulate a 20-participant cohort        fmri_simdata
%   2. First level: one map per participant    fmri_corregressor
%   3. Second level: group t-test              fmri_ttest
%   4. Threshold and clean clusters            fmri_cleanclusters
%   5. Label regions and compare with truth    fmri_regiontable
%
% Self-contained: it simulates its own data and needs no scanner data and
% nothing beyond base MATLAB.
%
% See also: fmri_simdata, fmri_simget, fmri_corregressor, fmri_ttest,
%           fmri_cleanclusters, fmri_regiontable, fmri_p2t, demo_tfce,
%           demo_csizeestimation, demo_preprocessing, validate_glm_recovery

clear; close all;
if exist('fmritoolbox_setup', 'file')
    fmritoolbox_setup;
else
    error('Please run fmritoolbox_setup.m from the toolbox root first.');
end
fprintf('=== VoxelWise Toolbox two-level analysis demo ===\n\n');

%% Parameters
TR             = 2;       % repetition time, seconds
n_scans        = 150;     % volumes per participant
n_subj         = 20;      % participants
n_sources      = 10;      % spatial sources (activation blobs)
n_network      = 3;       % sources sharing the task time course
phase_strength = 0.6;     % inter-participant variability, 0 to 1
alpha_th       = 0.001;   % voxel-level threshold
min_extent     = 20;      % minimum cluster size, voxels
rng(123);                 % reproducible

%% 1. Simulate a cohort
% -------------------------------------------------------------------
% WANT_FULL = false (argument 10) returns the compressed form only. The full
% 4D volumes are about 110 MB per participant and fmri_simget reconstructs
% one at a time in step 2, so there is no reason to hold them all.
fprintf('Step 1: Simulating %d participants...\n', n_subj);
[X_comp, S_3D, W, svd_info, ~, sim] = fmri_simdata( ...
        n_sources, n_subj, n_scans, TR, [], [], ...
        phase_strength, n_network, 0, false);

n_voxels = sim.mask.n_voxels;
fprintf('  %d voxels | %d sources, %d in the task network\n\n', ...
        n_voxels, n_sources, numel(sim.design.network.idx));

%% 2. First level: one map per participant
% -------------------------------------------------------------------
fprintf('Step 2: First-level analysis...\n');
z_maps = zeros(n_voxels, n_subj);

for p = 1:n_subj
    % One participant at a time, to bound memory.
    dat = fmri_simget(X_comp, svd_info, p);
    dat = fmri_zscorevoldata(fmri_detrend(dat));

    % The regressor is the BOLD time course the simulation put in the data.
    reg = W.bold(:, 1, p);

    r = fmri_corregressor(reg, dat);

    % Variance-stabilise before pooling across participants. This is plain
    % atanh(r), NOT fmri_fisherz: fmri_fisherz returns the standardised test
    % statistic atanh(r)*sqrt(df-3), already divided by its standard error,
    % and the group test in step 3 divides by a standard error of its own.
    % Passing the standardised form would apply that twice.
    z_maps(:, p) = atanh(r);

    if p == 1
        sub1_r = r;    % kept for the first-level figure
    end
    clear dat
    if mod(p, 5) == 0, fprintf('  %d/%d done\n', p, n_subj); end
end
fprintf('  First-level maps: %d voxels x %d participants\n\n', size(z_maps));

%% 3. Second level: one-sample t-test across participants
% -------------------------------------------------------------------
% fmri_ttest does the whole test: mean across participants, the
% between-participant standard error, t, the two-tailed p, and a guard for
% voxels with no variance. The degrees of freedom are N-1 - PARTICIPANTS, not
% time points - because the observations being tested are participants and
% the null variance comes from the spread between them.
fprintf('Step 3: Group t-test...\n');
[t_map, p_grp, df_group] = fmri_ttest(z_maps);
t_crit = fmri_p2t(alpha_th, df_group);

fprintf('  df = %d (%d participants), t_crit = %.2f at p < %g\n', ...
        df_group, n_subj, t_crit, alpha_th);
fprintf('  Significant voxels, uncorrected: %d\n\n', nnz(p_grp < alpha_th));

%% 4. Threshold and clean clusters
% -------------------------------------------------------------------
% fmri_cleanclusters drops clusters below a minimum size. Its third argument
% is a minimum neighbour count per voxel; 0 disables that second criterion, so
% surviving clusters are kept whole. Connectivity is the fourth argument and
% defaults to 18 (face and edge).
fprintf('Step 4: Thresholding and cluster cleaning...\n');
clean_map = fmri_cleanclusters(p_grp < alpha_th, min_extent, 0);
n_after   = nnz(clean_map > 0);
fprintf('  %d voxels survive a %d-voxel minimum extent\n\n', ...
        n_after, min_extent);

%% 5. Label regions, and compare with the planted signal
% -------------------------------------------------------------------
fprintf('Step 5: Anatomical labelling...\n');
if n_after > 0
    clust = fmri_regiontable(clean_map, t_map, min_extent, 0, 1);
    fprintf('  %d cluster(s) tabulated.\n\n', numel(clust));
else
    fprintf('  No clusters survived; nothing to tabulate.\n\n');
end

% The simulator returns the expected correlation between every voxel and the
% task time course, derived in closed form from the source weights and the
% noise level. It is the quantity a correlation analysis estimates, so it can
% be compared with the group map directly.
%
% sim.truth.population(:,k) is the correlation with source k's TIME COURSE, not
% a map of source k's territory: any source whose time course resembles source
% k's appears in column k wherever it sits. Column 1 is the task time course.
r_truth = sim.truth.population(:, 1);
fprintf('  Planted signal: %d voxels with |expected r| > 0.1\n\n', ...
        nnz(abs(r_truth) > 0.1));

%% Figures
% -------------------------------------------------------------------
% One figure per call, NOT subplot. The toolbox viewers manage figure-level
% state and overwrite one another inside subplot panels.
%
% Every call passes an explicit THRESHOLD, and CLIMITS(1) stays strictly
% BELOW it: data is clamped into CLIMITS before the display mask is built, so
% CLIMITS(1) >= THRESHOLD would paint the whole brain.
fprintf('Visualising...\n');

figure('Name', 'Planted signal');
fmri_showslices(r_truth, 1, 2, [-1 1], [], [], 1, [], 0.1);
title('Planted signal: expected correlation with the task time course (|r| \geq 0.1)');

figure('Name', 'First level, participant 1');
fmri_showslices(sub1_r, 1, 2, [-0.6 0.6], [], [], 1, [], 0.2);
title('Participant 1, first-level r-map (|r| >= 0.2)');

figure('Name', 'Group t-map');
% Display threshold = the value the analysis used, so figure and inference
% agree. Colour limits are a small multiple of it rather than max|t|, which
% is an outlier at this df.
fmri_showslices(t_map, 1, 2, [-3*t_crit 3*t_crit], [], [], 1, [], t_crit);
title(sprintf('Group t-map, N = %d (p < %g, |t| >= %.2f)', ...
      n_subj, alpha_th, t_crit));

figure('Name', 'Surviving clusters');
% Signed, so this is comparable with the planted signal and the t-map. A
% plain binary mask would paint deactivations the same colour as activations.
clean_signed = double(clean_map > 0) .* sign(t_map);
fmri_showslices(clean_signed, 1, 2, [-1 1], [], [], 1, [], 0.5);
title(sprintf('Surviving clusters, signed (%d voxels)', n_after));

fprintf('\n=== Demo complete ===\n');
fprintf(['Compare the first and last figures: the planted signal and what ' ...
         'the\nanalysis recovered. validate_glm_recovery scores the agreement ' ...
         'numerically.\n']);
