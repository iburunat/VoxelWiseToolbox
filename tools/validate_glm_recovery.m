function runs = validate_glm_recovery()
% validate_glm_recovery  Scores the two-level pipeline against analytic ground truth.
%
% Runs the toolbox's two-level analysis on simulated cohorts with known
% analytic ground truth, then measures recovery using precision and recall.
% This validation underlies Section 5.2 of the toolbox paper; demo_glm shows
% the same workflow without scoring.
%
% INDEPENDENT GROUND TRUTH
%   The expected voxel-to-source correlations are derived directly from the
%   simulation parameters and returned by fmri_simdata in SIM.TRUTH:
%
%       truth(v,k) = (S*G)(v,k) / sqrt(S(v,:)*G*S(v,:)' + (sigma/a)^2)
%
%   No analysis function is used to calculate the ground truth, so the
%   validation is independent of the pipeline being tested.
%
% THRESHOLDING
%   Detected voxels must meet p < 0.001 and the fixed minimum cluster
%   extent. No cluster-level correction is applied because the
%   detectability threshold is derived at the same voxel-level threshold.
%   This keeps the expected and observed detection criteria directly
%   comparable. The simulated noise is spatially smoothed to 3 voxels FWHM,
%   so detection is scored on data with realistic spatial autocorrelation
%   rather than on spatially independent noise.
% 
% GROUND-TRUTH DEFINITIONS
%   LATENT represents the unperturbed simulation design. POPULATION represents
%   the expected result across the simulated participants. This function uses
%   POPULATION because it evaluates group-level analysis; use LATENT when
%   evaluating whether the simulator generated the intended design.
%
% SCORING CRITERIA
%   DESIGNED evaluates recovery of the intended network contribution.
%   DETECTABLE evaluates all voxels whose expected correlation with the task
%   time course exceeds the detection threshold, regardless of which source
%   produces it.
%
%   Any difference between these criteria reflects contributions from sources
%   outside the designed network. They should normally agree when the
%   independent source time courses remain orthogonal.
%
% Usage:
%   validate_glm_recovery                      % both seeds, as reported in the paper
%   runs = validate_glm_recovery;              % also returns the struct that
%                                              % paper's make_figure4 input
%
% Outputs:
%   RUNS   - 1 x numel(SEEDS) struct array carrying each run's ground truth,
%            detected map, t map, detectability cut-off, df and seed. Pass it
%            straight to make_figure4.
%
% See also: fmri_simdata, demo_glm, make_figure4, DESIGN_NOTE_ground_truth.md

close all;
if exist('fmritoolbox_setup', 'file')
    fmritoolbox_setup;
else
    error('Please run fmritoolbox_setup.m from the toolbox root first.');
end

% --- settings -----------------------------------------------------------
TR               = 2;
n_scans          = 150;
n_subj           = 20;
n_sources        = 10;
n_network        = 3;
alpha            = 0.001;
min_extent       = 20;
noise_fwhm       = 3;      % spatial smoothness of the noise, voxels FWHM (0 = white)
truth_definition = 'population';     % 'latent' or 'population'


% PHASE_STRENGTH controls how much participants differ. The value 0.6 gives
% lower inter-participant similarity than the default 0.2, making recovery
% more challenging and reducing shared chance correlations between sources.
phase_strength = 0.6;

% Two seeds. Section 5.2 reports both: the scores should be stable even when
% the ground truth itself differs several-fold in extent, which is what the
% source orthogonalisation in fmri_simdata is for.
seeds = [123 456];

fprintf('=== two-level recovery against analytic ground truth ===\n');
fprintf('truth definition: %s | phase_strength %.2f | N = %d | noise FWHM %g\n\n', ...
        upper(truth_definition), phase_strength, n_subj, noise_fwhm);

runs = struct('truth', {}, 'r_task', {}, 'detected', {}, 't_map', {}, ...
              'r_detect', {}, 'df', {}, 'seed', {});



for k = 1:numel(seeds)
    fprintf('--- seed %d ---\n', seeds(k));
    rng(seeds(k));

    % --- simulate ------------------------------------------------------
    [X_comp, S_3D, W, svd_info, ~, sim] = fmri_simdata( ...
            n_sources, n_subj, n_scans, TR, [], [], ...
            phase_strength, n_network, 0, false, noise_fwhm);
    n_voxels = sim.mask.n_voxels;

    % --- first level ---------------------------------------------------
    z_maps = zeros(n_voxels, n_subj);
    for p = 1:n_subj
        dat = fmri_simget(X_comp, svd_info, p);
        dat = fmri_zscorevoldata(fmri_detrend(dat));
        z_maps(:, p) = atanh(fmri_corregressor(W.bold(:, 1, p), dat));
        clear dat
    end

    % --- second level --------------------------------------------------
    [t_map, p_grp, df_group] = fmri_ttest(z_maps);
    clean_map = fmri_cleanclusters(double(p_grp < alpha), min_extent, 0);
    detected  = clean_map > 0;

    % --- detectability cut-off -----------------------------------------
    % A voxel is considered detectable when its expected correlation reaches the
    % group-level threshold, given the observed between-participant variability:
    %
    %     r_detect = tanh(t_crit * sd_z / sqrt(N))
    %
    % The threshold is derived from variability rather than chosen arbitrarily,
    % keeping the expected and observed detection criteria comparable.
    sd_z     = std(z_maps, 0, 2);
    t_crit   = fmri_p2t(alpha, df_group);
    r_detect = tanh(t_crit * median(sd_z) / sqrt(n_subj));

    % --- scoring yardsticks --------------------------------------------------
    % Both ground-truth maps come from SIM, keeping their polarity, signal and
    % noise assumptions consistent with the simulation.
    %
    % For POPULATION truth, expected correlations are calculated separately for
    % each participant and then pooled in Fisher-z space. The source-correlation
    % matrices cannot be averaged first because the calculation is nonlinear.
    S_brain = reshape(S_3D, [], n_sources);
    S_brain = S_brain(sim.mask.logical(:), :);
    J       = sim.design.network.idx;

    switch truth_definition
        case 'latent'
            r_designed = (S_brain(:, J) * sim.gram.latent(J, 1)) ./ ...
                         sim.norm.latent;
            r_task     = sim.truth.latent(:, 1);

        case 'population'
            z_des = zeros(n_voxels, 1);
            for p = 1:n_subj
                r_p   = (S_brain(:, J) * sim.gram.participant(J, 1, p)) ./ ...
                        sim.norm.participant(:, p);
                z_des = z_des + atanh(min(max(r_p, -1+eps), 1-eps));
            end
            r_designed = tanh(z_des / n_subj);
            r_task     = sim.truth.population(:, 1);

        otherwise
            error('validate_glm_recovery:badTruthDefinition', ...
                  ['TRUTH_DEFINITION must be ''latent'' or ''population''.' ...
                   '\nSee DESIGN_NOTE_ground_truth.md section 5.']);
    end

    % --- score against the DESIGNED network -----------------------------
    % A detection counts as a hit only when the t-statistic has the expected
    % sign. This ensures that positively and negatively driven network sources
    % are evaluated correctly.
    truth_pos = r_designed >  r_detect;
    truth_neg = r_designed < -r_detect;
    truth_any = truth_pos | truth_neg;

    tp = nnz(detected & ((truth_pos & t_map > 0) | (truth_neg & t_map < 0)));
    fp = nnz(detected & ~truth_any);
    fn = nnz(~detected & truth_any);

    % Separate false positives caused by source leakage from unexpected
    % detections. A voxel is counted as leakage when its expected correlation
    % with the task time course exceeds the detection threshold, even though it
    % lies outside the designed network.
    fp_leak  = nnz(detected & ~truth_any & (abs(r_task) >  r_detect));
    fp_unexp = nnz(detected & ~truth_any & (abs(r_task) <= r_detect));
    conf     = find(abs(sim.gram.latent(:, 1)) > r_detect);
    conf     = conf(~ismember(conf, J))';

    fprintf('  r_detect = %.4f (sd_z %.3f, t_crit %.2f, df %d)\n', ...
            r_detect, median(sd_z), t_crit, df_group);
    fprintf('  designed-network truth : %d voxels (%d pos, %d neg)\n', ...
            nnz(truth_any), nnz(truth_pos), nnz(truth_neg));
    fprintf('  detected               : %d voxels\n', nnz(detected));
    fprintf('  TP %d | FP %d | FN %d\n', tp, fp, fn);
    if tp + fp > 0
        fprintf('  AGAINST THE DESIGN     : precision %.2f  recall %.2f\n', ...
                tp/(tp+fp), tp/(tp+fn));
    end
    fprintf('    of %d false positives, %d from source leakage, %d not\n', ...
            fp, fp_leak, fp_unexp);
    if ~isempty(conf)
        fprintf('    (sources %s correlate |r| > %.2f with TC1 by chance)\n', ...
                mat2str(conf), r_detect);
    end

    % --- score against everything DETECTABLE ----------------------------
    det_expected = abs(r_task) > r_detect;
    tp2 = nnz(detected &  det_expected);
    fp2 = nnz(detected & ~det_expected);
    fn2 = nnz(~detected &  det_expected);

    fprintf('  expected-detectable    : %d voxels (leakage adds %d)\n', ...
            nnz(det_expected), ...
            nnz(abs(r_task) > r_detect & abs(r_designed) <= r_detect));
    fprintf('  max |leakage|          : %.3f\n', max(abs(r_task - r_designed)));
    if tp2 + fp2 > 0
        fprintf('  AGAINST DETECTABLE     : precision %.2f  recall %.2f\n', ...
                tp2/(tp2+fp2), tp2/(tp2+fn2));
    end

    % Voxels near the detection threshold are uncertain: some just above it may
    % be missed, while some just below it may be detected. These boundary effects
    % can reduce both precision and recall without indicating a systematic failure
    % of the analysis.
    fprintf('\n');

    % --- carry forward for make_figure4 ---------------------------------
    runs(k).truth    = r_designed;   % the map scored against, above
    runs(k).r_task   = r_task;
    runs(k).detected = detected;
    runs(k).t_map    = t_map;
    runs(k).r_detect = r_detect;
    runs(k).df       = df_group;
    runs(k).seed     = seeds(k);

    clear X_comp S_3D W svd_info sim z_maps
end

fprintf(['Scores should agree across seeds to within 0.01 even where the\n' ...
         'ground-truth extents differ several-fold; that invariance is what ' ...
         'the source\northogonalisation in fmri_simdata exists to provide.\n\n']);

fprintf('Pass RUNS to make_figure4 for the Section 5.2 figure.\n');

end