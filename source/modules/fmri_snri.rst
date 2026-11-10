fmri_snri
=========

Image-domain signal-to-noise ratio (SNR-i) for each fMRI scan.

Description
-----------

Computes the image SNR for each time point as the ratio of the mean signal across all brain voxels to its standard deviation:

.. code-block:: matlab

   SNR-i = mean(S_t) / std(S_t)

A high SNR-i indicates that signal variation across voxels within a scan is small relative to the mean, suggesting low inter-voxel noise.

Usage
-----

.. code-block:: matlab

   SNR = fmri_snri(v)

Inputs
------

- **V** -- fMRI data, vectorized (228453 x T) or volume (91 x 109 x 91 x T).

Outputs
-------

- **SNR** -- Image SNR per time point (T x 1).

Examples
--------

.. code-block:: matlab

   snr = fmri_snri(data);
   plot(snr); xlabel('Scan'); ylabel('SNR-i')

See Also
--------

:doc:`fmri_snrt <fmri_snrt>` · :doc:`fmri_cnr <fmri_cnr>`

