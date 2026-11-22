fmri_acfestimate
================

Estimates the spatial smoothing KERNEL of the data.

Description
-----------

Estimates the mean smoothing kernel of pseudo-normal statistical images (pn-SI) by correlating phase-randomised regressors with brain data. This is the first step of the cluster-size correction procedure (Ledberg et al., 1998).

The ACF of the statistical image P has Fourier transform \|P_hat\|^2 (Wiener-Khinchin); white noise filtered by K gives an image whose ACF has Fourier transform \|K_hat\|^2. Requiring the two to match gives \|K_hat\| = \|P_hat\|, hence K = IFT\|FFT(P)\|, which is why the code takes abs(fftn(.)) and not abs(fftn(.)).^2.

fmri_csdist convolves white noise with this output, so it requires the KERNEL.

Usage
-----

.. code-block:: matlab

   acf_vol = fmri_acfestimate(datapath, regr, n_perm)
   [acf_vol, calib] = fmri_acfestimate(datapath, regr, n_perm, calibrate)

Inputs
------

- **DATAPATH** -- Path to directory containing vectorized fMRI data (.mat files). Each file should contain one variable: a (228453 x T) matrix; If a file holds several, the first variable is used.
- **REGR** -- Regressor matrix (T x R) for R regressors of interest.
- **N_PERM** -- Number of phase-randomisations per subject per regressor. Default: 10. More = better ACF estimate but slower.
- **CALIBRATE** -- Logical. Default FALSE, which reproduces the behaviour of the original implementation exactly. When TRUE, the kernel is replaced by an isotropic Gaussian tuned so that images simulated from it are as smooth as the data. This corrects a known bias: the estimated kernel comes out too narrow, so "the size threshold will be too liberal" (Ledberg et al., p. 116). They inflate the kernel "by adding a constant at small lags", and note that this "needs to be further investigated" (p. 125). The bias is larger here because the statistical image is zero outside the brain, and that step edge is broadband and narrows the kernel. On synthetic data, the uncalibrated kernel gives simulated images 15-20% less smooth than the data. OFF by default: turning it on changes cluster-size thresholds, and therefore results.

Outputs
-------

- **ACF_VOL** -- Cell array (1 x R), one KERNEL volume per regressor: a 902629 x 1 vector on the full 91x109x91 grid (fmri_csdist reshapes it into a 3D kernel. Each is the mean kernel over subjects and permutations, centred at (46,55,46). Only its shape matters, not its scale: fmri_csdist z-scores every simulated image.

  - **CALIB** -- Struct array (1 x R) reporting the calibration, empty when CALIBRATE is false. Fields: data_fwhm (measured smoothness of the statistical images), sim_fwhm (smoothness achieved by the returned kernel), sigma (the fitted Gaussian width), and ratio (sim_fwhm / data_fwhm, which should be near 1).

Examples
--------

.. code-block:: matlab

   % Step one of the cluster-size correction
   acf = fmri_acfestimate('/data/vectorized', regr, 10);

   % Calibrated, with a check on how well the kernel matched the data
   [acf, calib] = fmri_acfestimate('/data/vectorized', regr, 10, true);
   fprintf('ratio %.3f (1.0 = simulated smoothness matches data)\n', ...
           calib(1).ratio);

References
----------

- Ledberg, A., Akerman, S., & Roland, P.E. (1998). Estimation of the probabilities of 3D clusters in functional brain images. NeuroImage, 8, 113-128.
- Ebisuzaki, W. (1997). J. Climate, 10(6), 2147-2153.

See Also
--------

:doc:`fmri_csdist <fmri_csdist>` · :doc:`fmri_csthreshold <fmri_csthreshold>` · :doc:`fmri_scramblephases <fmri_scramblephases>` · :doc:`fmri_corregressor <fmri_corregressor>`

