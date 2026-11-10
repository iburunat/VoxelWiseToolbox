fmri_corregressor
=================

Voxelwise correlation of regressor(s) with fMRI data.

Description
-----------

Correlates one or more regressors with every voxel in the brain, returning a brain map of Pearson r values (or Spearman rho if requested). This is the primary function for univariate GLM-style analysis (e.g. correlating a stimulus time course, a behavioural score, or a seed-region time series with the whole brain).

Usage
-----

.. code-block:: matlab

   c = fmri_corregressor(regr, data)
   c = fmri_corregressor(regr, data, method)

Inputs
------

- **REGR** -- Regressor matrix (T x R): T time points, R regressors. Will be normalised internally. For a single regressor, a (T x 1) vector is accepted.
- **DATA** -- fMRI time series, vectorized (228453 x T). Each row is a voxel, each column a time point.
- **METHOD** -- Correlation method: 'pearson' (default) or 'spearman'. Spearman is rank-based and more robust to outliers but slower.

Outputs
-------

- **C** -- Correlation map (228453 x R). Each column is the r-map for one regressor. Values are clipped to [-1, 1].

Examples
--------

.. code-block:: matlab

   r = fmri_corregressor(stim_ts, data);
   fmri_showslices(r, 1, 2, [0.2 0.6])

   % Spearman (rank-based, outlier-robust)
   r = fmri_corregressor(score, group_data, 'spearman');

   % Multiple regressors at once
   r = fmri_corregressor([regr1, regr2], data);

See Also
--------

:doc:`fmri_corrvoldata <fmri_corrvoldata>` · :doc:`fmri_xcorr <fmri_xcorr>` · :doc:`fmri_r2p <fmri_r2p>` · :doc:`fmri_partcorr <fmri_partcorr>`

