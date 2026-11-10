fmri_upsample
=============

Restores spatially downsampled fMRI data to full resolution.

Description
-----------

Interpolates a downsampled brain dataset (from fmri_downsample) back to the full 228453-voxel vectorized space using the specified interpolation method. The downsampling factor is inferred automatically from the number of rows.

Usage
-----

.. code-block:: matlab

   fmri2 = fmri_upsample(fmri)
   fmri2 = fmri_upsample(fmri, factor)
   fmri2 = fmri_upsample(fmri, factor, method)

Inputs
------

- **FMRI** -- Downsampled vectorized data (M x T), where M is the number of voxels after downsampling (M < 228453).
- **METHOD** -- Interpolation method string: 'linear', 'nearest', 'cubic', 'spline'. Default: 'linear'.

Outputs
-------

- **FMRI2** -- Upsampled data (228453 x T) at full brain resolution.

Examples
--------

.. code-block:: matlab

   small = fmri_downsample(data, 2);
   full  = fmri_upsample(small);
   full  = fmri_upsample(small, 'spline');

Notes
-----

Supported input sizes (factor: voxel count): 2: 28542, 3: 8468, 4: 3574, 5: 1820, 6: 1065, 7: 674, 8: 449, 9: 312, 10: 223.

See Also
--------

:doc:`fmri_downsample <fmri_downsample>`

