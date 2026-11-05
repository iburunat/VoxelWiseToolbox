% demo_studyforrest — Group analysis of an open naturalistic dataset
%
% Runs the acoustic-power analysis across several StudyForrest participants and
% adds the steps a single subject cannot support: a group map, cluster-extent
% correction, and intersubject correlation.
%
% Prerequisites: each subject's run normalised to MNI152 and on the toolbox grid
% (see demo/studyforrest/README.md and sf_to_mni152.sh), plus the annotation
% files.
%
% Do not overread the group statistics. At fifteen subjects a group average is a
% consistency check rather than a strong inferential result, and intersubject
% correlation is at the low end of the sample sizes at which it is normally
% reported. Both are here to show the functions working on real data, and to
% show whether the single-subject pattern replicates - which is stronger
% evidence than any single-subject p-value.

%% ---- configuration -------------------------------------------------------
% Set this to your own StudyForrest download before running.
rootFolder = '';
if isempty(rootFolder) || ~isfolder(rootFolder)
    error('demo_studyforrest:noData', ...
          ['Set ROOTFOLDER at the top of this script to your StudyForrest\n' ...
           'download (the folder containing mni/ and ' ...
           'studyforrest-data-annotations/).\nSee demo/studyforrest/README.md.']);
end

tic

% SUBJECTS. All fifteen participants of the avmovie acquisition. Trimming this
% list gives a quicker run, but the group df falls with it and a short list
% cannot support a corrected result - keep the full cohort for the manuscript.
subjects   = {'sub-01','sub-02','sub-03','sub-04','sub-05','sub-06', ...
              'sub-09','sub-10','sub-14','sub-15','sub-16','sub-17', ...
              'sub-18','sub-19','sub-20'};

% RUNS. Runs are combined by the T-weighted identity described in section 1 -
% no concatenated file is ever created, so adding runs costs time but not disk.
% Peak disk is one run, about 1.6 GB on the MNI 2mm grid.
run_ids    = {'run-1'};

% Which run to keep in full for the smoothness estimate and ISC. Those steps
% need time series rather than a summary map, and keeping every run would
% reintroduce the storage problem the streaming loop avoids. ISC also needs all
% subjects on a common timeline, which one shared run guarantees.
acf_run_idx = 1;

TR         = 2.0;
frame_dur  = 0.04;

% ATLAS FOR THE RESULTS TABLE. AAL (1) labels 77% of the brain mask;
% Harvard-Oxford cortical (3) is a thresholded probabilistic atlas covering only
% 24%, so it returns large "Unlabelled" clusters - a property of the atlas, not
% of the result. Never mix atlases from different families in one table: the
% nomenclatures are not interchangeable.
table_atlas = 1;

% REPRODUCIBILITY. fmri_acfestimate and fmri_csdist are both permutation-based,
% so the extent threshold - and hence which small clusters survive - moves by a
% few voxels between runs of identical data unless the seed is fixed.
rng(2024, 'twister');

p_thresh   = 0.001;      % cluster-forming threshold
fwe_alpha  = 0.05;       % family-wise error rate for cluster extent
n_perm     = 1000;       % permutations for the smoothness/null estimates

% Annotation file per run. The acoustic annotations are published per run, so
% each run's regressor is built from its own segment and no timeline offset is
% needed. If your annotations are instead one file spanning the whole film, this
% is where a per-run offset would be applied.
annot_files  = cellfun(@(r) fullfile(rootFolder, ...
                 'studyforrest-data-annotations', 'segments', 'avmovie', ...
                 ['conf_audio_' r '_events.tsv']), run_ids, 'UniformOutput', false);

% MOTION REGRESSION. Set false to reproduce the no-motion comparison reported
% in Section 6.2. The work directory changes with it, so the two runs cannot
% overwrite each other's per-subject .mat files.
regress_motion = true;

if regress_motion
    work_dir = fullfile(rootFolder, 'toolbox_work');
else
    work_dir = fullfile(rootFolder, 'toolbox_work_nomotion');
end

if ~isfolder(work_dir), mkdir(work_dir); end

nSub = numel(subjects);

%% ---- 1. per-subject preprocessing and correlation ------------------------
% Voxel count from the template rather than a literal, so the allocation cannot
% silently disagree with the data if the reference grid ever changes.
load standard_brain
n_vox = nnz(br);
r_all = zeros(n_vox, nSub);

