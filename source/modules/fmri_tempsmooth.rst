fmri_tempsmooth
===============

Temporal Gaussian smoothing of fMRI time series.

Description
-----------

Smooths each voxel time series by convolving it with a Gaussian kernel, reducing rapid temporal fluctuations while retaining slower signal changes.

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

SIGMA is specified in seconds, and TR determines the spacing of the Gaussian kernel samples. This gives the smoothing width a consistent physical duration across different sampling rates.

The kernel is normalised to sum to one, preserving constant signal levels away from the run boundaries.

The kernel extends to approximately +/- 4 SIGMA. At the beginning and end of the run, part of the kernel falls outside the available data, which may attenuate values within approximately 4 SIGMA of each boundary.

For frequency-domain bandpass filtering use fmri_bandpassfilter instead.

See Also
--------

:doc:`fmri_bandpassfilter <fmri_bandpassfilter>` · :doc:`fmri_detrend <fmri_detrend>`

