fmri_showslices_int
===================

Displays integer-labelled brain data as a coloured slice mosaic.

Description
-----------

Renders an integer-valued brain map (e.g. atlas parcellations, cluster indices, network labels) as a mosaic of 2D slices, assigning each integer label a distinct flat colour. This is the integer-map counterpart of fmri_showslices, which is for continuous maps (z, r, t, ...).

Usage
-----

.. code-block:: matlab

   fmri_showslices_int(data)
   fmri_showslices_int(data, plane, interval, color, txt, overlayalpha)
   fmri_showslices_int(data, p)        % p from fmri_makevizpar

Inputs
------

- **DATA** -- Integer brain map, vectorized (228453 x 1) or a volume (91 x 109 x 91). Each unique non-zero integer is a label and is drawn in the colour COLOR(label,:). A 4D input is collapsed to a single label map, with volume k contributing label k.
- **PLANE** -- Slice plane: 1 = axial (default), 2 = sagittal. (3 = coronal is not yet implemented; see Notes.)
- **INTERVAL** -- Voxel spacing between displayed slices: 1 or 2. Default: 2.
- **COLOR** -- N x 3 RGB matrix, one row per label. Row L is the colour of label L. Default: an 8-colour set. There must be at least as many rows as the largest label in the data.
- **TXT** -- If nonzero/true, print each slice's position on the tile. Default: 1. Labels are MNI millimetres on the axis being

  - **sliced** -- z for an axial mosaic, x for a sagittal one - matching the coordinates fmri_regiontable reports, not the 1-91 grid index.

- **OVERLAYALPHA** -- Opacity of the label colours over the brain shell (0-1). Default: 1 (opaque).

Alternatively, pass a parameter struct P from fmri_makevizpar as the second argument. Fields used: plane, interval, color, txt (as TXT), overlayalpha.

Examples
--------

.. code-block:: matlab

   fmri_showslices_int(atlas_map)

   % Cluster map from fmri_findclusters, one distinct colour per cluster
   clusters = fmri_findclusters(t_map > 4.14, 18);
   fmri_showslices_int(clusters, 1, 2, fmri_distinctcolors(max(clusters)))
   fmri_showslices_int(roi_indices, 1, 2, hsv(20))
   p = fmri_makevizpar('plane', 2, 'interval', 2);
   fmri_showslices_int(atlas_map, p)

Notes
-----

Coronal display (plane = 3) is documented in fmri_makevizpar for consistency across the toolbox but is not yet implemented here; passing plane = 3 raises an error rather than silently drawing nothing. Requires graybrain.mat (the greyscale template shell) on the path.

See Also
--------

:doc:`fmri_showslices <fmri_showslices>` · :doc:`fmri_showselectslices_int <fmri_showselectslices_int>` · :doc:`fmri_show3dba <fmri_show3dba>` · :doc:`fmri_makevizpar <fmri_makevizpar>`

