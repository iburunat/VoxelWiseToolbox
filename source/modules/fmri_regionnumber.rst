fmri_regionnumber
=================

Looks up atlas ROI name and number for voxel coordinates.

Description
-----------

Return region name(s) and number(s) for voxel coordinate(s) For each voxel location (subscript space), returns the name and index of the atlas region that contains it. Handles single or multiple coordinates.

Usage
-----

.. code-block:: matlab

   [list_of_regions, regionnumber] = fmri_regionnumber(coords)
   [list_of_regions, regionnumber] = fmri_regionnumber(coords, atlas)

Inputs
------

- **COORDS** -- Voxel subscripts (N x 3): [x1 y1 z1; x2 y2 z2; ...]. 1-based, x in [1 91], y in [1 109], z in [1 91].
- **ATLAS** -- Atlas number (see atlas list below). Default: 1 (AAL).

Outputs
-------

- **LIST_OF_REGIONS** -- Cell array of region name strings (N x 1).
- **REGIONNUMBER** -- Region index numbers (N x 1). 0 = no atlas label.

Examples
--------

.. code-block:: matlab

   [name, num] = fmri_regionnumber([46 64 37]);     % brain centre, AAL
   [names, ~]  = fmri_regionnumber([30 50 40; 60 70 50], 3);

   % From MNI millimetres: convert first, then look up
   fmri_regionnumber(fmri_mni2sub([50 -20 6]), 8)   % Juelich: right TE 1.0

   % Peak voxel of a statistical map
   [~, peak]   = max(r_map);
   [region, ~] = fmri_regionnumber(fmri_ind2sub(peak));

Notes
-----

Atlas numbers: run fmri_atlas() for the indexed list, or fmri_loadatlas() for the metadata table.

See Also
--------

:doc:`fmri_loadatlas <fmri_loadatlas>` · :doc:`fmri_ind2sub <fmri_ind2sub>` · :doc:`fmri_sub2ind <fmri_sub2ind>`

