fmri_cleanclusters
==================

Removes small and sparse clusters from a thresholded map.

Description
-----------

Applies two criteria to discard unreliable clusters from a binary brain map:

1. Cluster size: removes clusters smaller than CL_SIZE_THRES voxels.
2. Neighbour density: within surviving clusters, removes voxels with fewer than NN_THRES neighbours (eliminates isolated or spikey voxels).

Usage
-----

.. code-block:: matlab

   newpmap = fmri_cleanclusters(pmap, CL_SIZE_THRES, NN_THRES)
   newpmap = fmri_cleanclusters(pmap, CL_SIZE_THRES, NN_THRES, CONN)

Inputs
------

- **PMAP** -- Thresholded binary brain map, vectorized (228453 x 1) or volume (91 x 109 x 91).
- **CL_SIZE_THRES** -- Minimum cluster size in voxels. Clusters smaller than this are removed entirely. Use fmri_csthreshold to obtain a statistically motivated value.
- **NN_THRES** -- Minimum number of neighbours a voxel must have to be retained (range 0-26). Default: 0 (disabled). A voxel with n neighbours inside its own cluster is kept when n >= NN_THRES. Neighbours are counted within the cluster only, so a voxel adjacent to a different cluster does not gain credit for it.
- **CONN** -- Connectivity criterion for cluster detection: 6  = face connectivity (most conservative) 18  = face + edge connectivity (default) 26  = face + edge + corner connectivity (most liberal) Default: 18.

Outputs
-------

- **NEWPMAP** -- Cleaned binary map, same format as PMAP input.

**Note on the order of the two criteria:**

Cluster size is assessed BEFORE neighbour pruning. A cluster that just passes CL_SIZE_THRES can therefore be reduced below that size by the NN_THRES step, and pruning can also split a cluster into disconnected pieces that are not re-tested. This matters when CL_SIZE_THRES comes from fmri_csthreshold, since the surviving voxels then no longer carry the guarantee that threshold was derived to provide.

The behaviour is kept as it is because it is what previous analyses used, and because NN_THRES defaults to 0, in which case the two steps do not interact at all. If both criteria are wanted with the size guarantee preserved, apply them in two passes:

.. code-block:: matlab

   tmp   = fmri_cleanclusters(pmap, 0, NN_THRES);
   clean = fmri_cleanclusters(tmp,  CL_SIZE_THRES, 0);

Examples
--------

.. code-block:: matlab

   clean = fmri_cleanclusters(thresh_map, 50, 0);
   clean = fmri_cleanclusters(thresh_map, cs, 2);
   clean = fmri_cleanclusters(thresh_map, 50, 0, 6);   % strict face-only
   clean = fmri_cleanclusters(thresh_map, 50, 0, 26);  % liberal corner

Notes
-----

No progress bar is shown. The previous version opened a waitbar unconditionally, which fails in headless or batch use and leaks a window if the loop errors.

See Also
--------

:doc:`fmri_csthreshold <fmri_csthreshold>` · :doc:`fmri_csdist <fmri_csdist>` · :doc:`fmri_regiontable <fmri_regiontable>` · :doc:`fmri_tfce <fmri_tfce>`

