demo_tempsmooth
===============

DEMO_TEMPSMOOTH  Temporal Gaussian smoothing of fMRI time series
----------------------------------------------------------------

Demonstrates fmri_tempsmooth by applying temporal smoothing to a simulated fMRI time series with different sigma values and comparing the effect on signal quality and frequency content.

**Functions demonstrated:**

fmri_tempsmooth, fmri_doublegamma, fmri_corrmat

NOTE ON UNITS: fmri_tempsmooth's SIGMA is in SECONDS, not scans. Always pass TR explicitly so the conversion is unambiguous.

See Also
--------

:doc:`fmri_tempsmooth <../modules/fmri_tempsmooth>` · :doc:`fmri_bandpassfilter <../modules/fmri_bandpassfilter>` · :doc:`fmri_detrend <../modules/fmri_detrend>`

