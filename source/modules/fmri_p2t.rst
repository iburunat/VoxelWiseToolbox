fmri_p2t
========

t-value needed to reach a given p-threshold.

Description
-----------

Answers "how large must t be to count as significant here?". Use it to set a display threshold that matches the threshold the analysis actually used - a figure drawn at a looser value shows voxels the analysis did not call significant, which reads as noise scattered over the result.

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

   Drawing a df = 2 map at |t| >= 2 shows roughly 9% of the brain by chance.

Note on colour limits: scale to a small multiple of T_CRIT rather than to max(abs(t_map)). At low df the t distribution is heavy-tailed, so the maximum is an outlier and scaling to it compresses every significant voxel to the middle of the colormap - the map then looks empty.

Examples
--------

.. code-block:: matlab

   [t_map, p_map, df] = fmri_ttest(z_maps);
   t_crit = fmri_p2t(0.001, df);
   fmri_showslices(t_map, 1, 2, [-3*t_crit 3*t_crit], [], [], 1, [], t_crit);

See Also
--------

:doc:`fmri_p2r <fmri_p2r>` · :doc:`fmri_r2p <fmri_r2p>` · :doc:`fmri_ttest <fmri_ttest>` · :doc:`fmri_effdf <fmri_effdf>`

