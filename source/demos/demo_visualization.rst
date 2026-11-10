demo_visualization
==================

Every display function in the toolbox, on one dataset.

Description
-----------

Runs through the visualisation module: slice mosaics, selected slices, the three-plane view, cortical surfaces and cut-aways, 3D isosurfaces, layered slab renderings ("brain cake"), and the colormap constructors that all of them share.

The data are simulated with fmri_simdata rather than drawn as analytic spheres. Spheres render as perfect balls, which look nothing like an fMRI result and make every 3D figure in this demo misleading about what the functions produce in practice. The simulator's sources are irregular and brain-shaped, so the renderings show what a real map looks like.

Nothing here needs scanner data, and no files are written.

See Also
--------

:doc:`fmri_showslices <../modules/fmri_showslices>` · :doc:`fmri_showselectslices <../modules/fmri_showselectslices>` · :doc:`fmri_showplanes <../modules/fmri_showplanes>` · :doc:`fmri_showcortex <../modules/fmri_showcortex>` · :doc:`fmri_show3d <../modules/fmri_show3d>` · :doc:`fmri_braincake <../modules/fmri_braincake>` · :doc:`fmri_juicyslices <../modules/fmri_juicyslices>` · :doc:`fmri_divmap <../modules/fmri_divmap>` · :doc:`fmri_makecmap <../modules/fmri_makecmap>` · :doc:`fmri_bin <../modules/fmri_bin>` · :doc:`fmri_makevizpar <../modules/fmri_makevizpar>`

