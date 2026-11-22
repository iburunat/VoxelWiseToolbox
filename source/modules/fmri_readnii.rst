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

- **DATA** -- Image array, [X Y Z] for 3D or [X Y Z T] for 4D data. Always returned as double to support subsequent numerical processing without integer rounding or saturation. The original storage class is reported in METADATA.origclass.
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

This function handles both 3D and 4D files, replacing the former fmri_read3Dnii and fmri_read4Dnii functions.

Files are read with load_nii, which applies the available sform/qform orientation information. Use load_untouch_nii instead if the image array and header must remain exactly as stored.

fmri_export creates a new header from the voxel size and origin rather than preserving the complete header read here. A read-modify-write cycle therefore preserves the image data and basic geometry, but may not retain other header information.

See Also
--------

:doc:`fmri_export <fmri_export>` · :doc:`fmri_vol2vect <fmri_vol2vect>` · :doc:`fmri_vect2vol <fmri_vect2vol>`

