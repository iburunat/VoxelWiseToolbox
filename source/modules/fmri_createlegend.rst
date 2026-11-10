fmri_createlegend
=================

Create a legend as an image for export.

Usage
-----

.. code-block:: matlab

   legend_img = fmri_createlegend(labels, colors)
   legend_img = fmri_createlegend(labels, colors, 'Title', 'Regions')
   legend_img = fmri_createlegend(labels, colors, 'FontSize', 12, 'MaxLabelLength', 25)

Inputs
------

- **LABELS** -- Legend entries, cell array of char (K x 1). Entries longer than MAXLABELLENGTH are truncated with an ellipsis.
- **COLORS** -- RGB colour per entry (K x 3), values in [0, 1]. Row k is the swatch drawn beside LABELS{k}; pass the same matrix used for the rendering, so that key and figure agree.

*Name-value pairs*

- **'Title'** -- Heading above the legend. Default: '' (none).
- **'FontSize'** -- Label font size in points. Default: 10.
- **'MaxLabelLength'** -- Characters before a label is truncated. Default: 25.
- **'ColorSwatchSize'** -- Swatch half-height in axis units. Default: 0.3.
- **'FigureSize'** -- [width height] in pixels. Default: sized automatically from the number and length of the labels. Passing a value overrides that.
- **'Padding'** -- Margin around the legend in pixels. Default: 10.

Outputs
-------

- **LEGEND_IMG** -- RGB image matrix that can be saved with imwrite(). Empty when LABELS is empty.

Examples
--------

.. code-block:: matlab

   % Save as PNG
   img = fmri_createlegend(list{2}, colors, 'Title', 'Regions');
   imwrite(img, 'legend.png');

   % Display in a figure
   figure; imshow(img);

Notes
-----

A figure window is opened to display the result. When generating legends in a loop, close it as you go.

See Also
--------

:doc:`fmri_distinctcolors <fmri_distinctcolors>` · :doc:`fmri_show3dba <fmri_show3dba>` · :doc:`fmri_show3datlas <fmri_show3datlas>` · :doc:`fmri_showslices_int <fmri_showslices_int>`

