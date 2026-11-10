fmri_mni2sub
============

Converts MNI coordinates (mm) to voxel subscripts.

Description
-----------

Converts one or more MNI152 coordinates (in mm) to voxel subscripts in the 91x109x91 MATLAB 1-based subscript space, using the standard 2mm MNI152 template. Rounds to the nearest voxel centre.

Usage
-----

.. code-block:: matlab

   sub = fmri_mni2sub(mni)

Inputs
------

- **MNI** -- MNI coordinates in mm, (N x 3) matrix: [x1 y1 z1; x2 y2 z2; ...].

Outputs
-------

- **SUB** -- Voxel subscripts (rounded), (N x 3) matrix: [x y z]. 1-based MATLAB indices, x in [1 91], y in [1 109], z in [1 91].

Examples
--------

.. code-block:: matlab

   sub = fmri_mni2sub([0 0 0]);             % returns [46 64 37]
   sub = fmri_mni2sub([-42 -18 60]);        % motor cortex
   mask = fmri_spheremask(fmri_mni2sub([20 -58 18]), 5);

Notes
-----

MNI [0 0 0] maps to subscript [46 64 37]. Coordinates outside the brain volume are not clipped — use with care. Inverse function: fmri_sub2mni.

See Also
--------

:doc:`fmri_sub2mni <fmri_sub2mni>` · :doc:`fmri_mni2tal <fmri_mni2tal>` · :doc:`fmri_spheremask <fmri_spheremask>` · :doc:`fmri_regionmask <fmri_regionmask>`

