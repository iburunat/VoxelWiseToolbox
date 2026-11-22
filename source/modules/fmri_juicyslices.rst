fmri_juicyslices
================

Finds the slices carrying most of a map's signal.

Description
-----------

Selects slices containing the strongest signal instead of using evenly spaced slices. This avoids devoting most panels to empty anatomy when the signal is spatially focal. The selected slices can then be displayed in fewer, larger panels, making the spatial pattern easier to see.

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

Each slice is scored by summing the absolute values of its suprathreshold voxels, favouring slices with both strong and spatially extensive signal.

The highest-scoring slice is selected first, slices within MINSEP are excluded, and the process is repeated. This avoids selecting closely spaced slices that show largely overlapping signal.

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

