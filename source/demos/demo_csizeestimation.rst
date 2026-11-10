demo_csizeestimation
====================

DEMO_CSIZEESTIMATION  Cluster-size correction by the Ledberg method
-------------------------------------------------------------------

Demonstrates the cluster-extent correction of Ledberg et al. (1998) in four steps:

1. fmri_acfestimate     Estimate the spatial smoothing kernel from the data \| v
2. fmri_csdist          Simulate null maps and record their cluster sizes \| v
3. fmri_csthreshold     Extract the critical size at the chosen FWER \| v
4. fmri_cleanclusters   Remove clusters smaller than the critical size

The size a chance cluster can reach depends on how spatially smooth the data is, which varies with acquisition, preprocessing and the analysis itself. This workflow measures that smoothness and derives a threshold from it.

**Functions demonstrated:**

fmri_acfestimate, fmri_csdist, fmri_csthreshold, fmri_cleanclusters

RUNTIME AND MEMORY. fmri_acfestimate reads participants from disk, so this demo writes temporary files and removes them at the end. Simulating one participant allocates the full 91x109x91xT grid before masking, which at T = 100 is about 720 MB in memory for roughly 180 MB on disk. Step 2 is the slow one - it convolves and cluster-labels a whole volume per null map, and reports its own progress and ETA. Every setting below is small; real use needs far more permutations at each stage.

References
----------

- Ledberg, A., Akerman, S. & Roland, P.E. (1998). Estimation of the probabilities of 3D clusters in functional brain images. NeuroImage 8(2).

See Also
--------

:doc:`fmri_acfestimate <../modules/fmri_acfestimate>` · :doc:`fmri_csdist <../modules/fmri_csdist>` · :doc:`fmri_csthreshold <../modules/fmri_csthreshold>` · :doc:`fmri_cleanclusters <../modules/fmri_cleanclusters>` · :doc:`fmri_tfce <../modules/fmri_tfce>`

