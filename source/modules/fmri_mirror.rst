fmri_mirror
===========

Flips a vectorized brain map left-to-right (sagittal mirror).

Description
-----------

Flips the brain image along the x-axis (left-right) to produce its mirror image. Useful for testing laterality or creating symmetric averages (hemisphere-averaged FC maps, etc.).

Usage
-----

.. code-block:: matlab

   d2 = fmri_mirror(d)

Inputs
------

- **D** -- Vectorized brain data (228453 x N) or volume (91 x 109 x 91 x N).

Outputs
-------

- **D2** -- Mirror-flipped brain, same format as D.

Examples
--------

.. code-block:: matlab

   d_mirror = fmri_mirror(d);
   bilateral = (d + fmri_mirror(d)) / 2;   % bilateral average

Notes
-----

the standard MNI152 brain mask is not perfectly left-right symmetric, so a voxel whose mirrored position falls outside the mask has its value dropped (that position is not in the 228453-voxel vector). Mirroring is therefore an exact involution only on the symmetric core of the mask, where both a voxel and its mirror are in-brain; near the asymmetric mask boundary, mirror(mirror(d)) can differ from d. This is a property of the mask, not of the flip.

See Also
--------

:doc:`fmri_vol2vect <fmri_vol2vect>` · :doc:`fmri_vect2vol <fmri_vect2vol>`

