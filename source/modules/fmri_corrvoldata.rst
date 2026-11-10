fmri_corrvoldata
================

Voxelwise Pearson correlation between two fMRI datasets.

Description
-----------

Computes the temporal correlation between two fMRI time series at each voxel independently, producing a voxelwise r-map. Both datasets must have the same number of voxels and the same number of time points.

Usage
-----

.. code-block:: matlab

   c = fmri_corrvoldata(d1, d2)

Inputs
------

- **D1, D2** -- fMRI time series, both vectorized (228453 x T). Each row is a voxel; each column a time point.

Outputs
-------

- **C** -- Voxelwise correlation map (228453 x 1). Values in [-1, 1].

Examples
--------

.. code-block:: matlab

   c = fmri_corrvoldata(run1, run2);
   fmri_showslices(c, 1, 2, [-1 1])

   % Correlation between rest and task
   c = fmri_corrvoldata(rest_data, task_data);

See Also
--------

:doc:`fmri_corregressor <fmri_corregressor>` · :doc:`fmri_corrmat <fmri_corrmat>` · :doc:`fmri_rv2 <fmri_rv2>` · :doc:`fmri_xcorr <fmri_xcorr>`

