fmri_mni2tal
============

Converts MNI152 coordinates to Talairach space.

Description
-----------

Transforms a 3D coordinate from MNI space to Talairach space using the linear mni2tal approximation of the Talairach Daemon (Lancaster et al., 2000). This is useful when comparing results with older literature reported in Talairach coordinates.

This is the simple single-matrix linear transform, not the later piecewise (Brett) or best-fit affine (Lancaster et al., 2007, "icbm2tal") transforms. It is an approximation: expect a few millimetres of disagreement with the 2007 affine, largest away from the AC. For coordinate-reporting where the 2007 fit matters, use the icbm2tal transform instead.

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

- Lancaster, J.L. et al. (2000). Automated Talairach atlas labels for functional brain mapping. Human Brain Mapping, 10(3), 120-131. (The 2007 "icbm2tal" affine — Lancaster et al., Hum Brain Mapp 28:1194 — is a different, more accurate transform not implemented here.)

See Also
--------

:doc:`fmri_sub2mni <fmri_sub2mni>` · :doc:`fmri_mni2sub <fmri_mni2sub>` · :doc:`fmri_sub2ind <fmri_sub2ind>`

