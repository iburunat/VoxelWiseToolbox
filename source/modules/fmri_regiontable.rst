fmri_regiontable
================

Cluster and ROI table for a thresholded statistical map.

Description
-----------

For a binary thresholded brain map, identifies all clusters, labels each voxel with its atlas region, and returns a structured summary table. Useful for reporting activation results: lists cluster size, peak coordinate, peak statistic, MNI location, and atlas region for every cluster.

Usage
-----

.. code-block:: matlab

   [clust, s] = fmri_regiontable(data_thres, data)
   [clust, s, ROI, list, roi_idx, clus, T] = ...
       fmri_regiontable(data_thres, data, clsize, roisize, atlas)

Inputs
------

- **DATA_THRES** -- Binary brain map (228453 x 1), logical or double: nonzero = suprathreshold voxel.
- **DATA** -- Continuous statistical map (228453 x 1): used for peak values.
- **CLSIZE** -- Minimum cluster size in voxels. Default: 0 (all clusters).
- **ROISIZE** -- Minimum region size in voxels to appear in the table. Default: 0. Capped at CLSIZE, since a region cannot be required to be larger than the cluster containing it.
- **ATLAS** -- Atlas number. Default: 1 (AAL). Run fmri_atlas() for the list of atlases and their region counts, which is maintained in fmri_loadatlas rather than repeated here.

Outputs
-------

- **CLUST** -- Struct array, one element per cluster. Fields: centroid (MNI mm), n (voxels), and region, itself a struct array with name, n, coord, z and BA for each atlas region in the cluster.
- **S** -- The same information as tab-separated text, for pasting into a manuscript.
- **ROI** -- Cell array: ROI{c} is a (228453 x K) binary matrix of the K atlas regions within cluster c.
- **LIST** -- Cell array: LIST{c}{k} names the region in ROI{c}(:,k).
- **ROI_IDX** -- The same regions as voxel INDICES rather than binary maps.
- **CLUS** -- (228453 x nClusters) matrix: column c = binary map of cluster c. Fast plotting: fmri_show3d(clus(:,[1 3]))
- **T** -- MATLAB table of the rows printed in S, with columns Cluster, Hemisphere, Region, Voxels, X, Y, Z, Peak, BA. Convenient for sorting, filtering and writetable(T, 'results.csv').

Examples
--------

.. code-block:: matlab

   [c, s] = fmri_regiontable(thresh_map, z_map);
   [c, s] = fmri_regiontable(thresh_map, z_map, 50, 10, 3);

   % Brodmann parcellation, rather than an AAL table with a BA column
   [~, ~, ~, ~, ~, ~, T] = fmri_regiontable(thresh_map, t_map, 20, 5, 19);

Notes
-----

SIGNED MAPS. Clusters are formed from DATA_THRES alone, and each peak is located by \|DATA\| with the signed value reported. The output is split by hemisphere but NOT by direction, so a spatially contiguous cluster holding both positive and negative voxels is reported as one cluster and the mixture is not flagged. To keep the directions distinct, call twice with direction-specific masks:

.. code-block:: matlab

   fmri_regiontable(mask & stat > 0, stat, ...)
   fmri_regiontable(mask & stat < 0, stat, ...)

THE BA COLUMN. BA is the MODAL Brodmann area across each region's voxels, read from the Talairach Daemon maps whatever atlas names the rows. It therefore annotates a region defined by one atlas with a label from another, and is a pointer to the nearby cytoarchitecture rather than a property of the region itself. Two consequences:

- The vote is taken over the LABELLED voxels only, so a label can rest on very few of them. Brodmann maps cover cortex only, roughly a quarter of the brain mask, with deliberate gaps between adjacent areas, so most of a region's voxels carry no area at all. A label backed by three voxels and one backed by three hundred are reported identically. 0 means no voxel in the region carries any Brodmann label.

- Where the two atlases place a boundary differently, the label can be plainly wrong for the region named beside it. Cerebellar regions are the clearest case: they abut occipital cortex across the tentorium, two voxels wide at 2 mm, so a cerebellar region can be labelled BA18 or BA19 although the cerebellum has no Brodmann area at all.

.. code-block:: matlab

   Brodmann areas also cannot be observed in MRI - they are cytoarchitectonic
   and vary between individuals - so a template label is an approximation
   however it is obtained. For Brodmann areas as regions in their own right,
   pass ATLAS = 19: each row is then an area, its voxel count is that area's
   own, nothing is inferred across atlases, and unlabelled voxels are grouped
   as Unlabelled.

**Atlas numbers (fmri_loadatlas is the source of truth):**

.. code-block:: matlab

   1  = AAL / MarsBar (Automated Anatomical Labeling, 116 ROIs, default)
   2  = Harvard-Oxford Subcortical Structural Atlas (21 ROIs)
   3  = Harvard-Oxford Cortical Structural Atlas (48 ROIs)
   4  = Cerebellar Atlas (MNI152, FLIRT affine, 28 ROIs)
   5  = Cerebellar Atlas (MNI152, FNIRT nonlinear, 28 ROIs)
   6  = JHU ICBM-DTI-81 White-Matter Labels (49 ROIs)
   7  = JHU White-Matter Tractography Atlas (20 ROIs)
   8  = Juelich Histological Atlas (121 ROIs)
   9  = MNI Structural Atlas (9 ROIs)

.. code-block:: matlab

   10  = Oxford-Imanova Striatal Structural Atlas (4 ROIs)
   11  = Oxford-Imanova Striatal Connectivity Atlas, 3 sub-regions
   12  = Oxford-Imanova Striatal Connectivity Atlas, 7 sub-regions
   13  = Oxford Thalamic Connectivity Probability Atlas (7 ROIs)
   14  = Craddock Parcellation 200 ROI
   15  = Craddock Parcellation 400 ROI
   16  = Craddock Parcellation 600 ROI
   17  = Craddock Parcellation 800 ROI
   18  = Craddock Parcellation 950 ROI
   19  = Brodmann Areas (47 regions)

See Also
--------

:doc:`fmri_cleanclusters <fmri_cleanclusters>` · :doc:`fmri_regionnumber <fmri_regionnumber>` · :doc:`fmri_csthreshold <fmri_csthreshold>`

