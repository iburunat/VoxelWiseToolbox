fmri_show3d
===========

3D isosurface rendering of brain activation.

Description
-----------

Renders one or more activation datasets as coloured isosurfaces on a transparent brain shell. Suitable for presenting whole-brain spatial distributions of activations, networks, or ROIs.

Usage
-----

.. code-block:: matlab

   fmri_show3d(data)
   fmri_show3d(data, az, el, level, surfalpha, color, maskalpha, crop, greypar)
   fmri_show3d(data, [], [], [], [], [], [], [], [], labels)  % with labels

Inputs
------

- **DATA** -- fMRI data, vectorized (228453 x N) or volume (91x109x91xN). Each column N is rendered in a separate colour.
- **AZ** -- Azimuth angle for view in degrees. Default: 0.
- **EL** -- Elevation angle for view in degrees. Default: 0.
- **LEVEL** -- Isosurface threshold (fraction of max). Default: 0.9.
- **SURFALPHA** -- Opacity of activation surface (0=transparent, 1=opaque). Default: 1.
- **COLOR** -- (N x 3) RGB matrix: one colour per data column. Default: [1 0 0; 0 1 0; 0 0 1; 1 1 0; 1 0 1; 0 1 1].
- **MASKALPHA** -- Opacity of the background brain shell. Default: 0.10.
- **CROP** -- Bounding box [xmin xmax ymin ymax zmin zmax] to restrict rendering to a sub-volume, or a mask vector. Default: full brain.
- **GREYPAR** -- Depth-shading strength for the activation surfaces, 0-1. Higher values give stronger front-to-back shading. Default: 0.4.
- **LABELS** -- Cell array of strings (N x 1) with one label per map. If provided, displays a legend with these labels. Default: [].

Examples
--------

.. code-block:: matlab

   fmri_show3d(activation_map)
   fmri_show3d(net1, 180, 10, 0.5, 0.8, [1 0 0], 0.1)
   fmri_show3d([net1 net2 net3], 40, 15, 0.9, 1, [1 0 0; 0 1 0; 0 0 1])
   fmri_show3d([net1 net2], [], [], [], [], [], [], [], [], {'Network A','Network B'})

See Also
--------

:doc:`fmri_show3dba <fmri_show3dba>` · :doc:`fmri_showcortex <fmri_showcortex>` · :doc:`fmri_showslices <fmri_showslices>` · :doc:`fmri_braincake <fmri_braincake>`

