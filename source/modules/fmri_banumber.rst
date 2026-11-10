fmri_banumber
=============

Shortcut for quick Brodmann lookups.

Description
-----------

Looks up the Brodmann area label for each voxel location using the toolbox Brodmann atlas (BRODMANNlookup.mat). Returns 0 for voxels outside any labelled Brodmann area. It is equivalent to:

.. code-block:: matlab

   fmri_regionnumber(coords, 19)

Usage
-----

.. code-block:: matlab

   regionnumber = fmri_banumber(coords)

Inputs
------

- **COORDS** -- Voxel subscripts (N x 3): [x1 y1 z1; x2 y2 z2; ...]. 1-based MNI152 2mm grid, x in [1 91], y in [1 109], z in [1 91].

Outputs
-------

- **REGIONNUMBER** -- Brodmann area numbers (N x 1). 0 = no Brodmann label.

Examples
--------

.. code-block:: matlab

   ba = fmri_banumber([56 34 27]);
   ba = fmri_banumber([56 34 27; 65 30 50]);

   % Equivalent explicit call
   ba2 = fmri_regionnumber([56 34 27], 19);

Notes
-----

Brodmann areas cover CORTEX ONLY, so 0 is a common and correct answer: it means the voxel has no Brodmann label, not that the lookup failed. About 24% of the 228453-voxel mask carries a label. The rest is white matter, cerebellum and subcortical structures, which have no Brodmann area at all, plus the gaps the Talairach Daemon leaves between adjacent areas, which it draws conservatively rather than extrapolating to a boundary.

A single coordinate can therefore return 0 while sitting a few millimetres from the area you expect.

Area 13 is insular cortex. Some sources state that areas 12-16 are absent in humans; that follows from their not appearing on Brodmann's published surface maps, since the insula is buried in the Sylvian fissure, rather than from their absence in his material. He recorded four human insular areas and identified them as 13-16 in 1914.

Atlas source: Talairach Daemon (Lancaster et al., 1997, 2000), as distributed with WFU PickAtlas (Maldjian et al., 2003). Redistribution permitted by J. Maldjian, September 2026.

See Also
--------

:doc:`fmri_regionnumber <fmri_regionnumber>` · :doc:`fmri_regionmask <fmri_regionmask>` · :doc:`fmri_regiontable <fmri_regiontable>`

