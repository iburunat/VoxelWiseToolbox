fmri_makecmap
=============

Builds a colormap from anchor colours and their positions.

Description
-----------

Interpolates between a small set of anchor colours to produce a full colormap, with control over WHERE each anchor sits. Moving an anchor changes how quickly the colours transition on either side of it, which is how a map is tuned so that its gradient falls where the data actually is.

Usage
-----

.. code-block:: matlab

   cmap = fmri_makecmap(colors)                       % evenly spaced anchors
   cmap = fmri_makecmap(colors, positions)
   cmap = fmri_makecmap(colors, positions, n)

Inputs
------

- **COLORS** -- K x 3 matrix of anchor colours in [0, 1], ordered from the low end of the colour range to the high end.
- **POSITIONS** -- K-element vector giving where each anchor sits. Any increasing values may be used - [1 50 100], [0 0.5 1] and [1 10 100] are all valid - and they are rescaled internally to span the map. Default: evenly spaced.
- **N** -- Number of colours in the result. Default 256.

Outputs
-------

- **CMAP** -- N x 3 colormap, ready to pass to any of the display functions.

WHY THIS IS A SEPARATE FUNCTION
-------------------------------

The anchor-and-position mechanism previously existed only inside fmri_braincake, as its CMAP and CMAPSCALE arguments. It built a colormap and passed the finished result to fmri_showcortex, which accepts only an N x 3 matrix - so a user calling fmri_showcortex, fmri_showslices or any other viewer directly could not reach the mechanism at all.

The alternative would have been to add a CMAPSCALE argument to every display function. That was rejected: it doubles the colour-related arguments everywhere, and it breaks the MATLAB convention that a colormap is simply an N x 3 matrix. Constructing a colormap and displaying data are different jobs. Every viewer keeps one colormap argument, and this function is how a non-uniform one is built.

Examples
--------

.. code-block:: matlab

   % Even blue-grey-red, the toolbox default shape
   cmap = fmri_makecmap([0 0 0.8; 0.7 0.7 0.7; 1 0 0]);

   % Same colours, but blue gives way to grey quickly and grey to red slowly.
   % Useful when negative values are few and should stay saturated.
   cmap = fmri_makecmap([0 0 0.8; 0.7 0.7 0.7; 1 0 0], [1 20 100]);

   % Five anchors, evenly spaced
   cmap = fmri_makecmap([0 0 1; 0.5 0.7 1; 1 1 1; 1 0.6 0.5; 1 0 0]);

   % Use with any viewer
   fmri_showslices(t_map, 1, 2, [-8 8], [], [], 1, cmap, 4.14);

See Also
--------

:doc:`fmri_divmap <fmri_divmap>` · :doc:`fmri_showslices <fmri_showslices>` · :doc:`fmri_showselectslices <fmri_showselectslices>` · :doc:`fmri_showcortex <fmri_showcortex>` · :doc:`fmri_braincake <fmri_braincake>`