% MULTI-RUN, WITHOUT EVER CONCATENATING.
%
% The avmovie task is split into several runs, and more timepoints buy
% first-level precision - but storing the concatenated series for fifteen
% subjects is not affordable, and it is not necessary either.
%
% If each run is z-scored SEPARATELY (the correct choice anyway: it removes
% run-specific baseline and drift), then r = (1/T)*sum(x.*y) for z-scored x and
% y, and therefore
%
%     r_concatenated = sum_over_runs( T_run * r_run ) / sum_over_runs( T_run )
%
% exactly, not approximately. So each run is loaded, correlated and discarded,
% accumulating a T-weighted sum. Peak memory is one run's matrix, regardless of
% how many runs are combined.

for s = 1:nSub
    fprintf('\n=== %s ===\n', subjects{s});

    r_acc    = zeros(n_vox, 1);    % T-weighted accumulator
    T_acc    = 0;
    dat_kept = [];                 % the ACF/ISC run, kept in full

    for k = 1:numel(run_ids)
        bold_file = fullfile(rootFolder, 'mni', ...
            sprintf('%s_task-avmovie_%s_MNI.nii.gz', subjects{s}, run_ids{k}));

        if ~exist(bold_file, 'file')
            fprintf('  %s: MISSING, skipped\n', run_ids{k});
            continue
        end

        vol = fmri_readnii(bold_file);

        sz = size(vol);
        if numel(sz) < 3 || ~isequal(sz(1:3), [91 109 91])
            error('demo_studyforrest:badGrid', ...
                ['%s is %s, not the toolbox 91x109x91 grid.\n' ...
                'Re-run sf_to_mni152.sh on it (see demo/studyforrest/README.md).'], ...
                bold_file, mat2str(sz));
        end
        data = fmri_vol2vect(vol);
        clear vol                                   % release the 4D volume
        [~, T] = size(data);

        % MOTION. The aligned release is already motion-CORRECTED (two-stage
        % MCFLIRT), but realignment is not the same as regression: residual
        % motion-related signal survives it, and in naturalistic viewing head
        % motion covaries with the stimulus - people shift at loud moments - so
        % it can induce spurious correlation with an acoustic regressor
        % specifically. MCFLIRT's 6 parameters ship beside the BOLD and are
        % regressed out here. They were estimated in the native space, before
        % the warp to MNI152, which does not matter: they are temporal nuisance
        % regressors, not a spatial object.
        mc_file = fullfile(rootFolder, 'studyforrest-data-aligned', subjects{s}, ...
                   'in_bold3Tp2', sprintf('%s_task-avmovie_%s_bold_mcparams.txt', ...
                                          subjects{s}, run_ids{k}));
        try
            mc = readmatrix(mc_file);
        catch ME
            error('demo_studyforrest:noMotionParams', ...
                  ['Could not read motion parameters for %s %s:\n  %s\n' ...
                   'In a DataLad dataset this file is a broken symlink until ' ...
                   'fetched:\n  datalad get %s\n(%s)'], ...
                  subjects{s}, run_ids{k}, mc_file, mc_file, ME.message);
        end
        if size(mc, 1) ~= T
            error('demo_studyforrest:motionLengthMismatch', ...
                  ['Motion parameters for %s %s have %d rows but the run has ' ...
                   '%d volumes.\nCheck that the parameter file matches this ' ...
                   'run.'], subjects{s}, run_ids{k}, size(mc, 1), T);
        end

        if regress_motion
            data = fmri_correctmovement(data, mc);
        end

        % Motion regression first, then detrend and z-score, which is the order
        % fmri_correctmovement's own help recommends. Both are required for the
        % T-weighted identity above to hold, and both are correct practice
        % independently of it.
        data = fmri_detrend(data);
        data = fmri_zscorevoldata(data);

        % Regressor for THIS run, built from the annotation segment covering it.
        reg_k = local_regressor(annot_files{k}, TR, frame_dur, T);

        % Normalise the regressor per run, just like the data. This makes no
        % difference to a single run's r (correlation ignores scale), but it is
        % needed for the duration-weighted combination above to equal the
        % correlation you would get from concatenating the runs. Without it,
        % runs whose soundtrack swings harder carry more weight than their
        % duration earns.
        reg_k = (reg_k - mean(reg_k)) / std(reg_k);

        r_k    = fmri_corregressor(reg_k, data);
        r_acc  = r_acc + T * r_k;
        T_acc  = T_acc + T;
        fprintf('  %s: %d TRs, r range %.3f to %.3f\n', ...
                run_ids{k}, T, min(r_k), max(r_k));

        % Keep this run's data and regressor for the ACF/ISC steps.
        if k == acf_run_idx
            dat_kept = data;
            rms_conv = reg_k;
        end
        clear data
    end

    if T_acc == 0
        error('demo_studyforrest:noRuns', ...
              'No runs found for %s. Check rootFolder/mni and run_ids.', subjects{s});
    end

    % The ACF_RUN_IDX run is the one kept in full. If it is the missing one
    % while others survive, T_acc is non-zero and nothing above catches it -
    % but an empty .mat would then reach fmri_acfestimate and rms_conv would be
    % undefined in section 4.
    if isempty(dat_kept)
        error('demo_studyforrest:noAcfRun', ...
              ['Run %s is missing for %s. It is the run ACF_RUN_IDX keeps for ' ...
               'the smoothness estimate and ISC, so those steps have no data.'], ...
              run_ids{acf_run_idx}, subjects{s});
    end

    r_all(:, s) = r_acc / T_acc;
    fprintf('  COMBINED over %d TRs: r range %.3f to %.3f\n', ...
            T_acc, min(r_all(:, s)), max(r_all(:, s)));

    % Written for fmri_acfestimate, which reads a directory of .mat files.
    data = dat_kept;                                %#ok<NASGU>
    save(fullfile(work_dir, [subjects{s} '.mat']), 'data', '-v7.3');
    clear data dat_kept
