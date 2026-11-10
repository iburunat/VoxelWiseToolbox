fmri_readnii
============

Reads a 3D or 4D NIfTI (.nii) or Analyze (.img/.hdr) file.

Description
-----------

Reads volumetric brain data and returns both the image array and a metadata structure. Works for both 3D (single volume) and 4D (time series) files. If no filename is supplied, a file-open dialog is shown.

Usage
-----

.. code-block:: matlab

   [data, metadata] = fmri_readnii()
   [data, metadata] = fmri_readnii('subject01.nii')
   [data, metadata] = fmri_readnii('/path/to/data.img')

Inputs
------

- **FILENAME** -- Path to a .nii or .img file (string). Optional: if omitted, a file-open dialog is displayed.

Outputs
-------

- **DATA** -- Image array. Shape: [X Y Z] for 3D, [X Y Z T] for 4D. Always returned as double, regardless of how the file was stored. NIfTI images are commonly saved as int16, and MATLAB propagates integer classes through arithmetic, so returning the stored class would silently round and saturate results in any downstream detrending, z-scoring or filtering. The original on-disk class is reported in METADATA.origclass.
- **METADATA** -- Structure with fields:

  - **.hdr** -- Full NIfTI/Analyze header
  - **.filetype** -- File type code
  - **.fileprefix** -- Filename without extension
  - **.machine** -- Byte-order string
  - **.original** -- Original header struct
  - **.origclass** -- Class of the image data as stored on disk

Examples
--------

.. code-block:: matlab

   [vol, meta] = fmri_readnii('anat.nii');
   [ts,  meta] = fmri_readnii('bold_run1.nii');
   [vol, meta] = fmri_readnii();   % opens file dialog

Notes
-----

This function replaces the earlier fmri_read3Dnii and fmri_read4Dnii, which were identical. Both 3D and 4D files are handled automatically.

Reading uses load_nii, which applies the sform/qform transform and so returns the data in a consistent orientation regardless of how the file was stored. This is what makes a file line up with the toolbox's 91x109x91 MNI152 grid. Use load_untouch_nii directly if you need the raw array exactly as written, for instance when editing a header field.

fmri_export writes with make_nii, which builds a fresh header from the voxel size and origin rather than preserving the one read here. A read-modify-write cycle therefore keeps the data and geometry but not any other header fields.

See Also
--------

:doc:`fmri_export <fmri_export>` · :doc:`fmri_vol2vect <fmri_vol2vect>` · :doc:`fmri_vect2vol <fmri_vect2vol>`

