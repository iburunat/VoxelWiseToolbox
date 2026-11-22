fmri_r2p
========

Converts Pearson correlation coefficient(s) to p-values.

Description
-----------

Transforms a correlation coefficient r to a p-value using the Fisher z-transformation followed by normal-distribution inference. Supports one-tailed and two-tailed tests, and handles both scalar and map inputs.

Usage
-----

.. code-block:: matlab

   [p_pos, p_neg] = fmri_r2p(r, df)
   [p_pos, p_neg] = fmri_r2p(r, df, tail)

Inputs
------

- **R** -- Correlation coefficient(s). Scalar, vector, or brain map (228453 x 1). Values should be in [-1, 1].
- **DF** -- Effective sample size, NOT N-2. For independent samples pass the number of observations N; the function applies the usual Fisher standardisation sqrt(DF-3) internally. For autocorrelated time series use fmri_effdf, which returns N when there is no autocorrelation and less when there is. Passing N-2 here would make the test conservative.
- **TAIL** -- Test direction: 2  = two-tailed (default) 1  = one-tailed, positive (r > 0) -1  = one-tailed, negative (r < 0)

Outputs
-------

- **P_POS** -- When TAIL = 2, the two-tailed p-value (identical to P_NEG; a two-tailed test has one p-value, which depends on \|r\| only, so correlations of either sign are treated symmetrically). When TAIL = 1, the one-tailed p-value for r > 0. Empty [] when TAIL = -1.
- **P_NEG** -- When TAIL = 2, the same two-tailed p-value as P_POS. When TAIL = -1, the one-tailed p-value for r < 0. Empty [] when TAIL = 1.

All returned p-values lie in [0, 1]. Thresholding a signed statistical map should use TAIL = 2 and the p-value alone; additionally requiring r > 0 would turn it into a one-tailed test at half the stated alpha.

Examples
--------

.. code-block:: matlab

   % Whole-brain significance map (two-tailed)
   r_map = fmri_corregressor(regressor, data);
   df    = size(data, 2);          % N, not N-2; see CHOOSING DF below
   [p_pos, p_neg] = fmri_r2p(r_map, df);

   % Single correlation with autocorrelation-corrected df (positive)
   df = fmri_effdf(ts1, ts2);
   r  = fmri_corrmat(ts1, ts2);
   p  = fmri_r2p(r, df, 1);

   % One-tailed test for negative correlations
   [~, p_neg] = fmri_r2p(r_map, df, -1);

   % Threshold map at p < 0.001 (positive correlations)
   sig_map = p_pos < 0.001;
   fmri_showslices(sig_map, 1, 2)

CHOOSING DF
-----------

In this function, DF represents the effective number of observations, not the conventional N-2 degrees of freedom of a correlation t-test. The Fisher transformation already applies the adjustment sqrt(DF-3), so do not subtract an additional 2.

FIRST LEVEL - correlation across time points

Temporal autocorrelation reduces the effective number of independent observations. Estimate it with fmri_effdf:

.. code-block:: matlab

   df = fmri_effdf(regressor, data(v,:)');
   p  = fmri_r2p(r, df);

GROUP LEVEL - correlation across participants

When participants are treated as independent observations, use their number directly:

.. code-block:: matlab

   df = size(participant_maps, 2);        % N, not N-2
   p  = fmri_r2p(rho, df);

PARTIAL CORRELATION - C confounds removed

Reduce the number of observations by the number of confounds:

- **df = N** -- C; p  = fmri_r2p(rho, df);

In summary, use the effective number of observations after accounting for temporal dependence and any confound regressors. fmri_r2p applies the Fisher sqrt(DF-3) adjustment internally.

See Also
--------

:doc:`fmri_fisherz <fmri_fisherz>` · :doc:`fmri_fisherz2p <fmri_fisherz2p>` · :doc:`fmri_effdf <fmri_effdf>` · :doc:`fmri_cleanclusters <fmri_cleanclusters>` · :doc:`fmri_tfce <fmri_tfce>`

