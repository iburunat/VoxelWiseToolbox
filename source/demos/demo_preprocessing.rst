demo_preprocessing
==================

% DEMO_PREPROCESSING  The temporal preprocessing chain, in order

Description
-----------

Simulates one participant and applies each temporal preprocessing step in sequence. The task regressor is detrended, filtered, and smoothed to match the processed data before the correlation map is computed and saved.

**Steps:**

1. Simulate data                     fmri_simdata / fmri_simget
2. Detrend (remove scanner drift)    fmri_detrend
3. Regress motion parameters         fmri_correctmovement
4. Band-pass filter                  fmri_bandpassfilter
5. Apply temporal smoothing          fmri_tempsmooth
6. Apply voxelwise z-scoring         fmri_zscorevoldata
7. Process the regressor, correlate, save and display

Signal quality is reported alongside the chain with fmri_snrt and fmri_cnr.

Two files are written to the current folder: demo_motion_params.txt and demo_data.mat.

This demo and demo_glm are independent and can be run in either order. demo_glm simulates its own 20-participant dataset and does not load this demo's output.

See Also
--------

:doc:`demo_tempsmooth <demo_tempsmooth>` · :doc:`demo_naturalistic <demo_naturalistic>` · :doc:`demo_glm <demo_glm>`

