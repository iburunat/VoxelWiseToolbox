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
- **MIDCOLOR** -- RGB triple for the centre of the map. Default [1 1 1], white. This matters far more for SURFACE renderings than for slice mosaics. In a mosaic a display threshold hides everything near zero, so the centre colour is rarely drawn. On a cortical surface or an isosurface the whole sheet is coloured by the map, so unactivated cortex - most of the surface - takes the centre colour. White gives a bright shell; [0.7 0.7 0.7] gives a neutral grey one closer to the anatomical underlay, which is usually preferable for fmri_showcortex and fmri_braincake.

Outputs
-------

- **CMAP** -- N x 3 colormap.
- **ENDS** -- 2 x 3 matrix, [negative_extreme; positive_extreme]. Useful for flat-colour renderers such as fmri_show3d, which take one RGB per data column rather than a colormap: passing ENDS keeps a 3D panel consistent with the slice panels beside it.

WHEN TO LEAVE HIDDEN AT ZERO, WHICH IS ALMOST ALWAYS
----------------------------------------------------

With the conventional choice CLIMITS = [-2\*THRESHOLD, 2\*THRESHOLD], a voxel exactly at the threshold sits at 75% of the colour range. Even spacing puts the light-red anchor there, so the visible band runs light red to saturated red - a full ramp already. Nothing needs redistributing.

DO NOT SET HIDDEN = THRESHOLD / CLIMITS(2). It seems the natural choice and it is the worst one: it places the end of the flat white band at exactly the position the weakest visible voxels occupy, so voxels just above threshold render WHITE and vanish against the anatomical underlay. An earlier version of this help recommended precisely that, and the resulting figures showed white blobs where the weakest suprathreshold clusters should have been.

HIDDEN is worth using only when CLIMITS is much wider than the threshold - say CLIMITS(2) > 5\*THRESHOLD - because the visible band then includes near-white colours that carry no useful contrast. Even then, set it well BELOW THRESHOLD/CLIMITS(2), so that the white band ends before the visible range begins.

ON LUMINANCE, AND WHY 'bright' IS THE DEFAULT
---------------------------------------------

In the default style the extremes are SATURATED and relatively bright, so the strongest effects keep usable contrast against both the dark surround and the greyscale anatomical underlay. Both styles are white-centred and therefore darken outward, as diverging maps for signed data conventionally do; 'bright' simply does not darken as far.

The 'dark' style instead ends in dark navy and dark maroon, following the trajectory of MATLAB's jet more closely. It gives a longer perceptual ramp, but the strongest voxels become the darkest, which on a dark mosaic background makes the most important values the hardest to see. It is offered because the trajectory is sometimes wanted, not because it is recommended.

WHY NOT jet
-----------

jet is not perceptually uniform: it compresses some value ranges and expands others, so a smooth statistical gradient acquires apparent boundaries that do not exist in the data - most visibly at the cyan-yellow transition. The extra "detail" it seems to show is partly an artefact of those false edges. It is also unreadable for red-green colour blindness. This map keeps jet's strong, gradual feel by using saturated endpoints and many steps, without passing through green and yellow.

Examples
--------

.. code-block:: matlab

   t_crit_disp = fmri_p2t(0.001, 14);       % 4.14 at df = 14
   t_lim       = 2 * t_crit_disp;           % 8.28
   cmap        = fmri_divmap(256);          % HIDDEN = 0, the usual choice
   fmri_showslices(t_map, 1, 2, [-t_lim t_lim], [], [], 1, cmap, t_crit_disp);

See Also
--------

:doc:`fmri_makecmap <fmri_makecmap>` · :doc:`fmri_showslices <fmri_showslices>` · :doc:`fmri_showselectslices <fmri_showselectslices>` · :doc:`fmri_p2t <fmri_p2t>` · :doc:`fmri_juicyslices <fmri_juicyslices>`