end

%% ---- 2. group map --------------------------------------------------------
% Average in Fisher z rather than averaging r directly: r is bounded and its
% sampling distribution is skewed, so the arithmetic mean of correlations is
% biased toward zero. Transform, average, transform back. The standardising
% sqrt(df-3) that fmri_fisherz applies would cancel in this round trip, so
% atanh/tanh is used directly to make that explicit.
fprintf('\n=== group map ===\n');
r_group = tanh(mean(atanh(r_all), 2));

fprintf('  group r range %.3f to %.3f\n', min(r_group), max(r_group));

% Between-subject MAP REPRODUCIBILITY: how similar are the subjects' spatial
% patterns? At this sample size this matters more than any p-value. It
% correlates the statistic maps across VOXELS, one value per subject pair, and
% is NOT intersubject correlation: ISC correlates the raw TIME SERIES at each
% voxel and yields a map (section 6). The two are not comparable in scale.
%
% fmri_corrmat correlates every column against every column, which is exactly a
% subject-by-subject matrix. Rows with any non-finite value are dropped first.
finite_rows = all(isfinite(r_all), 2);
map_repro   = fmri_corrmat(r_all(finite_rows, :));

% Summary only; MAP_REPRO holds the full matrix for anyone who wants it.
pairs = map_repro(triu(true(nSub), 1));
fprintf('  map reproducibility: mean r = %.3f (%.3f to %.3f, %d pairs)\n', ...
        mean(pairs), min(pairs), max(pairs), numel(pairs));

%% ---- 3. group inference: random-effects one-sample t-test ---------------
% Section 2 answers "what is the average correlation pattern?". This answers the
% more useful question: "where is the effect RELIABLE ACROSS SUBJECTS?"
%
% A fixed-effects test - testing the averaged correlation against the
% within-subject temporal df - treats between-subject variability as
% nonexistent, so it cannot tell an effect present in every subject from one
% driven by a single subject, and it does not generalise beyond the people
% scanned. The random-effects alternative used here is a voxelwise one-sample
% t-test on the Fisher-transformed correlations, with df = N-1 over SUBJECTS.
fprintf('\n=== group inference (random effects) ===\n');

% Plain atanh, NOT fmri_fisherz: this is the variance-stabilising EFFECT-SIZE
% transform. fmri_fisherz returns the standardised test statistic
% atanh(r)*sqrt(df-3), which already divides by a standard error - feeding that
% to a t-test would divide by a standard error twice.
zF = atanh(r_all);                       % effect-size transform, one per subject

