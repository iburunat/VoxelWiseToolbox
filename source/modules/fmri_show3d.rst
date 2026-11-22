fmri_show3d
===========

3D isosurface rendering of brain activation.

Description
-----------

Displays one or more brain maps as coloured 3D surfaces within a transparent brain shell. Useful for visualising activations, networks and regions of interest.

Usage
-----

.. code-block:: matlab

   fmri_show3d(data)
   fmri_show3d(data, az, el, level, surfalpha, color, maskalpha, crop, greypar)
   fmri_show3d(data, [], [], [], [], [], [], [], [], labels)  % with labels

Inputs
------

- **DATA** -- fMRI data, vectorized (228453 x N) or volume (91x109x91xN). Binary masks or continuous maps, one per column. Each column is drawn as a single surface in one colour; magnitude is not colour-coded. For that, see FMRI_BRAINCAKE or FMRI_SHOWSLICES. A label map (atlas or cluster indices) is drawn as one surface covering all labels, provided LEVEL is below 1; pass one column per label to colour them separately, as in the example below.
- **AZ** -- Azimuth angle for view in degrees. Default: 0.
- **EL** -- Elevation angle for view in degrees. Default: 0.
- **LEVEL** -- Value at which the surface is drawn, in the units of DATA. One scalar, applied to all maps. For a continuous map, your statistical threshold (e.g. 3.5); for a binary mask, a value in (0,1). Default: 0.1. On a mask, LEVEL also sets how much the surfaces are enlarged. 0.5 draws them at their true size but renders a single voxel at a sixth of its volume, which makes cluster edges look eroded. The default of 0.1 draws a single voxel at nearly full size and a large cluster about a third over. Use 0.5 when extents are being compared, 0.1 when the figure should read cleanly.
- **SURFALPHA** -- Opacity of activation surface (0=transparent, 1=opaque). Default: 1.
- **COLOR** -- (N x 3) RGB matrix: one colour per data column. Default: [1 0 0; 0 1 0; 0 0 1; 1 1 0; 1 0 1; 0 1 1].
- **MASKALPHA** -- Opacity of the background brain shell. Default: 0.10.
- **CROP** -- Bounding box [xmin xmax ymin ymax zmin zmax] to restrict rendering to a sub-volume, or a mask vector. Default: full brain.
- **GREYPAR** -- Depth-shading strength for the activation surfaces, 0-1. Higher values give stronger front-to-back shading. Default: 0.4.
- **LABELS** -- Cell array of strings (N x 1) with one label per map. If provided, displays a legend with these labels. Default: [].

Examples
--------

.. code-block:: matlab

   % a binary region or network mask
   fmri_show3d(net1, 180, 10, 0.5, 0.8, [1 0 0], 0.1)

   % a t map, thresholded at t = 3.5 by LEVEL
   fmri_show3d(t_map, 40, 15, 3.5)

   % positive and negative clusters of the same t map, in two colours
   fmri_show3d([t_map -t_map], 40, 15, 3.5, 1, [1 0 0; 0 0 1])

   % three networks with a legend
   fmri_show3d([net1 net2 net3], 40, 15, 0.5, 1, [1 0 0; 0 1 0; 0 0 1], ...
               [], [], [], {'Auditory','Motor','Default'})

Notes
-----

Isosurface rendering under-draws anything one voxel thick: at LEVEL 0.5 an isolated voxel is drawn at about a sixth of its size. The default LEVEL of 0.1 compensates by enlarging every surface instead. Use the slice viewers when extents matter.

See Also
--------

:doc:`fmri_show3dba <fmri_show3dba>` · :doc:`fmri_showcortex <fmri_showcortex>` · :doc:`fmri_showslices <fmri_showslices>` · :doc:`fmri_braincake <fmri_braincake>` · :doc:`fmri_colorbar <fmri_colorbar>`

