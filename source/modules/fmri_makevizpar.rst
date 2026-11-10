fmri_makevizpar
===============

Creates a visualization parameter structure with defaults.

Description
-----------

Returns a flat struct holding a default for every parameter used across the toolbox visualization functions. Each viewer reads only the fields it needs and ignores the rest, so one struct can drive several panels and guarantee they share their colour limits, colormap and threshold exactly.

Usage
-----

.. code-block:: matlab

   p = fmri_makevizpar()
   p = fmri_makevizpar('field', value, ...)

Inputs
------

- Name-value pairs overriding any field below. An unrecognised name warns and is ignored. An odd number of arguments is an error - note there is NO leading function-name argument; earlier versions took one and the struct is now flat.

Outputs
-------

- Shared across viewers:
- **P.AZ** -- Azimuth angle (degrees). Default: 40
- **P.EL** -- Elevation angle (degrees). Default: 15
- **P.LABELS** -- Legend labels, one per map, as a cell array of char. Default: {} (no legend). Used by fmri_show3d when DATA holds several maps as columns: one label per column, in the same order.
- **P.CLIMITS** -- Colour axis limits [min max]. Default: [] (auto-scale)
- **P.THRESHOLD** -- Display threshold, slice viewers. Default: [] (legacy rule)
- **P.CMAP** -- N x 3 RGB colormap. Default: fmri_divmap(256)
- **P.COLOR** -- N x 3 activation colours. Default: 6-colour set
- **P.MASKALPHA** -- Brain shell opacity (0-1). Default: 0.08
- **P.LIGHT** -- Light sources [az el; ...]. Default: [45 80; -45 80]
- **P.CBAR** -- Show colourbar (0/1). Default: 1
- **P.OVERLAYALPHA** -- Overlay opacity, slice views. Default: 1
- **P.CROP** -- Bounding box. Default: [1 91 1 109 1 91] (full brain)
- **P.GREYPAR** -- Depth shading, 0=flat to 1=strong. Default: 0.4
- **P.TXT** -- Show slice index on each tile (0/1). Default: 1
- **P.LEVEL** -- Isosurface threshold, fraction of max. Default: 0.9
- **P.SURFALPHA** -- Activation surface opacity (0-1). Default: 1
- **P.PLANE** -- 1=axial, 2=sagittal, 3=coronal. Default: 1. Not every viewer accepts all three. fmri_braincake implements all of them. fmri_showslices and fmri_showslices_int are axial and sagittal only and raise an error on 3. The fmri_showselectslices pair takes explicit slice indices, is axial only, and ignores this field. fmri_showplanes draws all three planes at once and reads P.COORD instead.
- **P.INTERVAL** -- Voxel spacing between slices (1 or 2). Default: 2
- **P.SLICES** -- Slice indices, e.g. [20 30 40 50]. Default: [] (you must set this; there is no sensible default)
- **P.SURFMATERIAL** -- 'metal' (default), 'dull' or 'shiny'

THREE OPACITIES, AND WHICH IS WHICH P.MASKALPHA      the transparent brain shell behind everything, 3D views P.OVERLAYALPHA   the statistical overlay on a slice, 2D views P.SURFALPHA      the activation isosurface itself, 3D views

They govern different objects and are not interchangeable. A viewer reads only the ones that apply to it.

**fmri_show3d surface lighting:**

P.SPECULAR_EXPONENT 0.25, P.SPECULAR_STRENGTH 0.75, P.SPECULAR_REFLECTANCE 1, P.DIFFUSE_STRENGTH 0.75, P.AMBIENT_STRENGTH 0.1, P.BACKFACE_LIGHTING 'reverselit'

**fmri_showplanes:**

- **P.COORD** -- Crosshair voxel [x y z]. Default: [45 63 36]
- **P.BGCOLOR** -- Figure background RGB. Default: [0 0 0]
- **P.CROSSHAIRCOLOR** -- Crosshair RGB. Default: [0 1 0]

**fmri_braincake:**

- **P.THICKNESS** -- Slab thickness in voxels. Default: [] (3 per slice)
- **P.STACKDIR** -- 1=vertical (default), 2=horizontal
- **P.INTERSLICE** -- Gap between slabs, % of slab size. Default: 2

**fmri_show3dhalfbrains:**

- **P.MARGIN** -- Inter-panel margin, % of panel size. Default: 10

Examples
--------

.. code-block:: matlab

   % Set options once and pass the struct; the viewer reads every field it
   % recognises, so nothing has to be re-typed in positional order.
   p = fmri_makevizpar('az', 180, 'el', 10, 'maskalpha', 0.1);
   fmri_show3d(data, p);

   % Fields can also be set after construction:
   p = fmri_makevizpar();
   p.az = 180;  p.el = 10;  p.maskalpha = 0.1;
   fmri_show3d(data, p);

   % One struct, two viewers, guaranteed identical scaling:
   p = fmri_makevizpar('climits', [-8 8], 'threshold', 4.14, ...
                       'slices', [30 40 50]);
   fmri_showslices(t_map, p);
   fmri_showselectslices(t_map, p);

   % The positional form remains available and is unaffected:
   fmri_show3d(data, 180, 10, 0.9, 1, [1 0 0], 0.1);

See Also
--------

:doc:`fmri_show3d <fmri_show3d>` · :doc:`fmri_showcortex <fmri_showcortex>` · :doc:`fmri_braincake <fmri_braincake>` · :doc:`fmri_showslices <fmri_showslices>` · :doc:`fmri_showselectslices <fmri_showselectslices>` · :doc:`fmri_showplanes <fmri_showplanes>` · :doc:`fmri_show3dhalfbrains <fmri_show3dhalfbrains>`

