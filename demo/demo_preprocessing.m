%% DEMO_PREPROCESSING  The temporal preprocessing pipeline
%
% Simulates one participant and applies each temporal preprocessing step in
% sequence. The task regressor receives the corresponding temporal
% operations before the voxelwise correlation map is calculated.
%
% Steps:
%   1. Simulate data                       fmri_simdata / fmri_simget
%   2. Regress motion parameters           fmri_correctmovement
%   3. Detrend (remove scanner drift)      fmri_detrend
%   4. Apply band-pass filtering           fmri_bandpassfilter
%   5. Apply temporal smoothing            fmri_tempsmooth
%   6. Standardise each voxel time series  fmri_zscorevoldata
%   7. Match the regressor to the data     fmri_correctmovement, fmri_detrend
%                                          fmri_bandpassfilter, fmri_tempsmooth
%   8. Correlate with the data             fmri_corregressor
%   9. Display the correlation map         fmri_showslices
%
% This sequence demonstrates the individual preprocessing functions. In a
% formal analysis, motion, drift and temporal filtering should be handled
% consistently within the statistical model.
%
% Voxelwise CNR is reported after preprocessing as a signal-quality summary.
%
% The demo writes demo_motion_params.txt and demo_data.mat to the current
% folder. The MAT file contains the regressors, correlation map and run
% metadata, but not the full preprocessed dataset.
%
% This demo and demo_glm are independent and can be run in either order.
% demo_glm simulates its own 20-participant dataset and does not load this
% demo's output.
%
% See also: demo_tempsmooth, demo_naturalistic, demo_glm

clear;
close all;
if exist('fmritoolbox_setup', 'file')
    fmritoolbox_setup;
else
    error('Please run fmritoolbox_setup.m from the toolbox root directory first.');
end
fprintf('=== VoxelWise Toolbox preprocessing demo ===\n\n');

%% 1. Simulate one participant
% -------------------------------------------------------------------
TR         = 2;      % repetition time (seconds)
n_scans    = 200;    % time points
n_sources  = 10;     % activation blobs
n_network  = 3;      % first 3 blobs share time course 1 (a "network")
rng(42);
outdir = pwd;

fprintf('Step 1: Simulating data with fmri_simdata...\n');
% Full 4D volumes and simulation ground truth are not needed for this demo.
% fmri_simget reconstructs the participant from the compressed representation.
[X_comp, ~, W, svd_info] = fmri_simdata(n_sources, 1, n_scans, TR, ...
                                        [], [], [], n_network, 0, false);

data     = fmri_simget(X_comp, svd_info, 1);   % n_voxels x n_scans
n_voxels = size(data, 1);

% Use the simulated BOLD task time course as the regressor. In a real analysis,
% construct this from the stimulus model and HRF, as shown in demo_naturalistic.
bold_regressor = W.bold(:, 1, 1);

fprintf('  Data: %d voxels x %d scans (TR = %.1f s)\n\n', n_voxels, n_scans, TR);

% Create six example motion parameters: three translations and three
% rotations. No matching motion artefacts were simulated, so this step only
% demonstrates how fmri_correctmovement reads a standard six-column SPM/FSL
% motion file.
motion_params = cumsum(0.05 * randn(n_scans, 6));
motion_file   = fullfile(outdir, 'demo_motion_params.txt');
save(motion_file, 'motion_params', '-ascii');

fprintf('  Motion parameters written to: %s\n\n', motion_file);

%% 2-6. The pipeline
% -------------------------------------------------------------------
% Filtering uses sampling frequency in Hz; smoothing uses seconds.
fs = 1 / TR;                            % 0.5 Hz at TR = 2 s

% CNR remains meaningful after mean removal and z-scoring. tSNR is not shown:
% it is mean/std, and these simulated voxels have no baseline offset.
fprintf('Steps 2-6: preprocessing the fMRI data...\n');

data = fmri_correctmovement(data, motion_file);   % 2. regress motion parameters
data = fmri_detrend(data);                        % 3. remove slow temporal drift
data = fmri_bandpassfilter(data, fs, 0.01, 0.1);  % 4. retain 0.01-0.10 Hz
data = fmri_tempsmooth(data, 3, TR);              % 5. Gaussian sigma = 3 s
data = fmri_zscorevoldata(data);                  % 6. standardise each voxel

c = fmri_cnr(data);
fprintf('  Median CNR: %.2f\n\n', median(c(isfinite(c))));

%% 7. Match the regressor to the data
% -------------------------------------------------------------------
% Apply the same temporal and nuisance-regression steps to the task regressor.
% This produces a partial correlation controlling for the example motion
% parameters.
reg_proc = fmri_correctmovement(bold_regressor(:)', motion_file);
reg_proc = fmri_detrend(reg_proc);
reg_proc = fmri_bandpassfilter(reg_proc, fs, 0.01, 0.1);
reg_proc = fmri_tempsmooth(reg_proc, 3, TR);
reg_proc = reg_proc(:);

%% 8. Correlate and save
% -------------------------------------------------------------------
r_map = fmri_corregressor(reg_proc, data);

demo_data_file = fullfile(outdir, 'demo_data.mat');
save(demo_data_file, 'bold_regressor', 'reg_proc', 'r_map', ...
     'TR', 'n_scans', 'n_voxels');
fprintf('Step 8: Saved %s\n', demo_data_file);
fprintf('  Contains the original and processed regressors and the r-map.\n\n');

%% 9. Display
% -------------------------------------------------------------------
% Use |r| >= 0.3 only as a display threshold, used only to make the map
% easier to read. It is not a statistical significance threshold.
display_threshold = 0.3;

figure('Name', 'Preprocessing: correlation map');
fmri_showslices(r_map, 1, 2, [-0.8 0.8], [], [], 1, [], display_threshold);
title(sprintf('Correlation with filtered regressor (display |r| >= %.1f)', ...
      display_threshold), 'FontSize', 12);

fprintf('=== Preprocessing demo complete ===\n');
fprintf('Regressors and correlation map saved to:\n  %s\n', ...
        demo_data_file);