fmri_cnr
========

Temporal contrast-to-noise ratio (tCNR) for fMRI data.

Description
-----------

Calculates the functional CNR per unit time (fCNR), defined as the ratio of the mean absolute scan-to-scan signal change (delta-S) to the temporal standard deviation of the signal per voxel:

.. code-block:: matlab

   fCNR = mean|delta-St| / sigma_t

.. code-block:: matlab

   Here delta-St is the time-dependent signal change, operationalised for a
   continuous (naturalistic) paradigm as the mean absolute scan-to-scan change
   of the voxel time series. Equivalently fCNR = fSNR * (delta-St / St), where
   fSNR = St / sigma_t; the mean signal St cancels, so no division by the mean
   is applied. For a block design delta-St would instead be the modelled
   condition contrast; this successive-difference form is the continuous-data
   analogue, appropriate to the paradigms this toolbox targets.

Usage
-----

.. code-block:: matlab

   CNR = fmri_cnr(v)

Inputs
------

- **V** -- fMRI data, vectorized (228453 x T) or volume (91 x 109 x 91 x T)

Outputs
-------

- **CNR** -- Voxelwise tCNR map, vectorized (228453 x 1). Voxels with zero temporal variance (e.g. outside the brain mask) are set to 0.

Examples
--------

.. code-block:: matlab

   CNR = fmri_cnr(data);
   fmri_showslices(CNR, 1, 2, [0 5])

References
----------

- Welvaert, M. & Rosseel, Y. (2013). On the definition of signal-to-noise ratio and contrast-to-noise ratio for fMRI data. PLoS ONE, 8(11).

See Also
--------

:doc:`fmri_snri <fmri_snri>` · :doc:`fmri_snrt <fmri_snrt>`

