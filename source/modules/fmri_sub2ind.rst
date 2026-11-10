fmri_sub2ind
============

Converts voxel subscripts to linear brain indices.

Description
-----------

Converts one or more voxel subscripts [x y z] in the 91x109x91 volume space to linear indices in the 228453-element vectorized brain space.

Usage
-----

.. code-block:: matlab

   ind = fmri_sub2ind(sub)

Inputs
------

- **SUB** -- Subscript matrix (N x 3): [x1 y1 z1; x2 y2 z2; ...]. 1-based MATLAB indices in the 91x109x91 volume.

Outputs
-------

- **IND** -- Linear brain indices (N x 1). Values in [1, 228453]. Returns NaN for subscripts outside the brain mask.

Examples
--------

.. code-block:: matlab

   ind  = fmri_sub2ind([46 64 37]);        % centre of the brain
   inds = fmri_sub2ind([46 64 37; 30 50 45]);

See Also
--------

:doc:`fmri_ind2sub <fmri_ind2sub>` · :doc:`fmri_mni2sub <fmri_mni2sub>` · :doc:`fmri_spheremask <fmri_spheremask>`

