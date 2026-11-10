fmri_juicyslices
================

Finds the slices carrying most of a map's signal.

Description
-----------

Picks the slices worth showing, instead of the evenly spaced set the default viewers produce. A regularly spaced mosaic devotes equal space to every slice, so a focal result occupies a few pixels in two panels and empty anatomy fills the rest. Selecting slices by content and then displaying fewer of them larger is usually the difference between a figure that shows an effect and one that merely contains it.

Usage
-----

.. code-block:: matlab

   slices = fmri_juicyslices(data)                       % 6 axial slices
   slices = fmri_juicyslices(data, 'coronal', 5)
   [slices, scores] = fmri_juicyslices(data, 'all', 6, 4.14, 6)

Inputs
------

- **DATA** -- Brain map, 228453 x 1 (vectorised) or 91 x 109 x 91.
- **PLANE** -- 'axial' (default), 'coronal', 'sagittal', or 'all'. With 'all', SLICES is a struct with one field per plane.
- **NSLICES** -- How many slices to return. Default 6.
- **THRESHOLD** -- Only voxels with \|value\| >= THRESHOLD count towards a slice's score. Default 0, meaning every finite non-zero voxel counts. Pass the threshold the figure will actually use, so the slices are chosen on what will be visible rather than on what is there.
- **MINSEP** -- Minimum separation between selected slices, in voxels. Default 4. Without it the top slices cluster around a single blob and the set is nearly redundant: adjacent slices through one cluster look almost identical, and the rest of the map is never shown.

Outputs
-------

- **SLICES** -- Selected slice indices, ascending, suitable for passing to fmri_showselectslices. For 'all', a struct with fields .axial, .coronal, .sagittal.
- **SCORES** -- Score of each selected slice, in the same order.

HOW SLICES ARE SCORED
---------------------

Each slice scores the sum of \|value\| over its suprathreshold voxels. This favours slices carrying a lot of strong signal over slices that clip the edge of a large cluster. Counting suprathreshold voxels instead would favour broad weak effects; summing unthresholded values would let a large volume of near-zero noise outweigh a focal result. Neither is wrong, but the sum of suprathreshold magnitude matches what a reader sees.

Selection is greedy: take the highest-scoring slice, exclude everything within MINSEP of it, repeat. This is not the globally optimal spread, but it is predictable and it never returns two slices through the same blob.

Examples
--------

.. code-block:: matlab

   % Choose slices on the threshold the figure will use, then show them large
   t_crit_disp = fmri_p2t(0.001, 14);            % 4.14 at df = 14
   t_lim       = 2 * t_crit_disp;                % 8.28
   sl          = fmri_juicyslices(t_map, 'axial', 6, t_crit_disp);
   cmap        = fmri_divmap(256);
   fmri_showselectslices(t_map, sl, [-t_lim t_lim], 1, 1, 1, cmap, t_crit_disp);

   % All three planes at once
   sl = fmri_juicyslices(t_map, 'all', 5, t_crit_disp);
   disp(sl.axial); disp(sl.coronal); disp(sl.sagittal);

See Also
--------

:doc:`fmri_showselectslices <fmri_showselectslices>` · :doc:`fmri_showselectslices_int <fmri_showselectslices_int>` · :doc:`fmri_showslices <fmri_showslices>` · :doc:`fmri_showplanes <fmri_showplanes>` · :doc:`fmri_p2t <fmri_p2t>` · :doc:`fmri_divmap <fmri_divmap>`

