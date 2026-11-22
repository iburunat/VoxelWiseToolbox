fmri_wiener
===========

Wiener deconvolution: estimate neural signal from BOLD response.

Description
-----------

Estimates the underlying neural activity time series from an observed BOLD signal using Wiener deconvolution. The method works in the frequency domain: it divides the BOLD spectrum by the HRF spectrum while applying a regulariser (the noise term) to suppress amplification of noise at frequencies where the HRF has low power.

Usage
-----

.. code-block:: matlab

   neural = fmri_wiener(bold, hrf, noise_level)

Inputs
------

- **BOLD** -- Observed BOLD time series (N x 1). Will be mean-centred.
- **HRF** -- Haemodynamic response function sampled at the same rate as BOLD (M x 1). Does not need to be the same length as BOLD; it will be zero-padded to match. A canonical HRF can be generated with fmri_doublegamma.
- **NOISE_LEVEL** -- Regularisation strength: the assumed noise magnitude as a fraction of the mean BOLD spectral amplitude, so the filter's noise term is (NOISE_LEVEL \* mean\|FFT(BOLD)\|)^2. Typical range: 0.05 to 0.20. Default: 0.1

Outputs
-------

- **NEURAL** -- Estimated neural time series (N x 1), same length as BOLD.

Examples
--------

.. code-block:: matlab

   % Generate canonical HRF at TR = 2s
   t   = 0:2:32;
   hrf = fmri_doublegamma(t);

   % Deconvolve BOLD signal from one voxel
   bold_ts = data(voxel_idx, :)';
   neural  = fmri_wiener(bold_ts, hrf', 0.1);

Notes
-----

Results are sensitive to the noise_level parameter. Too low: noisy output. Too high: over-smoothed, response is blurred. Values of 0.05-0.20 are typically reasonable for standard fMRI data.

The deconvolution is circular: the HRF tail wraps from the end of the run into the start, so the first numel(HRF) samples of NEURAL are unreliable. Discard them, or pad BOLD before calling.

References
----------

- Wiener, N. (1949). Extrapolation, Interpolation, and Smoothing of Stationary Time Series. MIT Press.

See Also
--------

:doc:`fmri_doublegamma <fmri_doublegamma>` · :doc:`fmri_corregressor <fmri_corregressor>` · :doc:`fmri_detrend <fmri_detrend>`

