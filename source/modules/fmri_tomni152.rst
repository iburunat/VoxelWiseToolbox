fmri_tomni152
=============

Resamples an MNI-space NIfTI onto the toolbox 2mm grid.

Description
-----------

Resamples a NIfTI image with valid spatial metadata onto the toolbox standard MNI152 2mm grid, 91 x 109 x 91 voxels, and writes it to disk. The result is the output file.

This performs AFFINE-BASED resampling only. It does NOT perform nonlinear registration or spatial normalisation from native anatomical space. The input affine must already describe the image's location in MNI/world coordinates, i.e. SPM normalisation, FSL fnirt or ANTs registration has already been applied.

Usage
-----

.. code-block:: matlab

   fmri_tomni152(input_nii, output_nii)
   fmri_tomni152(input_nii, output_nii, 'param', value, ...)

Inputs
------

- **INPUT_NII** -- Path to the input NIfTI (.nii). Support for .nii.gz depends on the bundled NIFTI toolbox version; test before relying on it.
- **OUTPUT_NII** -- Path for the output NIfTI (.nii).

*name-value pairs*

- **'origin'** -- World coordinates [x y z] in mm of input NIfTI voxel [0,0,0]. This is the affine translation, not the voxel index of the anterior commissure (AC). On the target grid, the AC is at NIfTI voxel [45 63 36], or MATLAB index [46 64 37]. If a valid header affine exists, this option changes only its translation and preserves its orientation. Default: read from the sform, or qform if unavailable.
- **'voxel_size'** -- Scalar or [sx sy sz] in mm, overriding the input voxel size. With a valid header affine this rescales the affine columns and preserves orientation. Default: read from the header.
- **'interp'** -- Interpolation method, numeric or string: 0 / 'nearest' - nearest neighbour. THE ONLY CORRECT METHOD for integer label images (atlases, parcellations, ROI masks); linear and spline invent label values that do not exist, at region boundaries. 1 / 'linear'  - trilinear (default). Best balance for functional and most anatomical images. 2 / 'spline'  - smoother with better detail, but can overshoot at sharp edges. The output datatype is float32 whichever is used, so with 'nearest' integer labels are preserved numerically but stored as float32.
- **'verbose'** -- 1 to print progress (default), 0 for silent.

WHAT IS WRITTEN
---------------

.. code-block:: matlab

   Dimensions  : 91 x 109 x 91, or 91 x 109 x 91 x V for a 4D input
   Voxel size  : 2 x 2 x 2 mm isotropic
   Datatype    : float32 (NIfTI datatype 16)
   Affine      : canonical MNI152 2mm sform (sform_code 1, qform_code 0)
   Scaling     : scl_slope 1, scl_inter 0 - values are physical
   pixdim(1)   : 1
   cal_min/max : set from the output data range
   Voxels falling outside the input field of view are set to 0.

The canonical target affine, RAS / SPM convention:

.. code-block:: matlab

   [-2   0   0    90 ]
   [  0  2   0  -126 ]
   [  0  0   2   -72 ]
   [  0  0   0     1 ]

.. code-block:: matlab

   so that TARGET_AFFINE * [45; 63; 36; 1] = [0; 0; 0; 1].

LIMITATION: MNI SPACE CANNOT BE VERIFIED

A valid affine does not prove that an image has been normalised to MNI space. A native-space image may overlap the target grid and be resampled without an error, despite being spatially incorrect. The coverage check detects only gross misalignment. Always compare the output with an MNI152 template before use.

METHOD: DIRECT TARGET-GRID SAMPLING

Each target voxel is mapped through MNI world coordinates to the corresponding location in the input image:

target voxel -> MNI coordinates -> input voxel -> interpolated value

This creates the output directly on the canonical grid, without separate reslicing, padding or cropping steps.

AFFINE PRIORITY
---------------

A valid header affine is always used when available. 'origin' and 'voxel_size' modify its translation and scale, respectively, while preserving its orientation. If the header has no valid sform or qform, a diagonal affine is constructed only when both options are supplied. This fallback is suitable only for axis-aligned images.

NIFTI INPUT AND OUTPUT
----------------------

load_untouch_nii preserves the stored voxel orientation, allowing the header affine to define the coordinate mapping. Because it returns stored intensity values, scl_slope and scl_inter are applied manually before interpolation. save_untouch_nii is used because this function constructs the output affine and header explicitly.

Requires load_untouch_nii and save_untouch_nii from NIFTI_20130306 (Jimmy Shen). Resampling uses MATLAB's interpn.

Examples
--------

.. code-block:: matlab

   % Recommended: take the full affine from the file header
   fmri_tomni152('func.nii', 'func_mni.nii');

   % An atlas or ROI mask: nearest neighbour, never linear
   fmri_tomni152('atlas.nii', 'atlas_mni.nii', 'interp', 'nearest');

   % Override the origin; header orientation still preserved
   fmri_tomni152('func.nii', 'func_mni.nii', 'origin', [90 -126 -72]);

   % Override both - the fallback path for a file with no sform or qform
   fmri_tomni152('func.nii', 'func_mni.nii', 'origin', [90 -126 -72], ...
                 'voxel_size', [3 3 4]);

   % Silent, for batch use
   fmri_tomni152('func.nii', 'func_mni.nii', 'verbose', 0);

   % Check the result reaches the toolbox vector length
   fmri_tomni152('input.nii', 'output.nii');
   v = fmri_vol2vect(fmri_readnii('output.nii'));
   assert(numel(v) == 228453, 'Vectorisation size mismatch');

See Also
--------

:doc:`fmri_readnii <fmri_readnii>` · :doc:`fmri_checknifti <fmri_checknifti>` · :doc:`fmri_export <fmri_export>` · :doc:`fmri_vol2vect <fmri_vol2vect>`

