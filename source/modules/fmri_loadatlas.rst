fmri_loadatlas
==============

Loads atlas ROI map and region labels by atlas number.

Description
-----------

Shared helper used internally by atlas functions. Returns the voxel-wise ROI index map and a cell array of region name strings for the requested atlas. All 19 atlases in the toolbox are supported.

Usage
-----

.. code-block:: matlab

   T = fmri_loadatlas()            % metadata table for all atlases
   [~, ~, T] = fmri_loadatlas()    % the same table, third-output form
   [ROI_nos, ROI_labels]                    = fmri_loadatlas(atlasnumber)
   [ROI_nos, ROI_labels, name, ref]         = fmri_loadatlas(atlasnumber)

Inputs
------

- **ATLASNUMBER** -- Atlas number (1-19). If omitted, returns only metadata.

Outputs
-------

- **ROI_NOS** -- Vectorized atlas map (228453 x 1).
- **ROI_LABELS** -- Cell array of region name strings {N x 1}.
- **ATLAS_NAME** -- Atlas name string (or full metadata cell array if no input).
- **REFERENCE** -- Reference string.

Examples
--------

.. code-block:: matlab

   fmri_loadatlas                  % print the table of all 19 atlases
   T = fmri_loadatlas();           % the same table, as a MATLAB table

   % AAL, with its name and citation
   [nos, labels, name, ref] = fmri_loadatlas(1);
   fprintf('%s (%s): %d labels\n', name, ref, numel(labels));

   % Voxels belonging to the first region
   mask = nos == 1;

See Also
--------

:doc:`fmri_atlas <fmri_atlas>` · :doc:`fmri_regionmask <fmri_regionmask>` · :doc:`fmri_regionnumber <fmri_regionnumber>` · :doc:`fmri_nregion <fmri_nregion>`

