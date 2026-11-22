fmri_distinctcolors
===================

Generates N perceptually distinguishable RGB colours.

Description
-----------

Produces a colormap with colours that are as perceptually different from each other as possible. Colour differences are measured in CIE L\*a\*b\* space, which approximates how humans perceive differences between colours. This makes neighbouring labels in an atlas or cluster map easier to distinguish. Intended for categorical data (atlas regions, Brodmann areas, cluster indices), NOT continuous maps, which are better displayed using smooth colormaps such as jet or parula.

Standard colormaps such as hsv become difficult to distinguish when many colours are needed. By maximising the perceptual differences between colours, this function produces more distinguishable palettes, even with 27 or 52 colours.

Usage
-----

.. code-block:: matlab

   cmap = fmri_distinctcolors(n)
   cmap = fmri_distinctcolors(n, seed)
   fmri_distinctcolors(n)              % no output: previews the palette

Inputs
------

- **N** -- Number of colours required.
- **SEED** -- Random seed for the candidate pool, so the palette is reproducible. Default: 0. Change it if you dislike the particular colours chosen.

Outputs
-------

- **CMAP** -- N x 3 RGB matrix, values in [0 1]. If called with no output argument, the palette is drawn as numbered swatches instead, so it can be inspected before use. Assigning the result keeps the function silent, so calls from other toolbox functions never open a figure.

Examples
--------

.. code-block:: matlab

   fmri_distinctcolors(27)              % look at the colours first
   cmap = fmri_distinctcolors(27);      % then use them
   fmri_showslices_int(atlas_map, 1, 2, cmap)

   cmap = fmri_distinctcolors(27, 5);   % reroll with a different seed
   fmri_show3dba(thresh_map, 180, 10, [], [], fmri_distinctcolors(30))

Notes
-----

Colours are selected to maximise their perceptual differences. Very dark and very light colours are avoided to ensure good visibility against the grey brain surface and white figure background.

See Also
--------

:doc:`fmri_show3dba <fmri_show3dba>` · :doc:`fmri_showslices_int <fmri_showslices_int>` · :doc:`fmri_showselectslices_int <fmri_showselectslices_int>`

