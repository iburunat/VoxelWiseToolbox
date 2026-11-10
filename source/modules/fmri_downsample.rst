fmri_downsample
===============

Spatially downsamples vectorized fMRI data by integer factor.

Description
-----------

Retains every Nth voxel along each spatial dimension (x, y, z), reducing data size for computationally expensive operations. The output is a sub-sampled vectorized brain (fewer voxels x T). Inverse: fmri_upsample.

Usage
-----

.. code-block:: matlab

   fmri2 = fmri_downsample(fmri)
   fmri2 = fmri_downsample(fmri, factor)

Inputs
------

- **FMRI** -- Vectorized fMRI data (228453 x T).
- **FACTOR** -- Downsampling factor (integer). Every FACTOR-th voxel is kept in each dimension. Default: 2 (keeps 1/8 of voxels).

Outputs
-------

- **FMRI2** -- Downsampled vectorized data. The number of rows depends on FACTOR and on the brain mask: factor 2 keeps 28542 voxels, factor 3 keeps 8468.

Examples
--------

.. code-block:: matlab

   small = fmri_downsample(data);         % factor 2
   small = fmri_downsample(data, 3);      % factor 3
   orig  = fmri_upsample(small);          % restore full resolution

See Also
--------

:doc:`fmri_upsample <fmri_upsample>` · :doc:`fmri_vol2vect <fmri_vol2vect>`

