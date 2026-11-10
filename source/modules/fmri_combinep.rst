fmri_combinep
=============

Combine p-values across participants using meta-analytic methods.

Description
-----------

Takes one p-value map per participant and combines the evidence across participants at each voxel using a standard meta-analytic method. This is useful when statistical maps were computed separately for each participant and the question is whether a spatial location shows a consistent effect across the group.

Stouffer's method averages the per-participant z-scores and so has the most power when many participants show a consistent moderate effect. Fisher's statistic is -2\*sum(log(p)), which a single very small p-value can dominate: that makes it the more sensitive of the two when the effect is concentrated in a few participants, and, for the same reason, the more easily driven by one outlier. The median method sacrifices some power for resistance to exactly that.

All three methods are ONE-SIDED and assume the input p-values are one-tailed and consistently directed. Passing two-tailed p-values discards the sign, so a voxel where half the participants show a strong positive effect and half a strong negative one combines to a small p-value with no interpretable direction. Split by sign before combining if direction matters.

Usage
-----

.. code-block:: matlab

   p_combined = fmri_combinep(pvals, method)
   [p_combined, stat] = fmri_combinep(pvals, method)

Inputs
------

- **PVALS** -- 228453 x N matrix of p-values (one map per participant)
- **METHOD** -- combination method (default: 'fisher') 'fisher'   : Fisher combined probability (-2\*sum(log(p))) 'stouffer' : Stouffer z-score method 'median'   : Wilkinson's method on the median order statistic, calibrated against Beta(k, N-k+1). More robust to one aberrant participant than Fisher or Stouffer.

Outputs
-------

- **P_COMBINED** -- 228453 x 1 combined p-value map
- **STAT** -- 228453 x 1 test statistic map (chi2, z, or the median order statistic, according to METHOD)

Examples
--------

.. code-block:: matlab

   p_combined = fmri_combinep(pvals)
   [p, stat]  = fmri_combinep(pvals, 'stouffer')

References
----------

- Fisher (1932). Statistical Methods for Research Workers. Stouffer et al. (1949). The American Soldier.
- Wilkinson, B. (1951). A statistical consideration in psychological research. Psychological Bulletin, 48(2), 156-158.

See Also
--------

:doc:`fmri_fisherz <fmri_fisherz>` · :doc:`fmri_fisherz2p <fmri_fisherz2p>` · :doc:`fmri_r2p <fmri_r2p>`

