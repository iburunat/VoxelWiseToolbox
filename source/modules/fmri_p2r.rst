fmri_p2r
========

Correlation magnitude corresponding to a given p-threshold.

Description
-----------

Returns the correlation magnitude associated with the specified p-value, degrees of freedom and tail setting. This is the inverse of fmri_r2p and can be used to choose a display threshold or report the sensitivity of an analysis.

Usage
-----

.. code-block:: matlab

   r = fmri_p2r(p, df)
   r = fmri_p2r(p, df, tail)

Inputs
------

- **P** -- Desired p-value threshold, e.g. 0.001. May be a vector.
- **DF** -- Degrees of freedom. For a single time series this is the EFFECTIVE df from fmri_effdf, not the number of time points - see below.
- **TAIL** -- 2 for two-tailed (default), 1 for one-tailed.

Outputs
-------

- **R** -- The correlation magnitude at which p equals the requested value.

WHY THE THRESHOLD DEPENDS ON DF
-------------------------------

The significance of a correlation depends on the number of independent observations. Therefore, a fixed threshold such as r > 0.3 does not correspond to the same p-value across datasets. Deriving the threshold from the relevant degrees of freedom gives the correlation associated with the requested significance level.

For time-series data, use the effective degrees of freedom. Filtering and smoothing typically introduce temporal dependence, so the nominal number of time points may overestimate the independent information in the data:

.. code-block:: matlab

   df_eff = fmri_effdf(regressor, one_voxel_timeseries);
   r_crit = fmri_p2r(0.001, df_eff);

RELATION TO FMRI_R2P
--------------------

fmri_p2r converts a p-value to its corresponding correlation threshold, while fmri_r2p performs the reverse conversion:

.. code-block:: matlab

   fmri_r2p(fmri_p2r(0.001, 50), 50)  % returns 0.001

Examples
--------

.. code-block:: matlab

   r_crit = fmri_p2r(0.001, 148);           % p < 0.001, two-tailed
   fmri_showslices(r_map, 1, 2, [0 0.8], [], [], 1, 'hot', r_crit);

   % Threshold matched to the data's real information content
   df_eff = fmri_effdf(reg, data(1,:)');
   fmri_showslices(r_map, 1, 2, [0 0.8], [], [], 1, 'hot', fmri_p2r(0.001, df_eff));

See Also
--------

:doc:`fmri_r2p <fmri_r2p>` · :doc:`fmri_p2t <fmri_p2t>` · :doc:`fmri_effdf <fmri_effdf>` · :doc:`fmri_fisherz <fmri_fisherz>` · :doc:`fmri_ttest <fmri_ttest>`

