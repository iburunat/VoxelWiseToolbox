fmri_mirror
===========

Flips a vectorized brain map left-to-right (sagittal mirror).

Description
-----------

Flips a vectorized brain map left-to-right. This can be used to compare hemispheres or to create a bilateral average of a map.

Because the MNI152 brain mask is not perfectly symmetric, some voxels near the mask boundary have no corresponding voxel on the opposite side. Their values are therefore lost during mirroring, and mirroring twice may not exactly reproduce the original map.

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

See Also
--------

:doc:`fmri_vol2vect <fmri_vol2vect>` · :doc:`fmri_vect2vol <fmri_vect2vol>`

