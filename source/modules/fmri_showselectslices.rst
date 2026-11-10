fmri_showselectslices
=====================

Displays continuous data on a user-specified set of slices.

Description
-----------

Renders a continuous brain map on a manually chosen set of axial slice positions. Useful for targeting specific anatomical levels in a figure rather than displaying a uniform mosaic.

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
- **THRESHOLD** -- Which voxels are drawn, stated explicitly rather than inferred from CLIMITS. Default: []. > 0 : draw where \|value\| >= THRESHOLD. Keeps strong effects of both signs and hides the weak middle, as SPM, FSLeyes and MRIcroGL do for signed maps. CLIMITS(1) must sit strictly below THRESHOLD: data is clamped into CLIMITS first, so otherwise every sub-threshold voxel is clamped up into view and the whole brain is painted. Zero is usually the right CLIMITS(1). = 0 : draw every finite voxel; zero is an ordinary value, not a control code. Mark voxels to hide with NaN. []  : legacy rule, draw where value >= CLIMITS(1). Suits a one-sided map; on a signed map it also draws negative voxels, and hides zeros only if CLIMITS(1) > 0.

Alternatively, pass a parameter struct P from fmri_makevizpar as the second argument. Fields used: slices, climits, txt, overlayalpha, cbar, cmap, threshold.

Examples
--------

.. code-block:: matlab

   fmri_showselectslices(z_map, [20 35 50 65])
   fmri_showselectslices(r_map, [30 45 60], [0.2 0.7])

See Also
--------

:doc:`fmri_showslices <fmri_showslices>` · :doc:`fmri_showselectslices_int <fmri_showselectslices_int>` · :doc:`fmri_showplanes <fmri_showplanes>`

