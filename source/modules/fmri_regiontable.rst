fmri_regiontable
================

Cluster and ROI table for a thresholded statistical map.

Description
-----------

Identifies clusters in a thresholded brain map and lists the atlas regions within each cluster. For every region, it reports the number of voxels, peak statistic and peak MNI coordinates. Results are returned as structures, tab-separated text, voxel maps and a MATLAB table.

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
- **CLSIZE** -- Minimum cluster size in voxels. Default: 0.
- **ROISIZE** -- Minimum number of voxels an atlas region must contain to appear in the results. Default: 0. May exceed CLSIZE. Clusters containing no regions that meet this threshold are not reported.
- **ATLAS** -- Atlas number. Default: 1 (AAL). Run fmri_atlas() for the list of atlases and their region counts, which is maintained in fmri_loadatlas rather than repeated here.

Outputs
-------

- **CLUST** -- Struct array, one element per reported cluster, in the same order that S and T number them: left hemisphere first, then right, largest first within each. Fields: centroid (MNI mm), n (voxels), and region, itself a struct array with name, n, coord, z and BA for each atlas region in the cluster. [clust.n] therefore gives the extents of Clusters 1..N.
- **S** -- The same information as tab-separated text, for pasting into a manuscript.
- **ROI** -- Cell array: ROI{c} is a (228453 x K) binary matrix of the K REPORTED atlas regions of cluster c, those meeting ROISIZE.
- **LIST** -- Cell array: LIST{c}{k} names the region in ROI{c}(:,k).
- **ROI_IDX** -- The same regions as voxel INDICES rather than binary maps.
- **CLUS** -- (228453 x nClusters) matrix. Column c holds the union of the regions reported for cluster c, so with ROISIZE > 0 it can be smaller than the cluster itself: nnz(clus(:,c)) <= clust(c).n, which remains the whole cluster's voxel count. Fast plotting: fmri_show3d(clus(:,[1 3]))
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

.. code-block:: matlab

   SIGNED MAPS
   Clusters are defined by DATA_THRES, and each peak is located using
   abs(DATA), with its signed value reported. The output is grouped by
   hemisphere, but clusters are not separated by sign. A contiguous
   cluster containing both positive and negative values is therefore
   reported as a single cluster. To analyse the two directions separately,
   call the function with sign-specific masks:

.. code-block:: matlab

   fmri_regiontable(mask & stat > 0, stat, ...)
   fmri_regiontable(mask & stat < 0, stat, ...)

.. code-block:: matlab

   HEMISPHERE ASSIGNMENT
   Each cluster is assigned to a hemisphere from the x-coordinate of its
   centroid. Clusters crossing the midline are not split; a centroid at
   x = 0 is assigned to the right hemisphere.

.. code-block:: matlab

   BRODMANN AREA COLUMN
   For each atlas region within a cluster, BA is the most frequent non-zero
   Brodmann label among its voxels. Voxels without a Brodmann label are
   excluded, and BA = 0 means that none of the region's voxels has a label.

.. code-block:: matlab

   Unless ATLAS = 19, the region labels come from the selected atlas, while
   BA comes from the toolbox Brodmann atlas. The BA column is therefore an
   approximate additional label rather than the atlas label defining the
   region.

.. code-block:: matlab

   With ATLAS = 19, the same Brodmann atlas defines both the table rows and
   the BA column. The BA column therefore repeats the area defining each row;
   unlabelled voxels are reported with BA = 0.

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

