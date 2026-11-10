fmri_regionmask
===============

Binary brain mask for one or more atlas regions.

Description
-----------

Returns a vectorized binary mask (228453 x 1) that is 1 for all voxels belonging to the specified region(s) in the given atlas. Accepts a vector of region numbers to combine multiple ROIs into a single mask.

Usage
-----

.. code-block:: matlab

   [mask, regionname] = fmri_regionmask(regionnumber)
   [mask, regionname] = fmri_regionmask(regionnumber, atlasnumber)

Inputs
------

- **REGIONNUMBER** -- Region number(s), scalar or vector. Use fmri_regionnumber to look up the number for a coordinate.
- **ATLASNUMBER** -- Atlas number (see atlas list below). Default: 1 (AAL).

Outputs
-------

- **MASK** -- Logical vectorized mask (228453 x 1), true inside the region(s). Combining several regions gives their union.
- **REGIONNAME** -- Cell array of region name strings for each requested number.

Examples
--------

.. code-block:: matlab

   % Left hippocampus mask (AAL region 57)
   mask = fmri_regionmask(57);

   % Combine L+R hippocampus
   mask = fmri_regionmask([57 58]);

   % Sphere intersected with anatomical region
   roi = fmri_spheremask(fmri_mni2sub([20 -58 18]), 5) & fmri_regionmask(6);

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

:doc:`fmri_regionnumber <fmri_regionnumber>` · :doc:`fmri_nregion <fmri_nregion>` · :doc:`fmri_regiontable <fmri_regiontable>` · :doc:`fmri_spheremask <fmri_spheremask>`

