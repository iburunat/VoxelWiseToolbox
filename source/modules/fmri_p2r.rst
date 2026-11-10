fmri_p2r
========

Correlation value needed to reach a given p-threshold.

Description
-----------

Answers "how large must r be to count as significant here?". This is the inverse of fmri_r2p, and is what you want for choosing a display threshold or reporting the sensitivity of an analysis.

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

WHY YOU SHOULD NOT PICK A ROUND NUMBER INSTEAD
----------------------------------------------

A threshold like "r > 0.3" means nothing on its own: whether 0.3 is impressive depends entirely on how many independent observations went into it. With 200 clean time points, r = 0.3 is overwhelming. After band-pass filtering, the effective df can fall to 15 or so, and r = 0.3 is then well inside the range of pure noise. Deriving the threshold from the data's own df avoids that.

USE THE EFFECTIVE DF. Filtering and smoothing make neighbouring time points dependent, so the nominal N overstates the information present. fmri_effdf estimates the effective value:

.. code-block:: matlab

   df_eff = fmri_effdf(regressor, one_voxel_timeseries);
   r_crit = fmri_p2r(0.001, df_eff);

RELATION TO fmri_r2p
--------------------

**fmri_r2p(r, df) and fmri_p2r(p, df) are inverses:**

.. code-block:: matlab

   fmri_r2p(fmri_p2r(0.001, 50), 50)  ->  0.001

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

