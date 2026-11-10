fmri_braincake
==============

3D layered-slice rendering of brain activation (brain cake).

Description
-----------

Renders the brain as a set of visible slabs separated in 3D space, with activation shown in colour on each slab face and a transparent brain shell surrounding them. Produces distinctive and informative figures for axial, sagittal, or coronal series.

Usage
-----

.. code-block:: matlab

   fmri_braincake(data, az, el, plane, slices, thickness, stackdir, ...
                  maskalpha, climits, light, interslice, cmap, surfmaterial)
   fmri_braincake(data, p)        % p from fmri_makevizpar

Inputs
------

- **DATA** -- Brain map, vectorized (228453 x N) or volume (91x109x91xN).
- **AZ** -- Azimuth angle in degrees. Default: -90.
- **EL** -- Elevation angle in degrees. Default: 10.
- **PLANE** -- Slice orientation: 1=axial (default), 2=sagittal, 3=coronal.
- **SLICES** -- Indices of visible slice positions (vector). E.g. [23 45 56].
- **THICKNESS** -- Slab thickness for each slice (vector, same length as SLICES). Default: 3 for all slices.
- **STACKDIR** -- Cake stacking: 1=vertical (default), 2=horizontal.
- **MASKALPHA** -- Brain shell opacity (0=invisible, 1=opaque). Default: 0.
- **CLIMITS** -- Colour axis limits [min max].
- **LIGHT** -- Light source positions (K x 2) [az el; ...]. Default: [45 80; -45 80].
- **INTERSLICE** -- Gap between slabs, as a PERCENTAGE of slab size along the stacking direction (0 = slabs touch). Default: 2.
- **CMAP** -- Colormap. Default: fmri_divmap(256). N x 3 matrix : used as given if it has at least 64 rows; fewer rows are treated as anchor colours and expanded with fmri_makecmap. scalar       : shorthand for a grey-yellow-red ramp starting at that grey level, i.e. [c c c; 1 1 0; 1 0 0].
- **SURFMATERIAL** -- Surface reflectance: 'metal' (default), 'dull', or 'shiny'.

Alternatively pass a parameter struct P from fmri_makevizpar as the second argument. Fields used: az, el, plane, slices, thickness, stackdir, maskalpha, climits, light, interslice, cmap, surfmaterial. Other fields are ignored.

Examples
--------

.. code-block:: matlab

   fmri_braincake(z_map, -90, 90, 1, 20:5:70, 4)
   fmri_braincake(r_map, 40, 20, 3, [30 50 70], 3, 1, 0.1, [0.2 0.8])

See Also
--------

:doc:`fmri_show3d <fmri_show3d>` · :doc:`fmri_showcortex <fmri_showcortex>` · :doc:`fmri_showslices <fmri_showslices>`

