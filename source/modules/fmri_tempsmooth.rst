fmri_tempsmooth
===============

Temporal Gaussian smoothing of fMRI time series.

Description
-----------

Convolves each voxel time series with a Gaussian kernel, suppressing high-frequency noise while preserving low-frequency BOLD signal. Useful as a preprocessing step before analyses that assume a slow haemodynamic response.

Usage
-----

.. code-block:: matlab

   newdata = fmri_tempsmooth(data)
   newdata = fmri_tempsmooth(data, sigma)
   newdata = fmri_tempsmooth(data, sigma, TR)

Inputs
------

- **DATA** -- fMRI time series, in any accepted layout: 228453 x T          canonical (voxels x time) 91 x 109 x 91 x T   volume
- **SIGMA** -- Standard deviation of the Gaussian kernel, in SECONDS. Default: 4 s. The corresponding full width at half maximum is FWHM = 2.355 \* SIGMA, so sigma = 4 s gives FWHM = 9.4 s.
- **TR** -- Repetition time in seconds. Default: 2.

Outputs
-------

- **NEWDATA** -- Temporally smoothed data, in the same layout as DATA.

Examples
--------

.. code-block:: matlab

   data = fmri_tempsmooth(data);              % sigma = 4 s, TR = 2 s
   data = fmri_tempsmooth(data, 4, 2);        % same, stated explicitly
   data = fmri_tempsmooth(data, 3, 0.72);     % sigma 3 s, multiband TR

   % To specify smoothing by FWHM instead of sigma:
   fwhm = 6;                                  % seconds
   data = fmri_tempsmooth(data, fwhm / 2.355, TR);

Notes
-----

SIGMA is given in seconds and TR is supplied explicitly, so the amount of smoothing is the same physical duration regardless of the sampling rate. Earlier versions of the toolbox built the kernel on a fixed -32:2:32 grid, which silently assumed TR = 2 s. Calls of the form fmri_tempsmooth(data, 4) therefore behave exactly as before, but the function is now correct at any TR. Note that some earlier documentation described SIGMA as being in scans; this was incorrect, and the unit has always effectively been seconds.

The kernel is normalised to sum to one, so smoothing changes the temporal shape of the signal but not its amplitude. (Earlier versions omitted this normalisation and scaled the data by roughly 0.5. Correlation is invariant to scale, so correlation-based results are unaffected, but amplitude-based measures such as tSNR, percent signal change and GLM betas were affected.)

The kernel spans +/- 4 sigma and is truncated at the run boundaries, so edge effects may be present in the first and last ~4 sigma of the run.

For frequency-domain bandpass filtering use fmri_bandpassfilter instead.

See Also
--------

:doc:`fmri_bandpassfilter <fmri_bandpassfilter>` · :doc:`fmri_detrend <fmri_detrend>`

