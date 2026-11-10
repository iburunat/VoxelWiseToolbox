demo_wiener
===========

DEMO_WIENER  Wiener deconvolution of a simulated BOLD signal
------------------------------------------------------------

Builds a known neural signal, convolves it with the canonical HRF to make a synthetic BOLD response, then recovers the neural signal with fmri_wiener and compares the result against the ground truth.

**The demo is in two parts:**

PART 1  The call itself: one line, and a before/after figure. This is all

you need to use the function.

.. code-block:: matlab

   PART 2  (optional) How to choose the regularisation parameter, and why the
           correlation with the truth is a poor criterion for choosing it.
           Skip it on a first read; come back when a recovery looks wrong.

**Functions demonstrated:**

fmri_wiener, fmri_doublegamma, fmri_corrmat

See Also
--------

:doc:`fmri_wiener <../modules/fmri_wiener>` · :doc:`fmri_doublegamma <../modules/fmri_doublegamma>` · :doc:`fmri_xcorr <../modules/fmri_xcorr>`

