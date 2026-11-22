fmri_show3dba
=============

3D rendering of a map split by Brodmann area.

Description
-----------

Splits a thresholded brain map by Brodmann area and renders each area as a separately coloured isosurface, with a legend listing the area numbers beside the brain. Useful for seeing which Brodmann areas a contrast involves.

Usage
-----

.. code-block:: matlab

   fmri_show3dba(data)
   fmri_show3dba(data, az, el, level, surfalpha, color, maskalpha, crop)
   fmri_show3dba(data, p)        % p from fmri_makevizpar

Inputs
------

- **DATA** -- Brain map, vectorized (228453 x 1). Voxels at or above LEVEL are assigned to Brodmann areas. Pass either a thresholded map with LEVEL in (0,1), or the map itself with LEVEL set to your statistical threshold. The two give near-identical surfaces.
- **AZ** -- Azimuth angle in degrees. Default: 0.
- **EL** -- Elevation angle in degrees. Default: 0.
- **LEVEL** -- Isosurface value, in the units of DATA, and also the cut-off deciding which areas appear. Default: 0.1, which enlarges the surfaces so small pieces stay visible; use 0.5 to draw them at their true size. See fmri_show3d.
- **SURFALPHA** -- Opacity of the area surfaces, scalar or one value per area. Default: 1.
- **COLOR** -- N x 3 RGB matrix, one colour per Brodmann area found. Default: fmri_distinctcolors(number of areas), which keeps the colours perceptually distinguishable however many areas there are. Supplying fewer rows than there are areas warns, and the palette is replaced by fmri_distinctcolors.
- **MASKALPHA** -- Opacity of the background brain shell. Default: 0.05.
- **CROP** -- Bounding box [xmin xmax ymin ymax zmin zmax], or a mask. Default: full brain.

Alternatively pass a parameter struct P from fmri_makevizpar as the second argument. Fields used: az, el, level, surfalpha, color, maskalpha, crop.

Examples
--------

.. code-block:: matlab

   fmri_show3dba(thresh_map)
   fmri_show3dba(thresh_map, 180, 10)
   fmri_show3dba(thresh_map, fmri_makevizpar('az', 180, 'el', 10))

Notes
-----

The map is split by Brodmann area, and each area is rendered in a different colour. Unlabelled and non-cortical voxels are not shown.

A fixed key beside the brain identifies the areas present.

See Also
--------

:doc:`fmri_show3d <fmri_show3d>` · :doc:`fmri_show3datlas <fmri_show3datlas>` · :doc:`fmri_showcortex <fmri_showcortex>` · :doc:`fmri_regiontable <fmri_regiontable>` · :doc:`fmri_banumber <fmri_banumber>` · :doc:`fmri_makevizpar <fmri_makevizpar>`

