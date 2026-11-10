fmri_bin
========

Bins continuous brain data into a set of discrete colour bands.

Description
-----------

Assigns each voxel to one of NBINS discrete bins spanning [MINVAL, MAXVAL]. Returns a binary (228453 x NBINS) matrix where column k is 1 for voxels whose value falls within bin k, and a corresponding RGB colour lookup table suitable for multi-colour 3D rendering. Used internally by fmri_tfce and fmri_show3d for multi-level rendering and cluster-size integration.

Usage
-----

.. code-block:: matlab

   [bindata, bincmap] = fmri_bin(data, minval, maxval)
   [bindata, bincmap] = fmri_bin(data, minval, maxval, nbins, cmap)

Inputs
------

- **DATA** -- Statistical map, vectorized (228453 x 1).
- **MINVAL** -- Lower bound: values below are excluded.
- **MAXVAL** -- Upper bound: values above are clipped to the top bin.
- **NBINS** -- Number of discrete bins. Default: 10.
- **CMAP** -- (NBINS x 3) RGB colormap. Default: jet, scaled from midrange.

Outputs
-------

- **BINDATA** -- Binary matrix (228453 x NBINS). Column k is 1 where data >= bin_k threshold.
- **BINCMAP** -- RGB colour matrix (NBINS x 3), one row per bin.

Examples
--------

.. code-block:: matlab

   [bd, bc] = fmri_bin(zmap, 2, 5);
   [bd, bc] = fmri_bin(zmap, 2, 5, 20);
   fmri_show3d(bd, [], [], [], [], bc)

See Also
--------

:doc:`fmri_show3d <fmri_show3d>` · :doc:`fmri_tfce <fmri_tfce>` · :doc:`fmri_showslices <fmri_showslices>`

