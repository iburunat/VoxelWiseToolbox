fmri_reg2vox
============

Maps ROI-level data back to voxel space for visualisation.

Description
-----------

Assigns each voxel the value of its corresponding atlas ROI, expanding an ROI-level statistical map or time series into a full voxel-level brain map. Inverse of fmri_vox2reg.

Usage
-----

.. code-block:: matlab

   vox = fmri_reg2vox(reg, atlas)

Inputs
------

- **REG** -- ROI-level data: (R x 1) statistical map or (R x T) time series, where R is the number of ROIs in the selected atlas.
- **ATLAS** -- Atlas number (see atlas list below). Default: 1 (AAL).

Outputs
-------

- **VOX** -- Voxel-level map (228453 x 1) or time series (228453 x T). Each voxel takes the value of its atlas ROI; voxels with no atlas label are set to zero.

Examples
--------

.. code-block:: matlab

   vox_map = fmri_reg2vox(roi_stats, 3);   % Harvard-Oxford Cortical
   fmri_showslices(vox_map, 1, 2, [0 5])

Notes
-----

**Atlas numbers:**

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

:doc:`fmri_vox2reg <fmri_vox2reg>` · :doc:`fmri_regionmask <fmri_regionmask>` · :doc:`fmri_regionnumber <fmri_regionnumber>`

