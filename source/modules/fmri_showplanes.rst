fmri_showplanes
===============

Three-plane (sagittal/coronal/axial) slice view with crosshair.

Description
-----------

Displays sagittal, coronal and axial slices intersecting at a selected voxel. A crosshair marks the selected location in each view, and the three slices are combined in a single figure.

Usage
-----

.. code-block:: matlab

   fmri_showplanes(data)
   fmri_showplanes(data, coord)
   fmri_showplanes(data, coord, climits)
   fmri_showplanes(data, coord, climits, cbar, cmap, overlayalpha, bgcolor,
                   crosshaircolor, threshold)
   fmri_showplanes(data, p)   % p from fmri_makevizpar, coord from p.coord

Inputs
------

- **DATA** -- Continuous brain map, vectorized (228453 x 1).
- **COORD** -- Voxel subscripts [x y z] of the crosshair centre. Convert from MNI: coord = fmri_mni2sub([x y z]).
- **CLIMITS** -- Colour axis limits [min max]. CLIMITS(1) also acts as a display threshold: voxels below it are not drawn. Default: [] = the full range of the data.
- **CBAR** -- Show colourbar (1) or not (0). Default: 1.
- **CMAP** -- (N x 3) colormap matrix. Default: fmri_divmap(256).
- **OVERLAYALPHA** -- Opacity of the activation overlay on the grey brain (0 = invisible, 1 = opaque). Default: 1.
- **BGCOLOR** -- Figure background: 'k' (default) or 'w', or an RGB triple. Everything outside the brain is zero and therefore renders black; 'w' inverts the surround for print figures.
- **CROSSHAIRCOLOR** -- RGB of the crosshair lines. Default: [0 1 0] (green).
- **THRESHOLD** -- Controls which voxels are displayed. Default: []. > 0 : display voxels with \|value\| >= THRESHOLD, retaining effects of both signs. CLIMITS(1) must be lower than THRESHOLD; zero is usually appropriate. = 0 : display all finite voxels. Use NaN to hide voxels. []  : display voxels with value >= CLIMITS(1). This legacy rule is mainly suitable for one-sided maps.

Examples
--------

.. code-block:: matlab

   fmri_showplanes(z_map, fmri_mni2sub([20 -58 18]))
   fmri_showplanes(r_map, [46 64 37], [0.2 0.8])
   fmri_showplanes(data)              % peak voxel, all defaults
   fmri_showplanes(data, coord)       % specified coord, all defaults
   fmri_showplanes(data, p)           % peak voxel, struct params (coord from p.coord)

See Also
--------

:doc:`fmri_showslices <fmri_showslices>` · :doc:`fmri_showselectslices <fmri_showselectslices>` · :doc:`fmri_showcortex <fmri_showcortex>` · :doc:`fmri_makevizpar <fmri_makevizpar>` · :doc:`fmri_mni2sub <fmri_mni2sub>`

