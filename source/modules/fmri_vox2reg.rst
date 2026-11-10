fmri_vox2reg
============

Averages voxel data within atlas ROIs to produce ROI-level data.

Description
-----------

Computes the mean across all voxels within each atlas ROI, producing a compact ROI-level representation. Useful for dimensionality reduction before connectivity or group-level analyses. Inverse of fmri_reg2vox.

Usage
-----

.. code-block:: matlab

   reg = fmri_vox2reg(vox, atlas)

Inputs
------

- **VOX** -- Voxel-level data: (228453 x T) time series or (228453 x 1) map.
- **ATLAS** -- Atlas number (see atlas list below). Default: 1 (AAL).

Outputs
-------

- **REG** -- ROI-level data (R x T) or (R x 1), where R is the number of ROIs in the selected atlas.

Examples
--------

.. code-block:: matlab

   roi_ts = fmri_vox2reg(data, 3);         % Harvard-Oxford Cortical time series
   roi_fc = fmri_corrmat(roi_ts');                  % ROI x ROI FC matrix

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

:doc:`fmri_reg2vox <fmri_reg2vox>` · :doc:`fmri_regionmask <fmri_regionmask>` · :doc:`fmri_vox2reg <fmri_vox2reg>`

