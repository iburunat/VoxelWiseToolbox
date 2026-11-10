demo_tfce
=========

DEMO_TFCE  Threshold-free cluster enhancement of a statistical map
------------------------------------------------------------------

Demonstrates fmri_tfce on a simulated z-map whose clusters have IDENTICAL height but very different spatial extent. TFCE rewards extent, so the large cluster scores higher than the small one even though no voxel in either is more significant than the other. The demo shows this spatially (the maps) and quantitatively (the scatter plots).

A negative cluster is included so the two-tailed workflow is shown rather than described: fmri_tfce takes a one-sided input, so a signed map must be run once per tail and recombined.

READING THE MAPS. TFCE does not move cluster boundaries and does not smooth - it reweights each voxel by the extent of the cluster it belongs to, integrated over thresholds. Each blob therefore occupies the SAME shape in the z-map and in both TFCE maps; what changes is the scale. In steps 2-5 every voxel in a blob has the same height, so every voxel in it scores almost the same and each blob looks flat. The informative comparison there is BETWEEN blobs. Step 6 repeats the exercise with graded blobs, where the TFCE map does look different from the z-map.

**Steps:**

1. Planted cluster layout                              (1 figure)
2. Simulated z-map                                     (1 figure)
3. TFCE, positive tail                                 (1 figure)
4. TFCE, both tails recombined into a signed map       (1 figure)
5. Raw z vs TFCE score, per cluster                    (1 figure) followed by the printed summary and the theoretical check
6. Graded clusters, the realistic case                 (3 figures)

**Functions demonstrated:**

fmri_tfce, fmri_loadatlas, fmri_ind2sub, fmri_voxdist, fmri_showslices

Note on inference: TFCE scores are NOT p-values and are not interpretable on their own scale. Converting them to corrected p-values requires a permutation null - see fmri_csdist and fmri_csthreshold. This demo stops at the enhancement step.

References
----------

- Smith & Nichols (2009). NeuroImage, 44(1), 83-98.

See Also
--------

:doc:`fmri_tfce <../modules/fmri_tfce>` · :doc:`fmri_csdist <../modules/fmri_csdist>` · :doc:`fmri_csthreshold <../modules/fmri_csthreshold>`

