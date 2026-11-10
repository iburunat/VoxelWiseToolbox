fmri_distinctcolors
===================

Generates N perceptually distinguishable RGB colours.

Description
-----------

Produces a colormap whose entries are as far apart as possible in CIE L\*a\*b\* space, so that neighbouring labels in an atlas or cluster map remain easy to tell apart. This is intended for categorical data (atlas regions, Brodmann areas, cluster indices), NOT for continuous maps, where a smooth colormap such as jet or parula is appropriate.

Evenly spaced hues (hsv(N)) become hard to distinguish beyond about a dozen entries: at N = 27 the closest pair differs by a Lab distance of under 4, which is essentially invisible. This function keeps the closest pair above about 30 at N = 27 and above 23 even at N = 52, the full Brodmann set.

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

Colours are chosen by greedy farthest-point sampling over a random pool in RGB, with distances measured in Lab. Very dark and very light candidates are excluded so that every colour reads clearly against both the grey brain shell and a white figure background.

See Also
--------

:doc:`fmri_show3dba <fmri_show3dba>` · :doc:`fmri_showslices_int <fmri_showslices_int>` · :doc:`fmri_showselectslices_int <fmri_showselectslices_int>`

