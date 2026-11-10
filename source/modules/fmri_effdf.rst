fmri_effdf
==========

Estimates effective degrees of freedom for correlated time series.

Description
-----------

Estimates the effective degrees of freedom (df) for the correlation between two time series, accounting for temporal autocorrelation in both signals. Temporal autocorrelation inflates Type I error when using the nominal sample size; this function provides a corrected value suitable for significance testing via fmri_r2p.

**The effective df is computed using the formula:**

.. code-block:: matlab

   1/df_eff = 1/N + (2/N) * sum_{k=1}^{N/5} AC1(k) * AC2(k)

where AC1 and AC2 are the normalised autocorrelation functions of ts1 and ts2 respectively, evaluated up to lag N/5.

The maximal lag follows Pyper & Peterman (1998). Their simulations used N/4 as a baseline but concluded that N/5 gave "the best combination of accuracy and precision" in error rates, which is their stated recommendation and what Alluri et al. (2012) implement. Simulation here reproduces that: across AR(0) to AR(0.9) the mean estimate is unchanged (within 0.2%) while the standard deviation is consistently lower.

Note on the test statistic. Pyper & Peterman pair this df estimate with a t-test on r using N\*-2 degrees of freedom. The toolbox instead follows Alluri et al., who use the same df estimate inside a Fisher z framework: z = atanh(r)\*sqrt(df-3), tested against the standard normal (see fmri_fisherz and fmri_r2p). Both are standard tests for a correlation; the Fisher form is variance-stabilising and averages sensibly across participants, which suits voxelwise maps. The df estimate itself is unchanged from Pyper & Peterman.

Usage
-----

.. code-block:: matlab

   df = fmri_effdf(ts1, ts2)

Inputs
------

- **TS1, TS2** -- Time series vectors (N x 1) or (1 x N). Must be the same length.

Outputs
-------

- **DF** -- Effective sample size (scalar). Equals N when neither series is autocorrelated, and falls below N as autocorrelation increases. Pass this straight to fmri_r2p or fmri_fisherz, which expect an effective sample size rather than N-2.

Examples
--------

.. code-block:: matlab

   % Compute effective df before testing a correlation
   r   = fmri_corrmat(ts1, ts2);
   df  = fmri_effdf(ts1, ts2);
   p   = fmri_r2p(r, df);

References
----------

- Pyper, B.J. & Peterman, R.M. (1998). Comparison of methods to account for autocorrelation in correlation analyses of fish data. Canadian Journal of Fisheries and Aquatic Sciences, 55(9), 2127-2140.
- Alluri, V., Toiviainen, P., Jaaskelainen, I.P., Glerean, E., Sams, M. &
- Brattico, E. (2012). Large-scale brain networks emerge from dynamic processing of musical timbre, key and rhythm. NeuroImage, 59(4), 3677-3689. Applies this estimator to continuous acoustic features, with the N/5 maximal lag.

See Also
--------

:doc:`fmri_r2p <fmri_r2p>` · :doc:`fmri_fisherz <fmri_fisherz>` · :doc:`fmri_corregressor <fmri_corregressor>`

