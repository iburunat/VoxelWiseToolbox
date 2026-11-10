fmri_acfestimate
================

Estimates the spatial smoothing KERNEL of the data.

Description
-----------

Estimates the mean smoothing kernel of pseudo-normal statistical images (pn-SI) by correlating phase-randomised regressors with brain data. This is the first step of the cluster-size correction procedure (Ledberg et al., 1998).

NAMING - READ THIS. The output is called ACF_VOL for backward compatibility, but it is the KERNEL K, not the autocorrelation function. The two are not interchangeable: the ACF of a field convolved with K is the autocorrelation OF K, so K is the Fourier-domain square root of the ACF. Ledberg's Eqs. 5-6 give ACF_P <-> \|P_hat\|^2 and ACF_S <-> \|K_hat\|^2; equating them yields \|K_hat\| = \|P_hat\|, which is why the code takes abs(fftn(.)) and not abs(fftn(.)).^2.

fmri_csdist convolves white noise with this output, so it requires the KERNEL. Supplying a true ACF instead produces simulated images about sqrt(2) too wide, and hence a cluster-size threshold that is too high. Earlier versions of this help described the output as an autocorrelation, which is the error the function itself warns against at the fftn call below.

Usage
-----

.. code-block:: matlab

   acf_vol = fmri_acfestimate(datapath, regr, n_perm)
   [acf_vol, calib] = fmri_acfestimate(datapath, regr, n_perm, calibrate)

Inputs
------

- **DATAPATH** -- Path to directory containing vectorized fMRI data (.mat files). Each file should contain one variable: a (228453 x T) matrix.
- **REGR** -- Regressor matrix (T x R) for R regressors of interest.
- **N_PERM** -- Number of phase-randomisations per subject per regressor. Default: 10. More = better ACF estimate but slower.
- **CALIBRATE** -- Logical. Default FALSE, which reproduces the behaviour of the original implementation exactly. When TRUE, the kernel is replaced by an isotropic Gaussian whose width is tuned so that images simulated from it have the same spatial autocorrelation as the data. This addresses a known bias in the method: Ledberg et al. state (p. 2130) that their acf estimator is biased low, so "the size threshold will be too liberal", and that they "inflated the filter kernel until the simulated images obtain the desired acf". They give no procedure beyond "adding a constant at small lags", and note the issue "needs to be further investigated". The bias is larger here than the small-sample effect they describe, because the statistical image is zero outside the brain and the resulting step edge is broadband, which narrows IFT\|FFT\|. Measured on synthetic data, the uncalibrated kernel yields simulated images about 15-20% less smooth than the data. Calibration is OFF by default because turning it on changes cluster-size thresholds and therefore results.

Outputs
-------

- **ACF_VOL** -- Cell array (1 x R), one KERNEL volume (902629 x 1) per regressor, i.e. the FULL 91x109x91 grid rather than the 228453 in-mask voxels, because fmri_csdist reshapes it to a 3D kernel. Each volume is the mean smoothing kernel across subjects and permutations, normalised to a peak of 1 and centred on the volume centre (46,55,46). It is NOT an autocorrelation function - see the naming note above.
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

