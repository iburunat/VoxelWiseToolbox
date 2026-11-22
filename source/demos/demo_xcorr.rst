demo_xcorr
==========

% DEMO_XCORR  Voxelwise lagged cross-correlation with fMRI data

Description
-----------

Demonstrates voxelwise cross-correlation between an HRF-convolved regressor and simulated fMRI data across temporal lags. Three regions are assigned known lags, allowing the recovered peak correlations and lags to be checked.

**Steps:**

1. Generate an HRF-convolved block-design regressor
2. Simulate three regions with known temporal lags
3. Compute voxelwise cross-correlations across lags
4. Extract and validate the peak correlation and lag
5. Display the correlation and lag maps

**Functions demonstrated:**

fmri_xcorr, fmri_doublegamma, fmri_regionmask, fmri_effdf, fmri_p2r, fmri_showslices

See Also
--------

:doc:`fmri_xcorr <../modules/fmri_xcorr>` · :doc:`fmri_corregressor <../modules/fmri_corregressor>` · :doc:`fmri_doublegamma <../modules/fmri_doublegamma>` · :doc:`fmri_partcorr <../modules/fmri_partcorr>`

