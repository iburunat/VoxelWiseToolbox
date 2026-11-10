fmri_export
===========

Saves 3D or 4D volume data as a NIfTI file (.nii).

Description
-----------

Saves a MATLAB volume array as a NIfTI file, with optional control over the output filename, voxel size, and origin. Accepts both 4D volume data and vectorized (228453 x T) data.

Usage
-----

.. code-block:: matlab

   fmri_export(voldata)
   fmri_export(voldata, filename)
   fmri_export(voldata, filename, voxelsize)
   fmri_export(voldata, filename, voxelsize, origin)

Inputs
------

- **VOLDATA** -- 3D (91x109x91) or 4D (91x109x91xT) volume, or vectorized (228453 x T) data. Vectorized input is converted automatically.
- **FILENAME** -- Output filename string. The .nii extension is added if absent. Default: 'output'
- **VOXELSIZE** -- Voxel dimensions in mm, [dx dy dz]. Default: [2 2 2]
- **ORIGIN** -- Voxel index of MNI coordinate [0 0 0], [ox oy oz]. Default: [45 63 36]  (standard 2mm MNI152 origin, 0-indexed)

Examples
--------

.. code-block:: matlab

   fmri_export(statmap, 'tmap')
   fmri_export(statmap, 'tmap_1mm', [1 1 1])
   fmri_export(voldata, 'bold', [2 2 2], [45 63 36])

See Also
--------

:doc:`fmri_readnii <fmri_readnii>` · :doc:`fmri_vect2vol <fmri_vect2vol>`

