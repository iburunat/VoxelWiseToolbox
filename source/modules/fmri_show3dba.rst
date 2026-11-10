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

- **DATA** -- Thresholded brain map, vectorized (228453 x 1). Non-zero voxels are assigned to Brodmann areas; zeros are ignored.
- **AZ** -- Azimuth angle in degrees. Default: 0.
- **EL** -- Elevation angle in degrees. Default: 0.
- **LEVEL** -- Isosurface threshold (fraction of max). Default: 0.9.
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

Internally the map is split into a 228453 x nAreas binary matrix, one column per Brodmann area present, and that matrix is handed to fmri_show3d, which renders each column as a separately coloured isosurface. The split is what this function adds; the rendering, lighting and shell conventions are fmri_show3d's and are shared with every other 3D viewer.

Only part of a map will be rendered. The Brodmann maps cover cortex only, about a quarter of the brain mask, so voxels in white matter, cerebellum, subcortex or the gaps the Talairach Daemon leaves between areas carry no area and are silently dropped. A map lying entirely outside cortex renders nothing and warns.

The area-number key is drawn in a panel beside the brain, in figure coordinates, so it stays inside the figure for any number of areas and does not move when the view is rotated. Numbers rather than names: the full labels (for example 'BA41 Primary auditory (Heschl)') are available from fmri_loadatlas(19) but are far too long for a compact key.

Earlier versions declared an ATLAS argument that was never used - the parcellation could not in fact be changed - and errored if a second argument was supplied. The signature now matches fmri_show3d, whose arguments this function passes through.

See Also
--------

:doc:`fmri_show3d <fmri_show3d>` · :doc:`fmri_show3datlas <fmri_show3datlas>` · :doc:`fmri_showcortex <fmri_showcortex>` · :doc:`fmri_regiontable <fmri_regiontable>` · :doc:`fmri_banumber <fmri_banumber>` · :doc:`fmri_makevizpar <fmri_makevizpar>`

