fmri_show3dhalfbrains
=====================

Plots activation on four lateral and medial hemisphere views.

Description
-----------

Renders the left and right hemispheres separately (both lateral and medial views) and displays them as a single composite figure. The four panels are:

Left lateral \| Left medial \| Right medial \| Right lateral

Usage
-----

.. code-block:: matlab

   fmri_show3dhalfbrains(data)
   fmri_show3dhalfbrains(data, level, surfalpha, color, maskalpha, margin)
   fmri_show3dhalfbrains(data, p)        % p from fmri_makevizpar

Inputs
------

- **DATA** -- fMRI data, vectorized (228453 x n) or volume (91x109x91xn). Binary or continuous values; each column is rendered separately.
- **LEVEL** -- Isosurface threshold level. Default: 0.9
- **SURFALPHA** -- Opacity of activation surface. Default: 1
- **COLOR** -- N x 3 colormap matrix; row k = colour for data column k. Default: [1 0 0; 0 1 0; 0 0 1; 1 1 0; 1 0 1; 0 1 1]
- **MASKALPHA** -- Opacity of the transparent brain shell. Default: 0.08
- **MARGIN** -- Inter-panel margin as a percentage of panel width. Default: 10

Alternatively, pass a parameter struct P from fmri_makevizpar as the second argument. Fields used: level, surfalpha, color, maskalpha, margin.

Examples
--------

.. code-block:: matlab

   fmri_show3dhalfbrains(activation_map)
   fmri_show3dhalfbrains(data, 0.5, 0.8, [1 0 0; 0 0 1], 0.1)

See Also
--------

:doc:`fmri_show3d <fmri_show3d>` · :doc:`fmri_showcortex <fmri_showcortex>` · :doc:`fmri_showslices <fmri_showslices>`

