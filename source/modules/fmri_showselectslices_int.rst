fmri_showselectslices_int
=========================

Displays integer data on user-specified axial slices.

Description
-----------

Displays selected axial slices from an integer-labelled brain map, using a distinct colour for each label. A sagittal locator panel on the left marks the locations of the displayed slices with green lines. This is the integer-map counterpart of fmri_showselectslices (for continuous maps), and the select-slice counterpart of fmri_showslices_int (which shows a full mosaic).

Usage
-----

.. code-block:: matlab

   fmri_showselectslices_int(data, slices)
   fmri_showselectslices_int(data, slices, color, txt, overlayalpha)
   fmri_showselectslices_int(data, slices, color, txt, overlayalpha, labels)
   fmri_showselectslices_int(data, p)     % p from fmri_makevizpar

Inputs
------

- **DATA** -- Integer brain map, vectorized (228453 x 1) or a volume (91 x 109 x 91). Each unique non-zero integer is a label and is drawn in colour COLOR(label,:). A 4D input is collapsed to a single label map, with volume k contributing label k.
- **SLICES** -- Vector of axial slice indices to display, e.g. [20 35 50 65].
- **COLOR** -- N x 3 RGB matrix, one row per label. Row L is the colour of label L, so COLOR must have at least max(label) rows. Default: a 6-colour set.
- **TXT** -- Show slice labels: 1 = yes, 0 = no. Default: 1. Labels give the slice position in MNI millimetres, matching the coordinates reported by fmri_regiontable, not the 1-91 voxel index passed in SLICES.
- **OVERLAYALPHA** -- Opacity of the label colours over the brain shell (0-1). Default: 1 (opaque). Overlayalpha=0 makes labels invisible; overlayalpha=0.5 gives semi-transparent labels.
- **LABELS** -- Cell array of strings, one per label, naming label 1 to max(label). Default: {} (no key). When given, a key is drawn in a panel to the right of the slices, using the same colours as the map, and the figure widens to make room. About 12 entries is the practical limit; beyond that the key is still drawn, with a warning, but is too dense to read.

Alternatively pass a parameter struct P from fmri_makevizpar as the second argument. Fields used: slices, color (as COLOR), txt (as TXT), overlayalpha, labels.

Examples
--------

.. code-block:: matlab

   fmri_showselectslices_int(atlas_map, [20 35 50 65])
   fmri_showselectslices_int(clusters, [30 50 70], hsv(10))
   fmri_showselectslices_int(atlas_map, [20 40 60], hsv(21), 1)
   fmri_showselectslices_int(region_map, sl, colors, 1, 0.85, region_names)

Notes
-----

Requires graybrain.mat (the greyscale template shell) on the path. Only axial slices are supported, matching fmri_showselectslices.

See Also
--------

:doc:`fmri_showselectslices <fmri_showselectslices>` · :doc:`fmri_showslices_int <fmri_showslices_int>` · :doc:`fmri_makevizpar <fmri_makevizpar>`

