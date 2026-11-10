fmri_bwlabel
============

Labels connected clusters in a 3D binary volume.

Description
-----------

Single entry point for all cluster labelling in the toolbox. Wraps fmri_bwlabel3d, the pure MATLAB implementation. All toolbox functions that need connected-component labelling call this function, so the underlying implementation can be changed in one place.

Usage
-----

.. code-block:: matlab

   [L, num] = fmri_bwlabel(BW)
   [L, num] = fmri_bwlabel(BW, CONN)

Inputs
------

- **BW** -- Binary volume (91 x 109 x 91). Non-zero voxels are foreground. Logical or numeric input accepted.
- **CONN** -- Connectivity: 6, 18 (default) or 26.

Outputs
-------

- **L** -- Integer-labelled volume, labels 1..NUM, background 0.
- **NUM** -- Number of clusters.

Examples
--------

.. code-block:: matlab

   % Cluster a thresholded t-map, keep the largest cluster only
   bw       = fmri_vect2vol(abs(t_map) > 4.14);
   [L, num] = fmri_bwlabel(bw);
   sizes    = accumarray(L(L > 0), 1);
   [~, big] = max(sizes);
   keep     = fmri_vol2vect(L == big);

   % Face connectivity only, a stricter definition of "connected"
   [L, num] = fmri_bwlabel(bw, 6);

Notes
-----

Earlier versions of the toolbox called SPM's compiled spm_bwlabel here. The toolbox is now self-contained and requires no part of SPM. Results are identical: fmri_bwlabel3d reproduces spm_bwlabel's labelling and its label ordering exactly (verified in test_bwlabel3d).

See Also
--------

``fmri_bwlabel3d`` · :doc:`fmri_findclusters <fmri_findclusters>` · :doc:`fmri_cleanclusters <fmri_cleanclusters>` · :doc:`fmri_tfce <fmri_tfce>`

