demo_preprocessing
==================

% DEMO_PREPROCESSING  The temporal preprocessing pipeline

Description
-----------

Simulates one participant and applies each temporal preprocessing step in sequence. The task regressor receives the corresponding temporal operations before the voxelwise correlation map is calculated.

**Steps:**

1. Simulate data                       fmri_simdata / fmri_simget
2. Regress motion parameters           fmri_correctmovement
3. Detrend (remove scanner drift)      fmri_detrend
4. Apply band-pass filtering           fmri_bandpassfilter
5. Apply temporal smoothing            fmri_tempsmooth
6. Standardise each voxel time series  fmri_zscorevoldata
7. Match the regressor to the data     fmri_correctmovement, fmri_detrend fmri_bandpassfilter, fmri_tempsmooth
8. Correlate with the data             fmri_corregressor
9. Display the correlation map         fmri_showslices

This sequence demonstrates the individual preprocessing functions. In a formal analysis, motion, drift and temporal filtering should be handled consistently within the statistical model.

Voxelwise CNR is reported after preprocessing as a signal-quality summary.

The demo writes demo_motion_params.txt and demo_data.mat to the current folder. The MAT file contains the regressors, correlation map and run metadata, but not the full preprocessed dataset.

This demo and demo_glm are independent and can be run in either order. demo_glm simulates its own 20-participant dataset and does not load this demo's output.

See Also
--------

:doc:`demo_tempsmooth <demo_tempsmooth>` · :doc:`demo_naturalistic <demo_naturalistic>` · :doc:`demo_glm <demo_glm>`