% fmri_ttest performs the whole test: mean, between-subject standard error, t,
% two-tailed p, df = N-1, and the guard for voxels constant across subjects.
[t_map, p_group, df_group] = fmri_ttest(zF);

% mean_z is the SIGN source for every positive/negative split below - cluster
% detection, the region tables and the corrected-map figure all use it.
% fmri_ttest returns t, p and df but not the mean, so it is computed here.
mean_z = mean(zF, 2);

% Critical value for the uncorrected voxel threshold, computed once and reused
% for both the inference below and the figures in section 6b, so the two cannot
% drift apart.
t_crit_disp = fmri_p2t(p_thresh, df_group);

fprintf('  one-sample t-test over %d subjects, df = %d\n', nSub, df_group);
fprintf('  t range %.2f to %.2f\n', min(t_map(isfinite(t_map))), ...
        max(t_map(isfinite(t_map))));

mask_unc = p_group < p_thresh;
fprintf('  %d voxels at p < %g uncorrected (%d positive, %d negative)\n', ...
        sum(mask_unc), p_thresh, sum(mask_unc & mean_z > 0), ...
        sum(mask_unc & mean_z < 0));

if nSub < 10
    fprintf(['  NOTE: with %d subjects this test has %d degrees of freedom and\n' ...
             '        very little power. A null result here is uninformative, and\n' ...
             '        surviving voxels should be read as suggestive rather than\n' ...
             '        established.\n'], nSub, df_group);
end

%% ---- 4. cluster-extent correction ---------------------------------------
% The step a single subject could not support. fmri_acfestimate reads the
% per-subject .mat files written above and estimates the spatial
% autocorrelation; fmri_csdist builds the null distribution of cluster sizes
% under that smoothness; fmri_csthreshold reads off the extent needed for
% family-wise error control.
%
% One caveat: the null is calibrated to the smoothness of the within-subject
% correlation maps, while the mask being corrected comes from the across-subject
% t-test. Their smoothness is similar, so this is a reasonable approximation,
% but a fully matched correction would build the null from the t-map itself
% (e.g. by permuting subject signs).
fprintf('\n=== cluster-extent correction ===\n');
fprintf('  estimating spatial smoothness from %d subjects...\n', nSub);
acf = fmri_acfestimate(work_dir, rms_conv, n_perm);

% TAIL CONVENTION - the null and the map must be thresholded alike.
%
% fmri_csdist's SI_ALPHA is the alpha IN EACH TAIL: it thresholds the null maps
% at abs(z) > -norminv(SI_ALPHA). The map is thresholded at p_group < p_thresh,
% and p_group from fmri_ttest is TWO-TAILED. Passing p_thresh straight through
% would build the null at twice the voxel fraction the real map uses, giving
% larger null clusters and an over-strict extent. Halving it matches the two.
%
% The published threshold is the map's, p < 0.001 two-tailed, so the null moves
% to match the map. To report a per-tail threshold instead, drop the /2 here and
% threshold the map at 2*p_thresh.
fprintf('  building the null cluster-size distribution (%d permutations)...\n', n_perm);
D = fmri_csdist(acf, p_thresh/2, n_perm);

% fmri_csthreshold returns a CELL ARRAY {1 x nRegressors}, each cell a
% (nSiAlpha x nCsAlpha) matrix of minimum surviving cluster sizes -- it supports
% several regressors and several alpha levels at once. With one regressor and
% scalar alphas the value wanted is the single element of the first cell.
CSIZE = fmri_csthreshold(D, p_thresh/2, fwe_alpha);
csize = CSIZE{1}(1, 1);
fprintf('  cluster-extent threshold at FWE %.2f: %d voxels\n', fwe_alpha, csize);

% Keep only clusters at or above that extent, positive and negative separately:
% a contiguous cluster spanning both signs would otherwise be counted as one.
[clus_pos, n_pos] = fmri_findclusters(mask_unc & mean_z > 0, csize);
[clus_neg, n_neg] = fmri_findclusters(mask_unc & mean_z < 0, csize);
mask_corr = (clus_pos > 0) | (clus_neg > 0);
fprintf('  surviving clusters: %d positive, %d negative (%d voxels total)\n', ...
        n_pos, n_neg, sum(mask_corr));

