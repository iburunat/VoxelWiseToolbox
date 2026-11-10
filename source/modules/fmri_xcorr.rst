fmri_xcorr
==========

Voxelwise lagged cross-correlation between regressor and fMRI data.

Description
-----------

Correlates a regressor with every brain voxel across a range of time lags, returning a (228453 x 2\*maxlag+1) correlation matrix. Column k corresponds to a temporal lag of (-maxlag + k - 1) scans. Useful for detecting haemodynamic delays or testing the HRF shape voxelwise.

Usage
-----

.. code-block:: matlab

   c = fmri_xcorr(regr, data, maxlag)

Inputs
------

- **REGR** -- Regressor (T x 1) or (T x R) for R regressors.
- **DATA** -- fMRI time series, vectorized (228453 x T).
- **MAXLAG** -- Maximum lag in scans (integer). The function computes correlations for lags in [-maxlag, +maxlag].

Outputs
-------

- **C** -- Cross-correlation matrix (228453 x (2\*maxlag+1)). Column (maxlag+1) is the zero-lag correlation (= fmri_corregressor).

Examples
--------

.. code-block:: matlab

   c = fmri_xcorr(stim_ts, data, 5);
   [peak_r, peak_lag] = max(c, [], 2);
   peak_lag = peak_lag - (maxlag+1);     % convert to signed lag
   fmri_showslices(peak_lag .* (peak_r > 0.3), 1, 2, [-5 5])

See Also
--------

:doc:`fmri_corregressor <fmri_corregressor>` · :doc:`fmri_doublegamma <fmri_doublegamma>` · :doc:`fmri_corrvoldata <fmri_corrvoldata>`

