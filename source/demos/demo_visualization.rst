demo_visualization
==================

% DEMO_VISUALIZATION  Every display function in the toolbox, on one dataset.

Description
-----------

Demonstrates all display functions using one simulated signed map and one atlas label map. Only fmri_brainvideo is left commented out, because it writes a file. No other files are written. Run it a section at a time with Ctrl+Enter rather than all at once: the full script opens more than fifty figures.

The data are simulated with fmri_simdata and therefore have irregular spatial profiles, giving the displays a more realistic test than simple geometric shapes.

**Steps:**

1. Build a signed map and an integer label map
2. Colormaps
3. Slice mosaics
4. Slices chosen by content
5. Three-plane view through the peak voxel
6. Cortical surfaces and cropped renderings
7. 3D isosurfaces
8. Value bands as nested surfaces
9. Brain cake: the volume as a stack of slabs
10. Atlas and Brodmann renderings
11. Plotting clusters/regions from fmri_regiontable
12. A smooth map: distance from a seed
13. Legends and colour scales, for assembling figures by hand
14. A rotating video (not run by default)
15. fmri_makevizpar: one struct, reused across viewers

**Functions demonstrated:**

1. fmri_simdata, fmri_vol2vect, fmri_loadatlas, fmri_cleanclusters
2. fmri_divmap, fmri_makecmap, fmri_distinctcolors
3. fmri_showslices, fmri_showslices_int
4. fmri_juicyslices, fmri_showselectslices, fmri_showselectslices_int
5. fmri_showplanes, fmri_ind2sub, fmri_regionnumber, fmri_sub2mni
6. fmri_showcortex
7. fmri_show3d, fmri_show3dhalfbrains
8. fmri_bin
9. fmri_braincake
10. fmri_atlas, fmri_show3datlas, fmri_show3dba
11. fmri_regiontable
12. fmri_voxdist, fmri_sub2ind, fmri_mni2sub
13. fmri_createlegend, fmri_colorbar
14. fmri_brainvideo
15. fmri_makevizpar

