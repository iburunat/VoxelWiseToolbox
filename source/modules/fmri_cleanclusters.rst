fmri_cleanclusters
==================

Removes small and sparse clusters from a thresholded map.

Description
-----------

Discards clusters smaller than CL_SIZE_THRES voxels, then optionally removes voxels with too few neighbours inside their own cluster, which strips off isolated or spiky voxels.

Usage
-----

.. code-block:: matlab

   newpmap = fmri_cleanclusters(pmap, CL_SIZE_THRES, NN_THRES)
   newpmap = fmri_cleanclusters(pmap, CL_SIZE_THRES, NN_THRES, CONN)

Inputs
------

- **PMAP** -- Thresholded binary brain map, vectorized (228453 x 1) or volume (91 x 109 x 91).
- **CL_SIZE_THRES** -- Minimum cluster size in voxels. Use fmri_csthreshold for a statistically motivated value.
- **NN_THRES** -- Minimum neighbours a voxel must have to be kept (0-26). Default: 0 (disabled). Neighbours are counted within the voxel's own cluster, so touching another cluster does not count.
- **CONN** -- Connectivity for cluster detection: 6 (face), 18 (face + edge, default) or 26 (face + edge + corner).

Outputs
-------

- **NEWPMAP** -- Cleaned binary map, same format as PMAP.

**Order of the two filters:**

Size is checked first, so neighbour pruning can leave clusters below CL_SIZE_THRES or split them in two. This is kept for compatibility with earlier analyses. To guarantee every surviving cluster meets the size threshold, run the filters separately:

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

See Also
--------

:doc:`fmri_csthreshold <fmri_csthreshold>` · :doc:`fmri_csdist <fmri_csdist>` · :doc:`fmri_regiontable <fmri_regiontable>` · :doc:`fmri_tfce <fmri_tfce>`

