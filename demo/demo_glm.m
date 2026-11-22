%% DEMO_GLM  Two-level fMRI analysis with a single task regressor
%
% Demonstrates a two-level analysis of simulated fMRI data. A voxelwise
% correlation map is calculated for each participant and then tested across
% participants. The recovered group map is compared with the expected signal.
%
% This introductory demo uses an uncorrected voxel threshold of p < 0.001 and
% a fixed 20-voxel extent. See demo_csizeestimation and demo_tfce for
% multiple-comparison methods.
%
%
% Steps:
%   1. Simulate a 20-participant cohort                           fmri_simdata
%   2. First level: correlate the task regressor with each voxel  fmri_corregressor
%   3. Second level: test the participant maps at group level     fmri_ttest
%   4. Threshold the result and remove small clusters             fmri_cleanclusters
%   5. Label the surviving clusters and compare with truth        fmri_regiontable
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
% Reconstruct one participant at a time; retaining all full volumes would
% require about 22 GB.
fprintf('Step 1: Simulating %d participants...\n', n_subj);
[X_comp, ~, W, svd_info, ~, sim] = fmri_simdata(n_sources, n_subj, n_scans, TR, [], [], ...
        phase_strength, n_network, 0, false);

n_voxels = sim.mask.n_voxels;
fprintf('  %d voxels | %d sources, %d in the task network\n\n', ...
        n_voxels, n_sources, numel(sim.design.network.idx));

%% 2. First level: one map per participant
% -------------------------------------------------------------------
fprintf('Step 2: First-level analysis...\n');
z_maps = zeros(n_voxels, n_subj);

for p = 1:n_subj
    % Reconstruct and analyse one participant at a time to limit memory use.
    dat = fmri_simget(X_comp, svd_info, p);
    dat = fmri_zscorevoldata(fmri_detrend(dat));

    % Detrend the participant-specific task regressor to match the data.
    reg = fmri_detrend(W.bold(:, 1, p)');
    reg = reg(:);
    
    r = fmri_corregressor(reg, dat);

    % Apply the plain Fisher transform before group analysis. Use ATANH directly,
    % not fmri_fisherz, because the latter also standardises by sample size.
    z_maps(:, p) = atanh(r);

    if p == 1
        sub1_r = r;    % kept for the first-level figure
    end

    clear dat
    
    if mod(p, 5) == 0, 
        fprintf('  %d/%d done\n', p, n_subj); 
    end
end
fprintf('  First-level maps: %d voxels x %d participants\n\n', size(z_maps));

%% 3. Second level: one-sample t-test across participants
% -------------------------------------------------------------------
% Degrees of freedom are N - 1: participants, not time points, are the
% observations.
fprintf('Step 3: Group t-test...\n');
[t_map, p_grp, df_group] = fmri_ttest(z_maps);
t_crit = fmri_p2t(alpha_th, df_group);

fprintf('  df = %d (%d participants), t_crit = %.2f at p < %g\n', ...
        df_group, n_subj, t_crit, alpha_th);
fprintf('  Significant voxels, uncorrected: %d\n\n', nnz(p_grp < alpha_th));

%% 4. Threshold and clean clusters
% -------------------------------------------------------------------
fprintf('Step 4: Thresholding and cluster cleaning...\n');
clean_map = fmri_cleanclusters(p_grp < alpha_th, min_extent, 0);
n_after   = nnz(clean_map > 0);
fprintf('  %d voxels survive a %d-voxel minimum extent\n\n', ...
        n_after, min_extent);

%% 5. Label regions, and compare with the planted signal (truth)
% -------------------------------------------------------------------
fprintf('Step 5: Anatomical labelling...\n');
if n_after > 0
    clust = fmri_regiontable(clean_map, t_map, min_extent, 0, 1);
    fprintf('  %d cluster(s) tabulated.\n\n', numel(clust));
else
    fprintf('  No clusters survived; nothing to tabulate.\n\n');
end

% Column 1 of SIM.TRUTH.POPULATION gives the expected cohort-level correlation
% with the task time course. It may include contributions from any source with
% a related time course, not only source 1.

r_truth = sim.truth.population(:, 1);
fprintf('  Expected signal displayed at |r| >= 0.1: %d voxels\n\n', ...
        nnz(abs(r_truth) > 0.1));

%% Figures
% -------------------------------------------------------------------
fprintf('Visualising...\n');

figure('Name', 'Planted signal');
fmri_showslices(r_truth, 1, 2, [-1 1], [], [], 1, [], 0.1);
title('Expected task correlation (|r| >= 0.1)');
figure('Name', 'First level, participant 1');
fmri_showslices(sub1_r, 1, 2, [-0.6 0.6], [], [], 1, [], 0.2);
title('Participant 1, first-level r-map (|r| >= 0.2)');

figure('Name', 'Group t-map');
% Use the analysis threshold and limit the colour range to +/-3*t_crit.
fmri_showslices(t_map, 1, 2, [-3*t_crit 3*t_crit], [], [], 1, [], t_crit);
title(sprintf('Group t-map, N = %d (p < %g, |t| >= %.2f)', ...
      n_subj, alpha_th, t_crit));

figure('Name', 'Surviving clusters');
% Retain the sign of each surviving cluster.
clean_signed = double(clean_map > 0) .* sign(t_map);
fmri_showslices(clean_signed, 1, 2, [-1 1], [], [], 1, [], 0.5);
title(sprintf('Surviving clusters, signed (%d voxels)', n_after));

fprintf('\n=== Demo complete ===\n');
fprintf(['Compare the expected-correlation map with the surviving clusters. ' ...
         'Use\nvalidate_glm_recovery for quantitative recovery scores.\n']);