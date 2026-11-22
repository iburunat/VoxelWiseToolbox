fmri_fisherz
============

Standardised Fisher z-score from a Pearson correlation.

Usage
-----

.. code-block:: matlab

   z = fmri_fisherz(r, df)

Inputs
------

- **R** -- Correlation coefficient(s), any shape. Values in [-1, 1].
- **DF** -- Effective sample size, NOT N-2. For independent samples this is the number of observations N; for autocorrelated time series use fmri_effdf, which returns N when there is no autocorrelation and less when there is. The standardisation is sqrt(DF-3), the usual Fisher form.

Outputs
-------

- **Z** -- Standardised z-score(s), same shape as R.

IMPORTANT: this is the standardised z STATISTIC, atanh(R) \* sqrt(DF-3), not the plain Fisher transform atanh(R). The two serve different purposes and are not interchangeable:

- **atanh(R)** -- Variance-stabilising transform used to combine correlations across participants or runs. Average the transformed values, then apply tanh() to return to the correlation scale.
- **atanh(R)\*sqrt(DF-3)** -- Test statistic for the null hypothesis rho = 0, returned by this function. Do not average it across participants because it combines effect size with within-participant sample size.

For group analysis, apply a one-sample t-test to the participant-level atanh(R) values. Its degrees of freedom are the number of participants minus one, not the within-participant DF.

Examples
--------

.. code-block:: matlab

   z = fmri_fisherz(r_map, size(ts,1));            % independent samples
   z = fmri_fisherz(r, fmri_effdf(ts1, ts2));      % autocorrelated

   % Group level: pool with the plain transform, NOT this standardisation
   zbar = mean(atanh(r_maps), 2);
   rbar = tanh(zbar);

See Also
--------

:doc:`fmri_fisherz2p <fmri_fisherz2p>` · :doc:`fmri_r2p <fmri_r2p>` · :doc:`fmri_effdf <fmri_effdf>`

