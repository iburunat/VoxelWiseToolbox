fmri_csdist
===========

Null cluster-size distribution from a smoothing kernel.

Description
-----------

Generates the null distribution of cluster sizes at one or more statistical thresholds by convolving the estimated smoothing kernel with Gaussian noise and recording the resulting cluster sizes. This is the second step of the Ledberg et al. (1998) cluster-size correction procedure.

Usage
-----

.. code-block:: matlab

   D = fmri_csdist(acf_vol)
   D = fmri_csdist(acf_vol, si_alpha)
   D = fmri_csdist(acf_vol, si_alpha, n_perm)
   D = fmri_csdist(acf_vol, si_alpha, n_perm, calib)

Inputs
------

- **ACF_VOL** -- Cell array {1 x R} of kernel volumes, one per regressor, as returned by fmri_acfestimate. Each cell holds a 902629 x 1 vector, i.e. the full 91x109x91 grid. A single volume may be passed outside a cell.
- **SI_ALPHA** -- Voxel-level threshold(s) as alpha PER TAIL. Null maps are thresholded at abs(z) > -norminv(SI_ALPHA), so both tails are retained and the total two-sided voxel rate is 2\*SI_ALPHA. A map thresholded with a two-tailed p must therefore pass p/2 here. Default: [0.01 0.001 0.0001]
- **N_PERM** -- Number of random images to generate. Default: 1000, matching Alluri et al. (2012). The critical size is fixed by wherever the survival curve crosses the FWER level, so only about alpha\*N_PERM images actually determine it. Simulated standard deviation of the resulting threshold: N_PERM    SD (voxels)   as % of a 22-voxel threshold 100         13              59% 500          6              27% 1000          4              18% 2000          3              14% The previous default of 100 gave an SD of roughly half the threshold itself for the small thresholds typical at strict SI alphas. Ledberg et al. used 9000, which is what their own Eq. 11 requires for the confidence half-width to fall within 10% of alpha. A warning is issued below 500.
- **CALIB** -- The second output of fmri_acfestimate when called with CALIBRATE true. Passing it suppresses the kernel truncation warning, which does not apply to a calibrated kernel: the calibration fits the width using the same 11x11x11 crop, so a high boundary value is already accounted for. Default: [].

Outputs
-------

- **D** -- Cluster-size distribution as a cell array {1 x R}. D{r} is a (500 x length(SI_ALPHA)) matrix. D{r}(k, zi) is the empirical probability that a null image contains at least one cluster LARGER THAN k voxels at threshold zi. The row index is therefore an exclusive bound, which is what fmri_csthreshold expects. Sizes above 500 are not tabulated. A warning is issued if the distribution has not decayed by then, since thresholds derived from a truncated distribution are underestimates.

DEPENDENCY
----------

standard_brain.mat, which ships with the toolbox and holds BR, the 91 x 109 x 91 binary brain mask. fmritoolbox_setup puts it on the path. Clusters are counted inside that mask only, so the null distribution is built over the same search volume the real analysis used.

Examples
--------

.. code-block:: matlab

   % Steps one and two of the correction, publication settings
   acf = fmri_acfestimate('/data/vectorized', regr, 10);
   D   = fmri_csdist(acf, [0.01 0.001 0.0001], 1000);

   % Calibrated kernel: passing CALIB skips the truncation check
   [acf, calib] = fmri_acfestimate('/data/vectorized', regr, 10, true);
   D = fmri_csdist(acf, [0.01 0.001 0.0001], 1000, calib);

   % A quick, deliberately noisy run while setting a pipeline up
   D = fmri_csdist(acf, 0.001, 100);   % warns: threshold SD ~13 voxels

References
----------

- Ledberg, A., Akerman, S., & Roland, P.E. (1998). NeuroImage, 8, 113-128.

See Also
--------

:doc:`fmri_acfestimate <fmri_acfestimate>` · :doc:`fmri_csthreshold <fmri_csthreshold>` · :doc:`fmri_cleanclusters <fmri_cleanclusters>`

