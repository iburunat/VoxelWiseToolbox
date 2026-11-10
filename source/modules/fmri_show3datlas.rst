fmri_show3datlas
================

3D rendering of atlas regions as coloured isosurfaces.

Description
-----------

Renders the regions of a toolbox atlas as distinctly coloured isosurfaces on the transparent brain shell, with a legend mapping each colour to its region name. Region names are abbreviated to keep the legend compact; the full names are returned in the output struct.

Usage
-----

.. code-block:: matlab

   fmri_show3datlas(atlasnumber)
   fmri_show3datlas(atlasnumber, regions)
   fmri_show3datlas(atlasnumber, regions, surfalpha)
   fmri_show3datlas(atlasnumber, regions, surfalpha, az, el)
   fmri_show3datlas(atlasnumber, p)           % p from fmri_makevizpar
   info = fmri_show3datlas(...)

Inputs
------

- **ATLASNUMBER** -- Atlas number (1-19). Run fmri_atlas() to list atlases.
- **REGIONS** -- Optional vector of region numbers to show. If omitted, all regions present in the brain mask are shown. Rendering many regions at once is slow and hard to read, so if more than 40 would be drawn you are asked to confirm or cancel and pass a subset instead.
- **SURFALPHA** -- Optional opacity of the region surfaces, 0 (transparent) to 1 (opaque). Default: 0.7, so that inner regions remain visible through outer ones. Pass a scalar for all regions, or a vector with one value per shown region for per-region control. Use a higher value (e.g. 1) for solid regions, a lower value (e.g. 0.3) when deep structures are otherwise hidden by the cortex.
- **AZ, EL** -- Optional azimuth and elevation for the view, in degrees. Defaults: AZ = 0, EL = 0 (matching fmri_show3d).

Alternatively pass a parameter struct P from fmri_makevizpar as the second argument, in place of REGIONS. Fields used: surfalpha, az, el. Other fields are ignored; colours always come from fmri_distinctcolors so that adjacent regions stay distinguishable, so P.COLOR has no effect here.

Outputs
-------

- **INFO** -- Struct describing what was drawn: .atlas          atlas name string .regions        region numbers shown (K x 1) .names          full region names (K x 1 cell) .abbrev         abbreviated names used in the legend (K x 1 cell) .colors         RGB colour per region (K x 3), matching the legend .surfalpha      opacity used for the region surfaces .ax             axis handle of the rendering

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

Colours come from fmri_distinctcolors, so adjacent regions are as visually separable as possible, and the same colour is used for a region's surface and its legend swatch. The rendering itself is delegated to fmri_show3d, so the brain shell, lighting and view conventions match the rest of the visualization family.

The confirmation prompt for more than 40 regions is interactive (it reads from the keyboard). In a script or automated context, pass an explicit REGIONS subset of 40 or fewer to avoid the prompt.

See Also
--------

:doc:`fmri_show3d <fmri_show3d>` · :doc:`fmri_loadatlas <fmri_loadatlas>` · :doc:`fmri_atlas <fmri_atlas>` · :doc:`fmri_distinctcolors <fmri_distinctcolors>` · :doc:`fmri_regionmask <fmri_regionmask>`

