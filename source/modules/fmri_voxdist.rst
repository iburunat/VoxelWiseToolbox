fmri_voxdist
============

Euclidean distance (mm) between brain voxels.

Description
-----------

Computes the pairwise Euclidean distance in millimetres between two sets of voxels specified as linear brain indices (228453-space). Returns a distance matrix D where D(i,j) is the distance between voxel ind1(i) and ind2(j) in mm (at 2mm isotropic voxel size).

Usage
-----

.. code-block:: matlab

   D = fmri_voxdist(ind1, ind2)
   D = fmri_voxdist(ind1)        % pairwise distances within ind1

Inputs
------

- **IND1** -- Linear brain indices, vector of length N. Values in [1, 228453].
- **IND2** -- Linear brain indices, vector of length M. Default: IND2 = IND1.

Outputs
-------

- **D** -- Distance matrix (N x M) in millimetres. D(i,j) = distance between voxel ind1(i) and ind2(j). If ind2 = ind1, D is symmetric with zeros on the diagonal.

Examples
--------

.. code-block:: matlab

   % Distance between two peak voxels
   d = fmri_voxdist(peak1, peak2);

   % Pairwise distances within a cluster
   cluster_ind = find(cluster_map > 0);
   D = fmri_voxdist(cluster_ind);
   max_diam = max(D(:));

   % Distance from seed voxel to all brain voxels
   seed = fmri_sub2ind(fmri_mni2sub([0 -51 27]));
   D    = fmri_voxdist(seed, 1:228453);
   fmri_showslices(D', 1, 3, [0 100])

Notes
-----

Voxel size is 2mm isotropic. Distance is in millimetres. For large index sets this function can be memory-intensive; consider working in chunks for whole-brain distance matrices.

See Also
--------

:doc:`fmri_spheremask <fmri_spheremask>` · :doc:`fmri_mni2sub <fmri_mni2sub>` · :doc:`fmri_ind2sub <fmri_ind2sub>`

