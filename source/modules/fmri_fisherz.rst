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

- **atanh(R)** -- variance-stabilising EFFECT-SIZE transform. Use this to average correlations across subjects or runs, then tanh() the mean to return to r.
- **atanh(R) \* sqrt(DF-3)** -- TEST STATISTIC for the null rho = 0, which this function returns. It already incorporates sample size, so averaging it across subjects would mix effect magnitude with within-subject precision and weight subjects by their run length.

So for pooling subject maps use atanh/tanh directly, and apply this standardisation afterwards at the group level if a statistic is wanted. Note also that a group-level test of whether an effect is reliable ACROSS subjects is a one-sample t-test on the atanh(R) values with N-1 degrees of freedom, not a standardisation by the within-subject DF.

Examples
--------

.. code-block:: matlab

   z = fmri_fisherz(r_map, size(ts,1));            % independent samples
   z = fmri_fisherz(r, fmri_effdf(ts1, ts2));      % autocorrelated

   % Group level: average in z space rather than r space
   zbar = mean(fmri_fisherz(r_maps, N), 2);

See Also
--------

:doc:`fmri_fisherz2p <fmri_fisherz2p>` · :doc:`fmri_r2p <fmri_r2p>` · :doc:`fmri_effdf <fmri_effdf>`

