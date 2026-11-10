fmri_vect2vol
=============

Devectorizes a 228453-element brain vector to a 91x109x91 volume.

Description
-----------

Reconstructs a full 3D (or 4D) volume array from vectorized brain data by placing each value back into its corresponding voxel position. The inverse of fmri_vol2vect.

Usage
-----

.. code-block:: matlab

   vol = fmri_vect2vol(v)
   vol = fmri_vect2vol(v, mask)

Inputs
------

- **V** -- Vectorized brain data: (228453 x 1) for a single map, or (228453 x T) for a time series. A transposed (1 x 228453) input is automatically corrected.
- **MASK** -- Binary brain mask (91 x 109 x 91). Optional. If omitted, the standard toolbox brain mask (standard_brain_NZ.mat) is used.

Outputs
-------

- **VOL** -- Volume array: (91 x 109 x 91) for single map, or (91 x 109 x 91 x T) for time series. Voxels outside the brain mask are set to zero.

Examples
--------

.. code-block:: matlab

   vol  = fmri_vect2vol(v);              % standard mask
   vol4 = fmri_vect2vol(timeseries);     % 91x109x91xT
   vol  = fmri_vect2vol(v, my_mask);     % custom mask

See Also
--------

:doc:`fmri_vol2vect <fmri_vol2vect>` · :doc:`fmri_showslices <fmri_showslices>` · :doc:`fmri_show3d <fmri_show3d>`