if sum(mask_corr) == 0
    fprintf(['  Nothing survives correction. With a small sample and one run ' ...
             'this is a\n  plausible outcome, not necessarily an error.\n']);
end

%% ---- 5. corrected region tables ------------------------------------------
if sum(mask_corr) > 0
    % Report the group t-statistic at each peak, split by the direction of the
    % across-subject effect. The t-map is the inferential quantity; r_group is
    % available too but is descriptive.
    %
    % mask_corr already contains only clusters surviving the corrected extent
    % threshold. Passing csize here, with the same 18-connectivity used above,
    % ensures that the table reports exactly those surviving clusters.
    %
    % CP and CN are kept for the manuscript tables: [cp.n] and [cn.n] give the
    % per-cluster extents reported in Table 5, which fmri_regiontable's printed
    % table does not include.
    fprintf('\nCorrected POSITIVE clusters (group t):\n');
    [cp, ~, ~, ~, ~, ~, T_pos] = ...
        fmri_regiontable(mask_corr & mean_z > 0, t_map, csize, 5, table_atlas);
    disp(T_pos);
    fprintf('\nCorrected NEGATIVE clusters (group t):\n');
    [cn, ~, ~, ~, ~, ~, T_neg] = ...
        fmri_regiontable(mask_corr & mean_z < 0, t_map, csize, 5, table_atlas);
    disp(T_neg);
end

%% ---- 6. intersubject correlation -----------------------------------------
% ISC is the canonical naturalistic measure: which voxels show a time course
% shared across people watching the same film, independent of any model of the
% stimulus. Included to show the function running on real data; at this sample
% size the values are noisy, so treat the map as illustrative.
%
% Streamed from disk rather than assembled in memory: at 15 subjects the full
% array is 228453 x 451 x 15 doubles, about 12 GB. fmri_isc reads the
% per-subject .mat files written in section 1 and forms each leave-one-out
% reference by subtraction from a running sum, so peak memory is one subject.
fprintf('\n=== intersubject correlation ===\n');

isc_map = fmri_isc(work_dir);
fprintf('  ISC range %.3f to %.3f (median %.3f)\n', ...
        min(isc_map), max(isc_map), median(isc_map, 'omitnan'));

% Permutation p-values for ISC are intentionally NOT computed here. fmri_isc
% accepts a permutation count, but only on an in-memory array -- the streaming
% path used above cannot permute, since it never holds more than one subject at
% a time. Each permutation phase-scrambles every subject and recomputes the
% whole-brain ISC, so at ~20 s per pass, 1000 permutations is several hours.

%% ---- 6b. figures ---------------------------------------------------------
% The figures the manuscript reports. Four separate figures, NOT subplots:
% several toolbox viewers manage figure-level state and overwrite one another
% inside subplot panels. Every call passes an explicit THRESHOLD with CLIMITS(1)
% strictly below it - the corrected map is exactly zero outside its clusters,
% which without a threshold renders as a solid painted brain.
fprintf('\n---- figures ----\n');

fprintf('  voxel-level critical value: |t| >= %.2f (p < %g, df = %d)\n', ...
        t_crit_disp, p_thresh, df_group);

% TWO DISPLAY RULES, both of which matter more than they look.
%
%  1. Set the colour limits from the CRITICAL VALUE, not from max|t|. The t
%     distribution is heavy-tailed at low degrees of freedom, so the maximum
%     can be far above the critical value. Scaling to that maximum can compress
%     most significant voxels toward the centre of the colormap.
%  2. Mask the r-map by the t-map's OWN criterion, not by converting t_crit
%     through a typical standard error. That approximation makes the two figures
%     disagree about which voxels count; masking by |t| means they show exactly
%     the same voxels, one as effect size and one as evidence.
sig_mask = abs(t_map) >= t_crit_disp;
fprintf('  voxels shown in both maps: %d\n', nnz(sig_mask));

% Effect size, masked by significance. NaN for non-significant voxels and
% THRESHOLD = 0 (the isfinite rule), so a genuine r of zero would still be drawn.
r_masked = r_group;
r_masked(~sig_mask) = NaN;
r_lim = max(abs(r_group(sig_mask)));
if isempty(r_lim) || r_lim == 0, r_lim = 1; end
figure('Name', 'StudyForrest group: effect size');
fmri_showslices(r_masked, 1, [], [-r_lim r_lim], [], [], 1, [], 0);
title(sprintf('Group r-map, N = %d (voxels with |t| >= %.1f)', nSub, t_crit_disp));

