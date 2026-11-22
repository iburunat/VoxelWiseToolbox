fmri_zscorevoldata
==================

Voxelwise z-scoring of fMRI time series.

Description
-----------

Standardises each voxel time series independently to zero mean and unit standard deviation. Constant voxels have no temporal variation and are set to zero rather than NaN, making the output suitable for subsequent GLM and correlation analyses.

Usage
-----

.. code-block:: matlab

   c = fmri_zscorevoldata(d)

Inputs
------

- **D** -- fMRI time series, in any accepted layout: 228453 x T          canonical (voxels x time) T x 228453          transposed 91 x 109 x 91 x T   volume

Outputs
-------

- **C** -- Z-scored data, in the same layout as D. Each voxel series has mean = 0 and std = 1. Constant voxels (zero variance) are set to zero.

Examples
--------

.. code-block:: matlab

   data_z = fmri_zscorevoldata(data);

Notes
-----

Typically applied after fmri_detrend and before correlation analyses to remove voxel-level amplitude differences.

See Also
--------

:doc:`fmri_detrend <fmri_detrend>` · :doc:`fmri_corregressor <fmri_corregressor>`

