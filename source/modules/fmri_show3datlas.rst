fmri_show3datlas
================

3D rendering of atlas regions as coloured isosurfaces.

Description
-----------

Displays selected regions from a toolbox atlas as coloured 3D surfaces on a transparent brain shell. A legend shows abbreviated region names, while INFO returns the full names.

Usage
-----

.. code-block:: matlab

   fmri_show3datlas(atlasnumber)
   fmri_show3datlas(atlasnumber, regions)
   fmri_show3datlas(atlasnumber, regions, surfalpha)
   fmri_show3datlas(atlasnumber, regions, surfalpha, az, el, maskalpha)
   fmri_show3datlas(atlasnumber, p)           % p from fmri_makevizpar
   info = fmri_show3datlas(...)

Inputs
------

- **ATLASNUMBER** -- Atlas number (1-19). Run fmri_atlas() to list atlases.
- **REGIONS** -- Region numbers to display. Default: all regions present in the brain mask. If more than 40 regions would be displayed, the function asks for confirmation because the result may be slow and difficult to interpret.
- **SURFALPHA** -- Region-surface opacity, from 0 (transparent) to 1 (opaque). Default: 1. Pass one value for all regions or one value per displayed region. Lower values help reveal deeper structures.
- **AZ, EL** -- View azimuth and elevation in degrees. Default: 0, 0.
- **MASKALPHA** -- Opacity of the surrounding brain shell, 0 (hidden) to 1 (opaque). Default: 0.05.
- **GREYPAR** -- Depth shading, 0 to 1. Fades far surfaces toward white, so they read paler than the legend swatches. Default: 0.4; lower it to match the key, 0 turns it off.

Alternatively pass a parameter struct P from fmri_makevizpar as the second argument, in place of REGIONS. Fields used: surfalpha, az, el, maskalpha.

Outputs
-------

- **INFO** -- Struct describing what was drawn: .atlas          atlas name string .regions        region numbers shown (K x 1) .names          full region names (K x 1 cell) .abbrev         abbreviated names used in the legend (K x 1 cell) .colors         RGB colour per region (K x 3), matching the legend .surfalpha      opacity used for the region surfaces .maskalpha      opacity used for the brain shell .ax             axis handle of the rendering

Examples
--------

.. code-block:: matlab

   % Whole small atlas
   fmri_show3datlas(9);                       % MNI Structural (9 regions)

   % A chosen subset of a large atlas, from a specific view
   info = fmri_show3datlas(1, [1 2 37 38], 0.5, 120, 20);   % AAL: 4 regions
   info.names        % full names of what was drawn

   % Make deep structures visible through the cortex with lower opacity
   fmri_show3datlas(2, [], 0.3);              % Harvard-Oxford Subcortical

Notes
-----

Colours come from fmri_distinctcolors, so adjacent regions are as visually separable as possible, and the same colour is used for a region's surface and its legend swatch.

See Also
--------

:doc:`fmri_show3d <fmri_show3d>` · :doc:`fmri_loadatlas <fmri_loadatlas>` · :doc:`fmri_atlas <fmri_atlas>` · :doc:`fmri_distinctcolors <fmri_distinctcolors>` · :doc:`fmri_regionmask <fmri_regionmask>`

