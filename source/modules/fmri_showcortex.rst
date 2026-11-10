fmri_showcortex
===============

Cortical surface rendering of a statistical or continuous map.

Description
-----------

Renders a continuous-valued brain map projected onto a cortical surface mesh using colour-coded patches. More informative than fmri_show3d for continuous maps such as z-statistics or correlation values.

Usage
-----

.. code-block:: matlab

   fmri_showcortex(data)
   fmri_showcortex(data, az, el, light, climits, crop, maskalpha, cmap, surfmaterial)

Inputs
------

- **DATA** -- Brain map, vectorized (228453 x 1). Continuous values.
- **AZ** -- Azimuth angle in degrees. Default: 0.
- **EL** -- Elevation angle in degrees. Default: 0.
- **LIGHT** -- Light source positions (K x 2) matrix [az1 el1; az2 el2; ...]. Default: [45 0; -45 0].
- **CLIMITS** -- Colour axis limits [min max]. Default: [] = [min max] of the data.

NOTE ON THRESHOLDING - there is deliberately no THRESHOLD argument here, unlike fmri_showslices / fmri_showplanes / fmri_showselectslices. Those renderers derive the displayed geometry from the thresholded voxel data, so hiding a voxel is meaningful. This function separates four concerns:

geometry            <- the anatomical volume (mask2) at isolevel LEV surface scalars     <- DATA, interpolated onto those vertices by

.. code-block:: matlab

   isosurface(mask2, lev, data)

colour mapping      <- CLIMITS and CMAP removal of anatomy  <- CROP

The anatomical volume defines the surface geometry; the statistical map provides the scalar values interpolated onto that surface for colour rendering. Masking those scalars therefore changes colours, not the rendered object, and CLIMITS already controls the value-to-colour mapping.

Use CLIMITS to control the colour scaling; values outside the range are clipped to the end colours, not hidden. Use CROP to actually remove anatomy from the render.

With the default diverging blue-grey-red colormap, symmetric limits (e.g. [-z z]) place zero at the midpoint of the colour scale, producing a neutral grey background with negative values in blue and positive in red. This holds for the default CMAP; an arbitrary CMAP has no guaranteed neutral midpoint.

CROP      - Restricts which part of the SURFACE is drawn. Either a

bounding box [xmin xmax ymin ymax zmin zmax], or a binary mask (228453 x 1 vectorized, or 91 x 109 x 91). Default: full brain.

The mask is applied to the ANATOMY, not to DATA: zeroed voxels are cut away from the rendered surface, exposing structures behind them, while the data values themselves are never altered. This is how cut-away and single-hemisphere views are made.

MASKALPHA - Opacity of the brain shell. Default: 0.05. Raise it

slightly (e.g. 0.1) to keep a ghost of the whole brain around a cut-away region.

CMAP      - (N x 3) custom colormap. Default: fmri_divmap(256). SURFMATERIAL - Surface reflectance: 'metal' (default, strong speculars),

'dull' (matte, much less washed out), or 'shiny'. If a bright colormap combined with near-overhead lighting looks bleached, 'dull' is usually the fix.

Examples
--------

.. code-block:: matlab

   fmri_showcortex(z_map)
   fmri_showcortex(r_map, 180, 10, [], [0.2 0.8])

   % cut away one quadrant to look inside
   load standard_brain (supplies br, the 91x109x91 binary brain mask)
   m = br;  m(1:45, 45:109, 46:91) = 0;
   fmri_showcortex(tmap, 49, 29, [], [-2.44 2.44], m)

   % left hemisphere only
   v = zeros(91,109,91);  v(1:45,:,:) = 1;
   fmri_showcortex(z_map, 180, 10, [], [], fmri_vol2vect(v))

See Also
--------

:doc:`fmri_show3d <fmri_show3d>` · :doc:`fmri_showslices <fmri_showslices>` · :doc:`fmri_braincake <fmri_braincake>` · :doc:`fmri_regionmask <fmri_regionmask>`

