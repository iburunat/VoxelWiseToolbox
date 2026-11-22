fmri_mni2tal
============

Converts MNI152 coordinates to Talairach space.

Description
-----------

Converts MNI coordinates to Talairach coordinates using the affine MNI-to-Talairach transform tabulated by the MRC CBU (aff_mni2tal, attributed to Meyer-Lindenberg), fitted between the SPM95/96 MNI templates and Talairach 88. This can be useful when comparing results with studies that report coordinates in Talairach space.

This is an approximate single-matrix transform. It differs from the Brett piecewise transform and the later icbm2tal affine transform (Lancaster et al., 2007), which are not implemented here. Those are separate transforms for data normalised using SPM2 or FSL/FLIRT; neither was derived for nonlinear normalisation, and selecting the appropriate one requires knowing the original normalisation route.

The transform is: tal = A \* mni + B

.. code-block:: matlab

   where A = [0.88 0 0; 0 0.97 0; 0 0.05 0.88] (scaling with a y->z shear)
   and   B = [-0.8; -3.32; -0.44]

Input is an MNI coordinate in millimetres. To go from a voxel index in the 91x109x91 template, convert to mm first with fmri_sub2mni, giving the chain

voxel subscripts --[fmri_sub2mni]--> MNI mm --[fmri_mni2tal]--> Talairach mm.

Usage
-----

.. code-block:: matlab

   tal = fmri_mni2tal(mni)

Inputs
------

- **MNI** -- MNI coordinate in mm, (3 x 1) column vector: [x; y; z].

Outputs
-------

- **TAL** -- Talairach coordinate in mm, (3 x 1) column vector.

Examples
--------

.. code-block:: matlab

   tal = fmri_mni2tal([0; 0; 0]);
   tal = fmri_mni2tal([-42; -18; 60]);

Notes
-----

Accepts a 3-element row or column vector (mni(:) is applied internally); the output is always a 3x1 column.

References
----------

- MRC Cognition and Brain Sciences Unit, MNI / Talairach coordinates (aff_mni2tal.m): https://imaging.mrc-cbu.cam.ac.uk/imaging/MniTalairach
- Lancaster, J.L. et al. (2007). Bias between MNI and Talairach coordinates analyzed using the ICBM-152 brain template. Human Brain Mapping, 28(11), 1194-1205. The "icbm2tal" affine given there is more accurate and is not implemented here.

See Also
--------

:doc:`fmri_sub2mni <fmri_sub2mni>` · :doc:`fmri_mni2sub <fmri_mni2sub>` · :doc:`fmri_sub2ind <fmri_sub2ind>`

