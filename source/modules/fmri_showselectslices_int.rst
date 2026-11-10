fmri_showselectslices_int
=========================

Displays integer data on user-specified axial slices.

Description
-----------

Renders an integer-labelled brain map on a manually chosen set of axial slices, each label drawn in a distinct flat colour. A sagittal locator panel on the left shows, with green lines, where each chosen axial slice sits. This is the integer-map counterpart of fmri_showselectslices (for continuous maps), and the select-slice counterpart of fmri_showslices_int (which shows a full mosaic).

Usage
-----

.. code-block:: matlab

   fmri_showselectslices_int(data, slices)
   fmri_showselectslices_int(data, slices, color, txt, overlayalpha)
   fmri_showselectslices_int(data, p)     % p from fmri_makevizpar

Inputs
------

- **DATA** -- Integer brain map, vectorized (228453 x 1) or a volume (91 x 109 x 91). Each unique non-zero integer is a label and is drawn in colour COLOR(label,:). A 4D input is collapsed to a single label map, with volume k contributing label k.
- **SLICES** -- Vector of axial slice indices to display, e.g. [20 35 50 65].
- **COLOR** -- N x 3 RGB matrix, one row per label. Row L is the colour of label L, so COLOR must have at least max(label) rows. Default: a 6-colour set.
- **TXT** -- Show slice labels: 1 = yes, 0 = no. Default: 1. Labels give the slice position in MNI millimetres, matching the coordinates reported by fmri_regiontable, not the 1-91 voxel index passed in SLICES.
- **OVERLAYALPHA** -- Opacity of the label colours over the brain shell (0-1). Default: 1 (opaque). Overlayalpha=0 makes labels invisible; overlayalpha=0.5 gives semi-transparent labels.

Alternatively pass a parameter struct P from fmri_makevizpar as the second argument. Fields used: slices, color (as COLOR), txt (as TXT), overlayalpha.

Examples
--------

.. code-block:: matlab

   fmri_showselectslices_int(atlas_map, [20 35 50 65])
   fmri_showselectslices_int(clusters, [30 50 70], hsv(10))
   fmri_showselectslices_int(atlas_map, [20 40 60], hsv(21), 1)

Notes
-----

Requires graybrain.mat (the greyscale template shell) on the path. Only axial slices are supported, matching fmri_showselectslices.

See Also
--------

:doc:`fmri_showselectslices <fmri_showselectslices>` · :doc:`fmri_showslices_int <fmri_showslices_int>` · :doc:`fmri_makevizpar <fmri_makevizpar>`

