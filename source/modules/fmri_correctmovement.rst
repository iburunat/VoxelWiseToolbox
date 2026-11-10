fmri_correctmovement
====================

Removes motion artefacts from fMRI data via regression.

Description
-----------

Regresses motion parameters out of the fMRI time series using ordinary least squares. The motion regressors are z-scored before regression for numerical stability, and an intercept is included so that the residuals retain the mean signal. The residuals are the data with motion-related variance removed.

Usage
-----

.. code-block:: matlab

   residual = fmri_correctmovement(data, movementfilepath)

Inputs
------

- **DATA** -- fMRI time series, in any accepted layout: 228453 x T          canonical (voxels x time) 91 x 109 x 91 x T   volume
- **MOVEMENTFILEPATH** -- Path to the motion parameter file, or a numeric T x P matrix of motion regressors. The file should contain a numeric matrix with one row per scan and one column per regressor (typically 6: three translations and three rotations).

Outputs
-------

- **RESIDUAL** -- Motion-corrected data, in the same layout as DATA.

Examples
--------

.. code-block:: matlab

   data = fmri_correctmovement(data, 'sub01_motion.txt');
   data = fmri_correctmovement(data, 'rp_asub-01_task-music_bold.txt');
   data = fmri_correctmovement(data, rp);        % regressors already loaded

Notes
-----

Motion parameter files are typically produced by SPM (rp\_\*.txt) or FSL (\*.par). Both 6-column rigid-body sets and extended sets (such as the 24-parameter Friston expansion) are accepted; every column of the file is used as a regressor.

In a preprocessing pipeline, motion regression is normally applied before detrending and temporal smoothing.

See Also
--------

:doc:`fmri_detrend <fmri_detrend>` · :doc:`fmri_tempsmooth <fmri_tempsmooth>` · :doc:`fmri_bandpassfilter <fmri_bandpassfilter>` · :doc:`fmri_readnii <fmri_readnii>`

