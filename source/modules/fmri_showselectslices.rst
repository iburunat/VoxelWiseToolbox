fmri_showselectslices
=====================

Displays continuous data on a user-specified set of slices.

Description
-----------

Displays a continuous brain map on selected axial slices, allowing specific anatomical levels to be shown instead of a regularly spaced mosaic.

Usage
-----

.. code-block:: matlab

   fmri_showselectslices(data, slices)
   fmri_showselectslices(data, slices, climits)
   fmri_showselectslices(data, slices, climits, txt, overlayalpha, cbar, cmap, threshold)
   fmri_showselectslices(data, p)   % p from fmri_makevizpar, slices in p.slices

Inputs
------

- **DATA** -- Continuous brain map, vectorized (228453 x 1).
- **SLICES** -- Vector of axial slice indices to display (e.g. [20 35 50 65]).
- **CLIMITS** -- Colour limits [lo hi]. CLIMITS(1) also acts as a display threshold: voxels below it are not drawn. Default: [] = the full range of the data, [min max]. For a SIGNED statistical map shown with the default diverging colormap, pass symmetric limits so that neutral grey sits at zero: m = max(abs(data));  ... , [-m m], ...
- **TXT** -- Show slice labels: 1 = yes, 0 = no. Default: 1. Labels give the slice position in MNI millimetres, matching the coordinates reported by fmri_regiontable, not the 1-91 voxel index passed in SLICES.
- **OVERLAYALPHA** -- Overlay opacity (0-1). Default: 1.
- **CBAR** -- Show colourbar: 1=yes, 0=no. Default: 1.
- **CMAP** -- Colormap, in any of three forms. Default: [] = the toolbox diverging blue-white-red map, fmri_divmap(256), shared with the other display functions so that panels agree. N x 3 matrix : used as given if it has enough rows, and interpolated up from N anchor colours if not, so [0 0 1; 1 1 1; 1 0 0] is a valid three-colour diverging map. char/string  : the name of any MATLAB colormap function ('hot', 'parula', 'turbo'). []           : the shared default above. For a signed map, pass a diverging map and symmetric CLIMITS so that the neutral colour sits at zero.
- **THRESHOLD** -- Controls which voxels are displayed. Default: []. > 0 : display voxels with \|value\| >= THRESHOLD, retaining effects of both signs. CLIMITS(1) must be lower than THRESHOLD; zero is usually appropriate. = 0 : display all finite voxels. Use NaN to hide voxels. []  : display voxels with value >= CLIMITS(1). This legacy rule is mainly suitable for one-sided maps.

Alternatively, pass a parameter struct P from fmri_makevizpar as the second argument. Fields used: slices, climits, txt, overlayalpha, cbar, cmap, threshold.

Examples
--------

.. code-block:: matlab

   fmri_showselectslices(z_map, [20 35 50 65])
   fmri_showselectslices(r_map, [30 45 60], [0.2 0.7])

See Also
--------

:doc:`fmri_showslices <fmri_showslices>` · :doc:`fmri_showselectslices_int <fmri_showselectslices_int>` · :doc:`fmri_showplanes <fmri_showplanes>`

