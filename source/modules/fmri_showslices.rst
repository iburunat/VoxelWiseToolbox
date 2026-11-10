fmri_showslices
===============

Displays continuous brain data as a series of 2D slices.

Description
-----------

Renders a continuous-valued brain map as a mosaic of axial or sagittal slices overlaid on the greyscale brain template. Each slice is equally spaced by INTERVAL voxels. Suitable for statistical maps, correlation maps, tSNR maps, etc.

Usage
-----

.. code-block:: matlab

   fmri_showslices(data)
   fmri_showslices(data, plane, interval, climits)
   fmri_showslices(data, plane, interval, climits, txt, overlayalpha, cbar, cmap, threshold)
   fmri_showslices(data, p)        % p from fmri_makevizpar

Inputs
------

- **DATA** -- Continuous brain map, vectorized (228453 x 1).
- **PLANE** -- Slice plane: 1=axial (default), 2=sagittal
- **INTERVAL** -- Voxel spacing between displayed slices (1 or 2). Default: 2.
- **CLIMITS** -- Colour limits [lo hi]. Unless THRESHOLD is given, CLIMITS(1) also acts as a display threshold: voxels below it are not drawn. Default: [] = determined automatically from the finite, NON-ZERO values in the data, [min max]; if there are none, it falls back to [0 1]. For a SIGNED statistical map shown with the default diverging colormap, pass symmetric limits so that neutral grey sits at zero: m = max(abs(data));  ... , [-m m], ...
- **TXT** -- Show each slice's position on the tile (0/1). Default: 1. Labels are MNI millimetres on the axis being sliced - z for an axial mosaic, x for a sagittal one - matching the coordinates fmri_regiontable reports, not the 1-91 grid index.
- **OVERLAYALPHA** -- Opacity of the statistical overlay over the greyscale anatomy (0-1). Default: 1 (opaque). Below 1 the anatomy shows through the coloured voxels; 0 hides the overlay entirely. Only voxels selected by THRESHOLD are blended, so lowering it does not reveal sub-threshold values.
- **CBAR** -- Show colourbar: 1=yes, 0=no. Default: 1.
- **CMAP** -- Colormap, in any of three forms. Default: [] = the toolbox diverging blue-white-red map, fmri_divmap(256), shared with the other display functions so that panels agree. N x 3 matrix : used as given if it has enough rows, and interpolated up from N anchor colours if not, so [0 0 1; 1 1 1; 1 0 0] is a valid three-colour diverging map. char/string  : the name of any MATLAB colormap function ('hot', 'parula', 'turbo'). []           : the shared default above. For a signed map, pass a diverging map and symmetric CLIMITS so that the neutral colour sits at zero.
- **THRESHOLD** -- Which voxels are drawn, stated explicitly rather than inferred from CLIMITS. Default: []. > 0 : draw where \|value\| >= THRESHOLD. Keeps strong effects of both signs and hides the weak middle, as SPM, FSLeyes and MRIcroGL do for signed maps. CLIMITS(1) must sit strictly below THRESHOLD: data is clamped into CLIMITS first, so otherwise every sub-threshold voxel is clamped up into view and the whole brain is painted. Zero is usually the right CLIMITS(1). = 0 : draw every finite voxel; zero is an ordinary value, not a control code. Mark voxels to hide with NaN. []  : legacy rule, draw where value >= CLIMITS(1). Suits a one-sided map; on a signed map it also draws negative voxels, and hides zeros only if CLIMITS(1) > 0.

Alternatively, pass a parameter struct P from fmri_makevizpar as the second argument. Fields used: plane, interval, climits, txt, overlayalpha, cbar, cmap, threshold.

Examples
--------

.. code-block:: matlab

   % Defaults: axial mosaic, every 2nd slice, full-range diverging map
   fmri_showslices(r_map)

   % Signed statistical map: symmetric limits put the neutral colour at zero,
   % and THRESHOLD hides the weak middle while keeping effects of both signs
   m = max(abs(t_map));
   fmri_showslices(t_map, 1, 2, [-m m], [], [], 1, [], t_crit)

   % Sagittal, every slice, slice labels suppressed
   fmri_showslices(r_map, 2, 1, [-0.7 0.7], 0)

   % One-sided map with a named MATLAB colormap
   fmri_showslices(tsnr, 1, 2, [0 100], [], [], 1, 'hot')

   % Custom diverging map from three anchor colours, expanded to 256
   fmri_showslices(r_map, 1, 2, [-0.7 0.7], [], [], 1, [0 0 0.8; 1 1 1; 1 0 0])

   % Semi-transparent overlay, so the anatomy stays visible underneath
   fmri_showslices(r_map, 1, 2, [-0.7 0.7], [], 0.6)

   % Options as a struct, reusable across viewers
   p = fmri_makevizpar('climits', [-m m], 'threshold', t_crit);
   fmri_showslices(t_map, p)

See Also
--------

:doc:`fmri_showslices_int <fmri_showslices_int>` · :doc:`fmri_showselectslices <fmri_showselectslices>` · :doc:`fmri_showplanes <fmri_showplanes>` · :doc:`fmri_makevizpar <fmri_makevizpar>` · :doc:`fmri_divmap <fmri_divmap>`

