fmri_bandpassfilter
===================

Non-causal FFT-based bandpass filter for fMRI time series.

Description
-----------

Applies a sharp (brick-wall) bandpass filter in the frequency domain by zeroing all FFT coefficients outside the specified band. Because the filter is applied in the frequency domain and the result is the real part of the inverse FFT, it is non-causal (zero phase shift) and free of the order- dependent edge effects of causal digital filters. Suitable for resting-state fMRI (for example a 0.01-0.1 Hz band) and for task-based filtering.

Usage
-----

.. code-block:: matlab

   data_filt = fmri_bandpassfilter(data, fs, f_low, f_high)

Inputs
------

- **DATA** -- fMRI time series, in any accepted layout: 228453 x T          canonical (voxels x time) 91 x 109 x 91 x T   volume A single time series (1 x T) is also accepted, which is useful for filtering a stimulus regressor with the same filter as the data.
- **FS** -- Sampling frequency in Hz (= 1 / TR). For TR = 2 s, fs = 0.5.
- **F_LOW** -- Low cutoff in Hz; frequencies below this are removed. E.g. 0.01. Set to 0 for a low-pass filter only.
- **F_HIGH** -- High cutoff in Hz; frequencies above this are removed. E.g. 0.10. Set to Inf for a high-pass filter only.

Outputs
-------

- **DATA_FILT** -- Filtered data, in the same layout as DATA.

Examples
--------

.. code-block:: matlab

   % Resting-state bandpass (TR = 2 s)
   data = fmri_bandpassfilter(data, 0.5, 0.01, 0.10);

   % High-pass only: remove drift below 0.008 Hz (TR = 1.5 s)
   data = fmri_bandpassfilter(data, 1/1.5, 0.008, Inf);

   % Apply the same filter to a stimulus regressor
   regr = fmri_bandpassfilter(regr(:).', 0.5, 0.01, 0.10);

Notes
-----

A brick-wall filter has a perfectly sharp transition band, at the cost of ringing in the time domain (Gibbs phenomenon) for signals with sharp transients. For fMRI time series, which are dominated by low frequencies, this is rarely a practical concern.

Any regressor to be correlated with filtered data should be filtered with the same band, so that both share the same frequency support.

See Also
--------

:doc:`fmri_detrend <fmri_detrend>` · :doc:`fmri_tempsmooth <fmri_tempsmooth>` · :doc:`fmri_correctmovement <fmri_correctmovement>`

