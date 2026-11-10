fmri_detrend
============

Removes low-frequency drift from fMRI data using spline fitting.

Description
-----------

Fits a cubic spline through a set of equally-spaced anchor points along the temporal dimension and subtracts it from the data. This removes slow drifts (scanner drift, respiratory and movement artefacts) while preserving higher-frequency BOLD signal. Operates voxelwise.

Usage
-----

.. code-block:: matlab

   newdata = fmri_detrend(data)
   newdata = fmri_detrend(data, no_of_anchor_points)

Inputs
------

- **DATA** -- fMRI time series, in any accepted layout: 228453 x T          canonical (voxels x time) 91 x 109 x 91 x T   volume
- **NO_OF_ANCHOR_POINTS** -- Number of spline knots. More knots removes slower drift more thoroughly, but risks attenuating genuine slow BOLD responses. Default: 6.

Outputs
-------

- **NEWDATA** -- Detrended data, in the same layout as DATA. Each voxel time series is also mean-centred.

Examples
--------

.. code-block:: matlab

   data = fmri_detrend(data);          % default 6 knots
   data = fmri_detrend(data, 4);       % gentler detrending
   data = fmri_detrend(data, 10);      % more aggressive

Notes
-----

Anchor values are the mean of the scans nearest each knot. Because the first and last knots sit at the ends of the run, they have neighbours on one side only, and so are estimated from about half as many scans as the interior knots (for T = 150 and 6 knots: 15, 30, 30, 30, 30, 15). The fitted drift is therefore somewhat less well determined at the very start and end of a run -- an edge effect shared, in some form, by all drift removal methods, including SPM's DCT high-pass filter. This behaviour is deliberately preserved for consistency with results published using earlier versions of the toolbox.

For high-pass filtering in the frequency domain, see fmri_bandpassfilter.

See Also
--------

:doc:`fmri_tempsmooth <fmri_tempsmooth>` · :doc:`fmri_bandpassfilter <fmri_bandpassfilter>` · :doc:`fmri_zscorevoldata <fmri_zscorevoldata>`

