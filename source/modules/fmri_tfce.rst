fmri_tfce
=========

Threshold-free cluster enhancement (TFCE) of a statistical map.

Description
-----------

Computes a TFCE score at each voxel by combining signal height with the spatial extent of the cluster containing it across a range of thresholds. This avoids selecting a single cluster-forming threshold. High scores indicate strong values supported by spatially extensive signal.

**The TFCE statistic is defined as:**

.. code-block:: matlab

   TFCE(v) = integral[ e(h)^E * h^H dh ]

where e(h) is the cluster extent at threshold h, E weights cluster extent (default 0.5), and H weights peak height (default 2).

Usage
-----

.. code-block:: matlab

   tfce = fmri_tfce(data)
   tfce = fmri_tfce(data, E, H, N)

Inputs
------

- **DATA** -- Statistical map, vectorized (228453 x 1). Must be non-negative; run separately for positive and negative tails if needed.
- **E** -- Extent exponent. Default: 0.5 (Smith & Nichols recommendation).
- **H** -- Height exponent. Default: 2   (Smith & Nichols recommendation).
- **N** -- Number of threshold bins for numerical integration. Default: 50. More bins = more accurate but slower.

Outputs
-------

- **TFCE** -- TFCE map, vectorized (228453 x 1)

Examples
--------

.. code-block:: matlab

   % Positive tail
   tfce_pos = fmri_tfce(max(zmap, 0));
   % Negative tail
   tfce_neg = fmri_tfce(max(-zmap, 0));
   % Visualize
   fmri_showslices(tfce_pos, 1, 2, [0 max(tfce_pos)])

Notes
-----

**Implementation notes (relative to Smith & Nichols, 2009):**

- Form, exponents and lower limit follow Eq. 1 with h0 = 0 and the recommended E = 0.5, H = 2.
- The integral is evaluated by the midpoint rule over N threshold bins.
- Clusters are formed with 18-connectivity, matching the rest of this toolbox (fmri_findclusters, fmri_cleanclusters, fmri_csdist). FSL's TFCE uses 26-connectivity, so TFCE scores here will not match FSL voxel for voxel. This does not affect validity: the connectivity is part of the statistic's definition and only needs to be consistent between the observed map and any permutation null built from it.
- The raw TFCE map is not a p-value. To obtain inference, build a null distribution of the maximum TFCE score over sign-flips or phase-scrambled regressors and threshold against it.

References
----------

- Smith, S.M. & Nichols, T.E. (2009). Threshold-free cluster enhancement: addressing problems of smoothing, threshold dependence and localisation in cluster inference. NeuroImage, 44(1), 83-98.

See Also
--------

:doc:`fmri_cleanclusters <fmri_cleanclusters>` · :doc:`fmri_csthreshold <fmri_csthreshold>` · :doc:`fmri_findclusters <fmri_findclusters>`

