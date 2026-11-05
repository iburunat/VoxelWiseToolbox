function runs = validate_glm_recovery()
% validate_glm_recovery  Scores the two-level pipeline against analytic ground truth.
%
% Runs the toolbox's two-level analysis on simulated cohorts whose answer is
% known in closed form, and reports precision and recall against that answer.
% This is the test behind Section 5.2 of the toolbox paper; demo_glm shows the
% same workflow without the scoring.
%
% WHY THIS IS NOT CIRCULAR
%   The ground truth is never obtained by running an analysis function. It is
%   computed from the generative parameters themselves - the source weights,
%   the time-course Gram matrix and the noise level - as
%
%       truth(v,k) = (S*G)(v,k) / sqrt( S(v,:)*G*S(v,:)' + (sigma/a)^2 )
%
%   which fmri_simdata returns as sim.truth. The quantity being validated and
%   the quantity validating it share no code path.
%
% WHAT IS AND IS NOT CORRECTED
%   Scoring uses the voxel-level threshold (p < 0.001) plus a fixed minimum
%   cluster extent, not either of the toolbox's cluster-level corrections.
%   That is deliberate: the detectability cut-off below is derived at the same
%   voxel threshold, so "should have been found" and "was found" use the same
%   bar, and what the figures characterise is the ESTIMATION chain. Applying a
%   correction would move both sides at once.
%
% GROUND-TRUTH DEFINITION
%   fmri_simdata returns two and does not choose between them:
%
%     latent      the base design, before participant perturbation. Answers
%                 "did the simulator generate what was asked for?".
%     population  the expected value of the statistic a group test actually
%                 computes, pooled across the participants simulated. Answers
%                 "did the analysis recover the effect in this cohort?".
%
%   POPULATION is used here, because this validates an ANALYSIS. The detection
%   threshold is derived from the between-participant sampling distribution,
%   and scoring a sampling-based threshold against a variability-free latent
%   effect would put the two sides on different footings. Set TRUTH_DEFINITION
%   to 'latent' to validate the simulator instead; the difference between them
%   is the attenuation that participant perturbation induces.
%
% TWO YARDSTICKS, DELIBERATELY
%   DESIGNED    the designed network's contribution alone. Asks whether the
%               analysis found the network that was asked for.
%   DETECTABLE  everything whose expected correlation with the task time
%               course clears the threshold, whatever source produces it. A
%               voxel genuinely correlating with the task regressor through
%               chance correlation between sources SHOULD be detected;
%               scoring it as an error measures the simulator's luck rather
%               than the method's accuracy.
%
%   Both are reported, and the gap between them is source leakage. With the
%   orthogonalisation fmri_simdata applies, that gap is normally zero and the
%   two yardsticks agree exactly - which is itself worth seeing, because it
%   says the chance correlations the DETECTABLE yardstick exists to absorb
%   are not there to absorb. A run where they diverge means the
%   orthogonalisation has stopped doing its job.
%
% Usage:
%   validate_glm_recovery                      % both seeds, as reported in the paper
%   runs = validate_glm_recovery;              % also returns the struct that
%                                          % make_figure5 takes
%
% Outputs:
%   RUNS   - 1 x numel(SEEDS) struct array carrying each run's ground truth,
%            detected map, t map, detectability cut-off, df and seed. Pass it
%            straight to make_figure5.
%
% See also: fmri_simdata, demo_glm, make_figure5, DESIGN_NOTE_ground_truth.md

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
truth_definition = 'population';     % 'latent' or 'population'

% PHASE_STRENGTH controls inter-participant similarity by FFT phase
% perturbation: 0 = identical participants, 1 = fully decorrelated. The
% simulator's default of 0.2 gives inter-participant r ~ 0.98, which is
% unrealistically clean and has a concrete consequence: because every
% participant is a mild perturbation of ONE base set of time courses, any
% chance correlation between sources is reproduced in all of them, survives
% group averaging and appears as a highly significant cluster. 0.6 gives a
% mean pairwise correlation near 0.81, which decorrelates the background
% sources and makes this a harder test than the default would be.
phase_strength = 0.6;

% Two seeds. Section 5.2 reports both: the scores should be stable even when
% the ground truth itself differs several-fold in extent, which is what the
% source orthogonalisation in fmri_simdata is for.
seeds = [123 456];

fprintf('=== two-level recovery against analytic ground truth ===\n');
fprintf('truth definition: %s | phase_strength %.2f | N = %d\n\n', ...
        upper(truth_definition), phase_strength, n_subj);

runs = struct('truth', {}, 'r_task', {}, 'detected', {}, 't_map', {}, ...
              'r_detect', {}, 'df', {}, 'seed', {});

for k = 1:numel(seeds)
    fprintf('--- seed %d ---\n', seeds(k));
    rng(seeds(k));

    % --- simulate ------------------------------------------------------
    [X_comp, S_3D, W, svd_info, ~, sim] = fmri_simdata( ...
            n_sources, n_subj, n_scans, TR, [], [], ...
            phase_strength, n_network, 0, false);
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

    % --- detectability cut-off, derived rather than guessed -------------
    % A voxel is detectable when its expected correlation would clear the
    % group threshold given the observed between-participant variability:
    %     t = atanh(r)/(sd_z/sqrt(N))  =>  r_detect = tanh(t_crit*sd_z/sqrt(N))
    % This uses only the NOISE level, never the effect, so it is a power
    % calculation rather than a circular fit. Scoring against a fixed,
    % arbitrary cut-off would measure the choice of cut-off instead.
    sd_z     = std(z_maps, 0, 2);
    t_crit   = fmri_p2t(alpha, df_group);
    r_detect = tanh(t_crit * median(sd_z) / sqrt(n_subj));

    % --- the two yardsticks --------------------------------------------
    % Both come from the simulator via sim, so the polarity rule, the
    % signal and noise constants and the expected-correlation formula are
    % never reproduced here. Those were silent couplings: if the simulator
    % changed, a test that rebuilt them broke without warning.
    %
    % Under the POPULATION definition both are evaluated per participant and
    % pooled in atanh space afterwards. They cannot be computed from a
    % participant-averaged Gram: r_p is a nonlinear function of G^(p), so
    % f(pooled G) ~= pooled f(G).
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
    % Sign-aware: a surviving voxel counts as a hit only if the t statistic
    % matches the ground truth's polarity there. fmri_simdata does not give
    % every network blob the same sign - the rule lives in the simulator and
    % is reported as sim.design.network.sign - so treating the network as one
    % undifferentiated mask would make the anti-correlated blob look like a
    % false positive when it is a correct detection with the opposite sign.
    truth_pos = r_designed >  r_detect;
    truth_neg = r_designed < -r_detect;
    truth_any = truth_pos | truth_neg;

    tp = nnz(detected & ((truth_pos & t_map > 0) | (truth_neg & t_map < 0)));
    fp = nnz(detected & ~truth_any);
    fn = nnz(~detected & truth_any);

    % Which false positives are the analysis's fault? A voxel whose expected
    % correlation with the task time course clears the threshold is one a
    % correct analysis should find, whichever source produces it. r_task
    % answers this directly - no confound mask, no second threshold, no loop
    % over sources. Printed unconditionally, including when it is zero: a
    % figure that only appears when leakage exists cannot be compared across
    % runs.
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

    % The false positives and false negatives are one phenomenon seen from
    % two sides. Truth is defined AT the test's critical threshold, so voxels
    % sitting near r_detect have roughly 50% power: about half of those just
    % above it are missed and about half of those just below are detected.
    % Both sets lie at the source margins. A recall of exactly 1.00 is
    % therefore not attainable by construction, and the precision shortfall
    % has the same origin - neither is a sensitivity failure.
    fprintf('\n');

    % --- carry forward for make_figure5 ---------------------------------
    runs(k).truth    = r_designed;   % the map scored against, above
    runs(k).r_task   = r_task;
    runs(k).detected = detected;
    runs(k).t_map    = t_map;
    runs(k).r_detect = r_detect;
    runs(k).df       = df_group;
    runs(k).seed     = seeds(k);

    clear X_comp S_3D W svd_info sim z_maps
end

fprintf(['Scores should agree across seeds to two decimal places even ' ...
         'where the\nground-truth extents differ several-fold; that ' ...
         'invariance is what the source\northogonalisation in fmri_simdata ' ...
         'exists to provide.\n\n']);
fprintf('Pass RUNS to make_figure5 for the Section 5.2 figure.\n');
end
