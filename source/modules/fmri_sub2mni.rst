fmri_sub2mni
============

Converts voxel subscripts to MNI coordinates (mm).

Description
-----------

Converts one or more voxel indices (in the 91x109x91 MATLAB 1-based subscript space) to MNI152 coordinates in millimetres, using the standard 2mm isotropic MNI152 template origin.

Usage
-----

.. code-block:: matlab

   mni = fmri_sub2mni(sub)

Inputs
------

- **SUB** -- Voxel subscripts, (N x 3) matrix: [x1 y1 z1; x2 y2 z2; ...]. Subscripts are 1-based (MATLAB convention), x in [1 91], y in [1 109], z in [1 91].

Outputs
-------

- **MNI** -- MNI coordinates in mm, (N x 3) matrix: [x1 y1 z1; ...]. MNI [0 0 0] corresponds to subscript [46 64 37].

Examples
--------

.. code-block:: matlab

   mni = fmri_sub2mni([46 64 37]);       % returns [0 0 0]
   mni = fmri_sub2mni([46 64 37; 1 1 1])

Notes
-----

Origin is [46 64 37] (1-indexed), corresponding to the MNI152 2mm anterior commissure. Voxel size is 2mm isotropic. Inverse function: fmri_mni2sub.

See Also
--------

:doc:`fmri_mni2sub <fmri_mni2sub>` · :doc:`fmri_mni2tal <fmri_mni2tal>` · :doc:`fmri_ind2sub <fmri_ind2sub>` · :doc:`fmri_regionnumber <fmri_regionnumber>`

