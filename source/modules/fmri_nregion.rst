fmri_nregion
============

Returns the region name(s) for one or more atlas ROI numbers.

Description
-----------

Performs the reverse lookup of fmri_regionnumber: given a region number (or list of numbers), returns the corresponding region label string(s) from the specified atlas.

Usage
-----

.. code-block:: matlab

   list_of_regions = fmri_nregion(number)
   list_of_regions = fmri_nregion(number, atlas)

Inputs
------

- **NUMBER** -- Region number(s), scalar or vector.
- **ATLAS** -- Atlas number (see atlas list below). Default: 1 (AAL).

Outputs
-------

- **LIST_OF_REGIONS** -- Cell array of region name strings, one per input number.

Examples
--------

.. code-block:: matlab

   name  = fmri_nregion(57);          % AAL region 57 name
   names = fmri_nregion([1 3 5], 3);  % Harvard-Oxford Cortical regions

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

:doc:`fmri_regionnumber <fmri_regionnumber>` · :doc:`fmri_regionmask <fmri_regionmask>` · :doc:`fmri_regiontable <fmri_regiontable>`

