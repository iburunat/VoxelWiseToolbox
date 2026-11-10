fmri_vol2vect
=============

Vectorizes a 91x109x91 brain volume to a 228453-element vector.

Description
-----------

Extracts the brain voxels from a 3D or 4D volume array, returning a compact matrix in which each row is a brain voxel. Non-brain voxels (outside the standard MNI152 2mm brain mask) are discarded. This is the canonical data format used throughout the toolbox.

Usage
-----

.. code-block:: matlab

   v = fmri_vol2vect(vol)
   v = fmri_vol2vect(vol, mask)

Inputs
------

- **VOL** -- Volume array of size (91 x 109 x 91) or (91 x 109 x 91 x T). Must match the standard MNI152 2mm grid exactly.
- **MASK** -- Binary brain mask (91 x 109 x 91). Optional. If omitted, the standard toolbox brain mask (standard_brain_NZ.mat) is used.

Outputs
-------

- **V** -- Vectorized data: (228453 x 1) for a single volume, or (228453 x T) for a time series.

Examples
--------

.. code-block:: matlab

   v   = fmri_vol2vect(volume);             % standard mask
   v   = fmri_vol2vect(timeseries_4d);      % 228453 x T
   v   = fmri_vol2vect(volume, my_mask);    % custom mask

Notes
-----

The standard brain mask defines 228453 in-brain voxels from the 91x109x91 MNI152 2mm template (total voxels: 902,629). The number 228453 is therefore a constant throughout the toolbox.

See Also
--------

:doc:`fmri_vect2vol <fmri_vect2vol>` · :doc:`fmri_maskdata <fmri_maskdata>` · :doc:`fmri_readnii <fmri_readnii>`

