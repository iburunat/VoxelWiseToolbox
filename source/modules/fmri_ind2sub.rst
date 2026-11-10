fmri_ind2sub
============

Converts linear brain indices to voxel subscripts.

Description
-----------

Converts one or more linear indices in the 228453-element vectorized brain space to voxel subscripts [x y z] in the 91x109x91 volume space.

Usage
-----

.. code-block:: matlab

   sub = fmri_ind2sub(ind)

Inputs
------

- **IND** -- Linear brain indices, vector of length N. Values in [1, 228453].

Outputs
-------

- **SUB** -- Subscript matrix (N x 3): [x1 y1 z1; x2 y2 z2; ...]. 1-based MATLAB indices in the 91x109x91 volume.

Examples
--------

.. code-block:: matlab

   sub  = fmri_ind2sub(114227);        % centre of the brain
   subs = fmri_ind2sub([1000; 5000; 100000]);
   mni  = fmri_sub2mni(fmri_ind2sub(peak_voxel));

Notes
-----

The mask is cached between calls, so the first call in a session is slower than subsequent ones.

See Also
--------

:doc:`fmri_sub2ind <fmri_sub2ind>` · :doc:`fmri_sub2mni <fmri_sub2mni>` · :doc:`fmri_regionnumber <fmri_regionnumber>`

