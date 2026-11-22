demo_tfce
=========

% DEMO_TFCE  Threshold-free cluster enhancement of a statistical map.

Description
-----------

Demonstrates how TFCE combines signal height with spatial extent. Two positive clusters are generated with the same mean z-value but different sizes, allowing the effect of cluster extent to be seen directly.

A negative cluster illustrates the two-tailed workflow: apply fmri_tfce separately to the positive and negative tails, then recombine the results into a signed TFCE map.

The final example uses graded clusters whose signal decreases toward the edges. This shows how TFCE varies both between clusters and within them.

**Steps:**

1. Define clusters with different spatial extents
2. Generate a signed z-map
3. Apply TFCE to the positive tail
4. Recombine positive and negative TFCE maps
5. Compare raw z-values with TFCE scores
6. Repeat with graded, more realistic clusters

TFCE scores are enhancement statistics, not p-values. Statistical inference requires a permutation null based on the maximum TFCE statistic; this demo covers only the enhancement step.

**Functions demonstrated:**

fmri_tfce, fmri_loadatlas, fmri_ind2sub, fmri_voxdist, fmri_showslices

References
----------

- Smith & Nichols (2009). NeuroImage, 44(1), 83-98.

See Also
--------

:doc:`fmri_tfce <../modules/fmri_tfce>` · :doc:`fmri_scramblephases <../modules/fmri_scramblephases>`

