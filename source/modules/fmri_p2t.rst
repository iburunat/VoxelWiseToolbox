fmri_p2t
========

t-value corresponding to a given p-threshold.

Description
-----------

Returns the t-value corresponding to a given p-value and degrees of freedom. This can be used to match a figure's display threshold to the significance threshold used in the analysis, avoiding the display of voxels that do not meet that threshold.

Usage
-----

.. code-block:: matlab

   t = fmri_p2t(p, df)
   t = fmri_p2t(p, df, tail)

Inputs
------

- **P** -- Desired p-value threshold, e.g. 0.001. May be a vector.
- **DF** -- Degrees of freedom. For a group analysis over N participants this is N-1, NOT the number of time points - the observations being tested are participants.
- **TAIL** -- 2 for two-tailed (default), 1 for one-tailed.

Outputs
-------

- **T** -- The t magnitude at which p equals the requested value.

SMALL SAMPLES ARE THE CASE TO WATCH
-----------------------------------

Critical t rises steeply as df falls, and the round numbers that look reasonable are badly wrong at small N:

.. code-block:: matlab

   df = 100 :  p < 0.001 needs |t| >=  3.39
   df =  14 :  p < 0.001 needs |t| >=  4.14
   df =   7 :  p < 0.001 needs |t| >=  5.41
   df =   2 :  p < 0.001 needs |t| >= 31.60

.. code-block:: matlab

   Drawing a df = 2 map at |t| >= 2 shows roughly 18% of the brain by chance.

Note on colour limits: use a small multiple of T_CRIT instead of the largest absolute t-value in the map. At low degrees of freedom, a few very large t-values can stretch the colour scale, making the remaining significant values difficult to distinguish.

Examples
--------

.. code-block:: matlab

   [t_map, p_map, df] = fmri_ttest(z_maps);
   t_crit = fmri_p2t(0.001, df);
   fmri_showslices(t_map, 1, 2, [-3*t_crit 3*t_crit], [], [], 1, [], t_crit);

See Also
--------

:doc:`fmri_p2r <fmri_p2r>` · :doc:`fmri_r2p <fmri_r2p>` · :doc:`fmri_ttest <fmri_ttest>` · :doc:`fmri_effdf <fmri_effdf>`

