fmri_colorbar
=============

Standalone colour scale, in a window of its own.

Description
-----------

Reproduces the value-to-colour mapping a viewer used, as a bar that can be placed beside a figure that carries no scale of its own: fmri_braincake, fmri_showcortex, fmri_show3d, or a panel assembled by hand.

Usage
-----

.. code-block:: matlab

   h = fmri_colorbar(cmap, climits)
   h = fmri_colorbar(cmap, climits, 'Threshold', t_crit)
   h = fmri_colorbar(cmap, climits, 'Ticks', [-8 -4 0 4 8], 'Label', 't')

Inputs
------

- **CMAP** -- N x 3 colormap, the one passed to the viewer.
- **CLIMITS** -- [min max], the limits passed to the viewer. These two fix the mapping: a value V is drawn in the colour at row 1 + (V - CLIMITS(1))/diff(CLIMITS) \* (N-1).

*Name-value pairs*

- **'Threshold'** -- Scalar. Adds ticks at -THRESHOLD and +THRESHOLD, marking where a grey plateau or display threshold begins. Default: [].
- **'Ticks'** -- Explicit tick values; overrides THRESHOLD. Default: [].
- **'Label'** -- Text beside the bar, e.g. 't'. Default: ''.
- **'Orientation'** -- 'vertical' (default) or 'horizontal'.
- **'FontSize'** -- Tick label size. Default: 12.
- **'Position'** -- Figure position [x y w h] in pixels. Default: a bar of 160 x 420 (or 420 x 140 horizontal) at the right edge of the primary screen, clear of the figure it annotates.

Outputs
-------

- **H** -- Figure handle, for exportgraphics or further adjustment.

Examples
--------

.. code-block:: matlab

   fmri_braincake(t_map, -90, 20, 1, sl.axial, 4, 2, 0.08, cl, [], 10, cmap);
   fmri_colorbar(cmap, cl, 'Threshold', t_crit, 'Label', 't');

   % horizontal bar, for placing under a montage
   fmri_colorbar(cmap, cl, 'Orientation', 'horizontal', 'Label', 't');

See Also
--------

:doc:`fmri_createlegend <fmri_createlegend>` · :doc:`fmri_braincake <fmri_braincake>` · :doc:`fmri_showcortex <fmri_showcortex>` · :doc:`fmri_divmap <fmri_divmap>`

