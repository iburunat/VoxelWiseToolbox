fmri_atlas
==========

Lists all available atlases and their region counts.

Usage
-----

.. code-block:: matlab

   fmri_atlas()     % print full atlas list
   fmri_atlas(n)    % print region list for atlas n

Inputs
------

- **ATLAS** -- Atlas number (1-19). If omitted, the table of all atlases is printed instead of a region list.

Examples
--------

.. code-block:: matlab

   fmri_atlas          % the 19 atlases, region counts and references
   fmri_atlas(1)       % the 116 AAL / MarsBar regions
   fmri_atlas(19)      % Brodmann areas, cortex only

See Also
--------

:doc:`fmri_loadatlas <fmri_loadatlas>` · :doc:`fmri_regionmask <fmri_regionmask>` · :doc:`fmri_regionnumber <fmri_regionnumber>` · :doc:`fmri_nregion <fmri_nregion>`