% Inferential map. Colour limits are a small multiple of the critical value,
% NOT max|t| - see rule 1 above.
t_lim = 2 * t_crit_disp;
figure('Name', 'StudyForrest group: t-map');
fmri_showslices(t_map, 1, [], [-t_lim t_lim], [], [], 1, [], t_crit_disp);
title(sprintf('Group t-map (p < %g, |t| >= %.1f, df = %d; scale clipped at %.0f of %.0f)', ...
      p_thresh, t_crit_disp, df_group, t_lim, max(abs(t_map))));

% Cluster-corrected result, signed so it is comparable with the two above.
if sum(mask_corr) > 0
    corr_signed = double(mask_corr & mean_z > 0) - double(mask_corr & mean_z < 0);
    figure('Name', 'StudyForrest group: cluster-corrected');
    fmri_showslices(corr_signed, 1, [], [-1 1], [], [], 1, [], 0.5);
    title(sprintf(['Cluster-corrected (FWE %.2f, >= %d voxels): ' ...
          '%d pos, %d neg clusters'], fwe_alpha, csize, n_pos, n_neg));
else
    fprintf('  (no corrected figure: nothing survived correction)\n');
end

% ISC can be positive or negative. This figure focuses on positively shared
% responses, so the colour limits start at 0 and use a sequential colormap.
% Negative values are therefore not displayed.
isc_lim = max(isc_map);
figure('Name', 'StudyForrest group: intersubject correlation');
fmri_showslices(isc_map, 1, [], [0 isc_lim], [], [], 1, 'hot', 0.1);
title(sprintf('Leave-one-out ISC, N = %d (r >= 0.1; illustrative at this N)', nSub));
% A rim of high ISC around the brain edge is the expected artefact here, not a
% finding: residual motion and registration mismatch are shared across subjects
% because they are driven by the same stimulus-locked head movement, so they
% correlate. Interpret ISC in the interior, and treat an edge-dominated map as
% a sign that motion correction or the brain mask needs attention.

%% ---- 7. resting-state network correspondence -----------------------------
% Which canonical networks does the group map resemble? See rsn_compare_demo for
% why this is reported as a ranking rather than a significance test.
if exist('rsn_compare_demo', 'file')
    rsn_compare_demo(r_group);
end

fprintf('\nDone.\n');

toc

%% ---- local functions -----------------------------------------------------
function reg = local_regressor(annot_file, TR, frame_dur, nTR)
% Build the HRF-convolved acoustic-power regressor for one run.
%
% ORDER MATTERS, AND THE WRONG ORDER FAILS SILENTLY. The annotation is sampled
% per stimulus frame (40 ms), fifty times finer than the TR. The HRF is
% convolved at that native resolution and the result averaged down to the TR
% grid - never the reverse. Downsampling first discards 49 of every 50 samples
% of a rapidly varying envelope and aliases badly, giving a regressor that
% correlates only r ~ 0.2 with the correct one and a weak but entirely
% plausible-looking map.
%
% Detrending happens LAST, on the TR grid, so the regressor receives the same
% linear projection the data received in section 1. fmri_detrend expects voxels
% x time, so the regressor goes in as 1 x T; the elongated-matrix notice is a
% false alarm here and is silenced for this call only.

tbl     = readtable(annot_file, 'FileType', 'text', 'Delimiter', '\t');
rms_raw = tbl.rms(:);
per_TR  = round(TR / frame_dur);

need = nTR * per_TR;
if numel(rms_raw) < need
    error('demo_studyforrest:shortAnnotation', ...
          ['%s has %d frames but %d volumes need %d.\n' ...
           'Check that the annotation file matches this run.'], ...
          annot_file, numel(rms_raw), nTR, need);
end
rms_raw = rms_raw(1:need);

hrf_fine = fmri_doublegamma(0 : frame_dur : 30);
rms_fine = conv(rms_raw, hrf_fine);
rms_fine = rms_fine(1:need);
reg      = mean(reshape(rms_fine, per_TR, nTR), 1)';

ws  = warning('off', 'fmri:ambiguousOrientation');
reg = fmri_detrend(reg')';
warning(ws);
end
