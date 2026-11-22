% demo_studyforrest — Group analysis of an open naturalistic dataset
%
% Extends the acoustic-power analysis to multiple StudyForrest participants,
% demonstrating group maps, cluster-extent correction, and intersubject
% correlation.
%
% Prerequisites: each subject's run normalised to MNI152 and resampled to the
% toolbox grid (see demo/studyforrest/README.md and sf_to_mni152.sh), plus
% the annotation files.
%
% Treat the group statistics as illustrative. With fifteen subjects, the
% group analysis mainly shows whether the single-subject pattern replicates
% across participants and demonstrates the toolbox functions on real data.
%
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
% list gives a quicker run.
subjects   = {'sub-01','sub-02','sub-03','sub-04','sub-05','sub-06', ...
              'sub-09','sub-10','sub-14','sub-15','sub-16','sub-17', ...
              'sub-18','sub-19','sub-20'};

run_ids    = {'run-1'};

% Which run to keep in full for the smoothness estimate and ISC. Those steps
% need time series rather than a summary map, and keeping every run would
% reintroduce the storage problem the streaming loop avoids. ISC also needs all
% subjects on a common timeline, which one shared run guarantees.
acf_run_idx = 1;

TR         = 2.0;
frame_dur  = 0.04;

% ATLAS FOR THE RESULTS TABLE. 
table_atlas = 1;

% REPRODUCIBILITY. fmri_acfestimate and fmri_csdist are both permutation-based,
% so without a fixed seed the cluster-extent threshold shifts by a few voxels
% between runs on identical data, and clusters near it flip in or out.
rng(2024, 'twister');

p_thresh   = 0.001;      % cluster-forming threshold
fwe_alpha  = 0.05;       % family-wise error rate for cluster extent
n_perm     = 1000;       % permutations for the smoothness/null estimates

% One annotation file per run
annot_files  = cellfun(@(r) fullfile(rootFolder, ...
                 'studyforrest-data-annotations', 'segments', 'avmovie', ...
                 ['conf_audio_' r '_events.tsv']), run_ids, 'UniformOutput', false);

% MOTION REGRESSION. Set false to reproduce the no-motion comparison reported
% in Section 6.2.
regress_motion = true;

if regress_motion
    work_dir = fullfile(rootFolder, 'toolbox_work');
else
    work_dir = fullfile(rootFolder, 'toolbox_work_nomotion');
end

if ~isfolder(work_dir), mkdir(work_dir); end

nSub = numel(subjects);

%% ---- 1. per-subject preprocessing and correlation ------------------------
load standard_brain
n_vox = nnz(br);
r_all = zeros(n_vox, nSub);

% Per-run z-scoring makes concatenated r = sum(T.*r)/sum(T): one run at a time.
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

        % MOTION PARAMETERS
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

        % Motion regression first, then detrend and z-score
        data = fmri_detrend(data);
        data = fmri_zscorevoldata(data);

        % Regressor for THIS run, built from the annotation segment covering it.
        reg_k = local_regressor(annot_files{k}, TR, frame_dur, T);

        % Normalise the regressor per run, just like the data. 
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
fprintf('\n=== group map ===\n');
r_group = tanh(mean(atanh(r_all), 2));

fprintf('  group r range %.3f to %.3f\n', min(r_group), max(r_group));

finite_rows = all(isfinite(r_all), 2);
map_repro   = fmri_corrmat(r_all(finite_rows, :));

% Summary only; MAP_REPRO holds the full matrix for anyone who wants it.
pairs = map_repro(triu(true(nSub), 1));
fprintf('  map reproducibility: mean r = %.3f (%.3f to %.3f, %d pairs)\n', ...
        mean(pairs), min(pairs), max(pairs), numel(pairs));

%% ---- 3. group inference: random-effects one-sample t-test ---------------
% Section 2 answers "what is the average correlation pattern?". This answers the
% more useful question: "where is the effect RELIABLE ACROSS SUBJECTS?"
fprintf('\n=== group inference (random effects) ===\n');

zF = atanh(r_all);                       % effect-size transform, one per subject

[t_map, p_group, df_group] = fmri_ttest(zF);
mean_z = mean(zF, 2);
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
fprintf('\n=== cluster-extent correction ===\n');
fprintf('  estimating spatial smoothness from %d subjects...\n', nSub);
acf = fmri_acfestimate(work_dir, rms_conv, n_perm);


fprintf('  building the null cluster-size distribution (%d permutations)...\n', n_perm);
D = fmri_csdist(acf, p_thresh/2, n_perm);

CSIZE = fmri_csthreshold(D, p_thresh/2, fwe_alpha);
csize = CSIZE{1}(1, 1);
fprintf('  cluster-extent threshold at FWE %.2f: %d voxels\n', fwe_alpha, csize);

% Keep only clusters at or above that extent, positive and negative separately:
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
fprintf('\n=== intersubject correlation ===\n');

isc_map = fmri_isc(work_dir);
fprintf('  ISC range %.3f to %.3f (median %.3f)\n', ...
        min(isc_map), max(isc_map), median(isc_map, 'omitnan'));

%% ---- 6b. figures ---------------------------------------------------------
fprintf('\n---- figures ----\n');

fprintf('  voxel-level critical value: |t| >= %.2f (p < %g, df = %d)\n', ...
        t_crit_disp, p_thresh, df_group);

sig_mask = abs(t_map) >= t_crit_disp;
fprintf('  voxels shown in both maps: %d\n', nnz(sig_mask));

r_masked = r_group;
r_masked(~sig_mask) = NaN;
r_lim = max(abs(r_group(sig_mask)));
if isempty(r_lim) || r_lim == 0, r_lim = 1; end
figure('Name', 'StudyForrest group: effect size');
fmri_showslices(r_masked, 1, [], [-r_lim r_lim], [], [], 1, [], 0);
title(sprintf('Group r-map, N = %d (voxels with |t| >= %.1f)', nSub, t_crit_disp));

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

isc_lim = max(isc_map);
figure('Name', 'StudyForrest group: intersubject correlation');
fmri_showslices(isc_map, 1, [], [0 isc_lim], [], [], 1, 'hot', 0.1);
title(sprintf('Leave-one-out ISC, N = %d (r >= 0.1; illustrative at this N)', nSub));

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