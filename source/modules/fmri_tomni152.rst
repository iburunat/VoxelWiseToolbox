fmri_tomni152
=============

Resamples an MNI-space NIfTI onto the toolbox 2mm grid.

Description
-----------

Resamples a NIfTI image with valid spatial metadata onto the toolbox standard MNI152 2mm grid, 91 x 109 x 91 voxels, and writes it to disk. Nothing is returned; the result is the output file.

This performs AFFINE-BASED resampling only. It does NOT perform nonlinear registration or spatial normalisation from native anatomical space. The input affine must already describe the image's location in MNI/world coordinates, i.e. SPM normalisation, FSL fnirt or ANTs registration has already been applied.

Previously named: convert_to_MNI152_2mm

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

- **'origin'** -- [x y z] in mm: the world-coordinate location of NIfTI voxel [0,0,0] in the INPUT image, i.e. the translation column of the input affine. This is NOT the voxel index of the AC. For the toolbox target, voxel [0,0,0] maps to world [90 -126 -72] mm, while the AC (world [0,0,0]) sits at NIfTI voxel [45 63 36], MATLAB index [46 64 37]. With a valid header affine this overrides the translation column only, and the header's orientation is preserved. Default: read from sform, or qform if there is no sform.
- **'voxel_size'** -- Scalar or [sx sy sz] in mm, overriding the input voxel size. With a valid header affine this rescales the affine columns and preserves orientation. Default: read from the header.
- **'interp'** -- Interpolation method, numeric or string: 0 / 'nearest' - nearest neighbour. THE ONLY CORRECT METHOD for integer label images (atlases, parcellations, ROI masks); linear and spline invent label values that do not exist, at region boundaries. 1 / 'linear'  - trilinear (default). Best balance for functional and most anatomical images. 2 / 'spline'  - smoother with better detail, but can overshoot at sharp edges. The output datatype is float32 whichever is used, so with 'nearest' integer labels are preserved numerically but stored as float32.
- **'verbose'** -- 1 to print progress (default), 0 for silent.

WHAT IS WRITTEN
---------------

| Dimensions  : 91 x 109 x 91, or 91 x 109 x 91 x V for a 4D input
| Voxel size  : 2 x 2 x 2 mm isotropic
| Datatype    : float32 (NIfTI datatype 16)
| Affine      : canonical MNI152 2mm sform (sform_code 1, qform_code 0)
| Scaling     : scl_slope 1, scl_inter 0 - values are physical
| pixdim(1)   : 1
| cal_min/max : set from the output data range

Voxels falling outside the input field of view are set to 0.

**The canonical target affine, RAS / SPM convention:**

.. code-block:: matlab

   [-2   0   0    90 ]
   [  0  2   0  -126 ]
   [  0  0   2   -72 ]
   [  0  0   0     1 ]

so that TARGET_AFFINE \* [45; 63; 36; 1] = [0; 0; 0; 1].

MNI SPACE CANNOT BE VERIFIED AUTOMATICALLY
------------------------------------------

A native-space image has a perfectly valid affine, and if its origin is plausible it will overlap MNI152 space geometrically. This function will then resample it without complaint and produce a spatially meaningless result. The coverage check catches only gross misplacement. ALWAYS check the output against an MNI template before using it.

METHOD - DIRECT TARGET-GRID SAMPLING
------------------------------------

.. code-block:: matlab

   target voxel (0-based NIfTI)
       -> MNI world coordinates (mm)   via TARGET_AFFINE
       -> input voxel coordinates      via inv(INPUT_AFFINE)
       -> interpolated intensity       via interpn

The output array is therefore born on the exact canonical grid. No reslice_nii, pad or clip step is involved.

AFFINE PRIORITY
---------------

The header affine is ALWAYS preferred when a valid sform or qform exists. 'origin' and 'voxel_size' are overrides on top of it, never replacements for it. A diagonal axis-aligned affine is constructed ONLY when no valid header affine exists (sform_code 0, qform_code 0) AND both 'origin' and 'voxel_size' are supplied. That is a documented fallback for files with no spatial metadata, not the primary interface, and it is wrong for images whose axes are not world-aligned.

WHY load_untouch_nii AND save_untouch_nii
-----------------------------------------

load_untouch_nii reads the stored voxel array exactly as it is on disk, with no silent axis reorientation - essential here, because the coordinate mapping is done from the header affine. Because it returns stored rather than physical values, NIfTI intensity scaling (scl_slope, scl_inter) is applied manually before resampling. save_untouch_nii is used for the same reason: the affine and header are managed here, and save_nii would apply orientation transforms of its own.

Requires NIFTI_20130306 (Jimmy Shen): load_untouch_nii, save_untouch_nii. reslice_nii and save_nii are not used. interpn is base MATLAB.

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

