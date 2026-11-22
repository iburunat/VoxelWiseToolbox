fmri_divmap
===========

Diverging blue-white-red colormap for thresholded statistical maps.

Description
-----------

Builds a symmetric blue-to-red colormap in which the gradient is concentrated where the data will actually be visible, rather than spread evenly across a range half of which a display threshold hides.

Usage
-----

.. code-block:: matlab

   cmap = fmri_divmap                       % 256 colours, gradient throughout
   cmap = fmri_divmap(256, 0.5)             % middle 50% compressed (hidden band)
   cmap = fmri_divmap(256, 0.15) % wide CLIMITS only; see the warning below.
   cmap = fmri_divmap(256, 0.5, 'dark')     % strong values dark, not bright
   cmap = fmri_divmap(256, 0, 'bright', [0.7 0.7 0.7])   % grey centre
   [cmap, ends] = fmri_divmap(256)          % also return the endpoint colours

Inputs
------

- **N** -- Number of colours. Default 256. More than 64 matters here: the visible band may be a quarter of the map, so 64 colours leaves only 16 steps and the result bands visibly.
- **HIDDEN** -- Fraction of the colour range to hold flat white in the middle. DEFAULT 0, AND 0 IS USUALLY RIGHT - see the warning below before setting it to anything else.
- **STYLE** -- 'bright' (default) or 'dark'. See the note below.
- **MIDCOLOR** -- RGB triple for the centre of the map. Default [1 1 1], white. The centre colour is particularly important for surface renderings. In slice views, values near zero are usually hidden by the display threshold. On cortical surfaces, however, most of the cortex is unactivated and therefore takes the centre colour. White produces a bright surface, while [0.7 0.7 0.7] gives a neutral grey that blends better with the anatomical background, often making it preferable for fmri_showcortex and fmri_braincake.

Outputs
-------

- **CMAP** -- N x 3 colormap.
- **ENDS** -- 2 x 3 matrix, [positive_extreme; negative_extreme]. Useful for flat-colour renderers such as fmri_show3d, which take one RGB per data column rather than a colormap: passing ENDS keeps a 3D panel consistent with the slice panels beside it.

Examples
--------

.. code-block:: matlab

   t_crit_disp = fmri_p2t(0.001, 14);       % 4.14 at df = 14
   t_lim       = 2 * t_crit_disp;           % 8.28
   cmap        = fmri_divmap(256);          % HIDDEN = 0, the usual choice
   fmri_showslices(t_map, 1, 2, [-t_lim t_lim], [], [], 1, cmap, t_crit_disp);

   % a 3D panel in the same colours: ENDS(1,:) is the red end, matching
   % column 1 of [t_map -t_map]
   [cmap, ends] = fmri_divmap(256);
   fmri_show3d([t_map -t_map], 40, 15, t_crit_disp, [], ends);

Notes
-----

Leave HIDDEN at zero in most cases. With the usual CLIMITS of [-2\*THRESHOLD, 2\*THRESHOLD], the visible colour range already provides a good gradient. Setting HIDDEN too high can make weak suprathreshold voxels white and therefore difficult to see against the anatomical background. Use HIDDEN only when CLIMITS is much wider than the threshold, and keep it below THRESHOLD/CLIMITS(2).

The default 'bright' style keeps strong effects visible against both dark backgrounds and greyscale anatomy. The alternative 'dark' style has darker endpoints, similar to jet, but can make strong effects harder to see on dark backgrounds.

Unlike jet, this map avoids abrupt perceptual transitions and the green-yellow range, which can create misleading visual boundaries and be difficult to interpret for people with red-green colour blindness.

See Also
--------

:doc:`fmri_makecmap <fmri_makecmap>` · :doc:`fmri_showslices <fmri_showslices>` · :doc:`fmri_showselectslices <fmri_showselectslices>` · :doc:`fmri_p2t <fmri_p2t>` · :doc:`fmri_juicyslices <fmri_juicyslices>` · :doc:`fmri_colorbar <fmri_colorbar>`

