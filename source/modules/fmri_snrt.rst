fmri_snrt
=========

Temporal signal-to-noise ratio (tSNR) for each brain voxel.

Description
-----------

Computes the temporal SNR for each voxel as the ratio of the mean signal across time to its temporal standard deviation:

.. code-block:: matlab

   tSNR = mean(S_v) / std(S_v)

A high tSNR voxelwise map indicates stable signal; low values indicate noisy or artefact-prone voxels. Standard quality metric for fMRI data.

Usage
-----

.. code-block:: matlab

   SNR = fmri_snrt(v)

Inputs
------

- **V** -- fMRI data, vectorized (228453 x T) or volume (91 x 109 x 91 x T).

Outputs
-------

- **SNR** -- Temporal SNR map (228453 x 1). Visualise with fmri_showslices.

Examples
--------

.. code-block:: matlab

   tsnr = fmri_snrt(data);
   fmri_showslices(tsnr, 1, 2, [0 100])

See Also
--------

:doc:`fmri_snri <fmri_snri>` · :doc:`fmri_cnr <fmri_cnr>`

