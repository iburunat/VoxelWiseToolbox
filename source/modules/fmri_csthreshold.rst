fmri_csthreshold
================

Extracts critical cluster sizes from a CS distribution.

Description
-----------

Given a cluster-size (CS) null distribution (from fmri_csdist), extracts the critical cluster size at one or more family-wise error rate (FWER) levels. This is the third and final step of the Ledberg et al. (1998) procedure.

Usage
-----

.. code-block:: matlab

   [CSIZE, report] = fmri_csthreshold(D, si_alpha, cs_alpha)

Inputs
------

- **D** -- CS distribution cell array {1 x R}, as returned by fmri_csdist.
- **SI_ALPHA** -- Statistical image alpha levels used to generate D (per tail; see fmri_csdist). Default: [0.01 0.001 0.0001]
- **CS_ALPHA** -- FWER alpha level(s) for cluster-size thresholding. Default: [0.05 0.01 0.001]

Outputs
-------

- **CSIZE** -- Cell array {1 x R}. Each cell is a (length(SI_ALPHA) x length(CS_ALPHA)) matrix of MINIMUM SURVIVING cluster sizes: a cluster of at least the returned size survives correction, which is the convention fmri_cleanclusters and fmri_findclusters compare with >=.
- **REPORT** -- Formatted string summarising the critical cluster sizes, suitable for printing (disp(report)) or saving to a file.
- **CS_TABLE** -- Cell array {1 x R}, one table per regressor. Rows are SI alpha levels and columns are FWER alpha levels, named CS_FWER_0_05, CS_FWER_0_01 and so on, with a leading SI_alpha column giving the statistical-image thresholds. CS_TABLE{1} is the table for regressor #1. Built only when a third output is requested.

Examples
--------

.. code-block:: matlab

   % Full pipeline
   acf   = fmri_acfestimate(datapath, regressor, 10);
   D     = fmri_csdist(acf, [0.001 0.0001], 1000);
   [CS, report] = fmri_csthreshold(D, [0.001 0.0001], [0.05 0.01]);
   disp(report)

   % Apply the threshold to a z-map. 0.001 is the per-tail alpha and both
   % tails are taken, matching how fmri_csdist formed the null clusters.
   z_thresh = abs(zmap) > fmri_p2t(0.001, 1e6, 1);
   clean    = fmri_cleanclusters(z_thresh, CS{1}(1,1), 0);

References
----------

- Ledberg, A., Akerman, S., & Roland, P.E. (1998). NeuroImage, 8, 113-128.

See Also
--------

:doc:`fmri_acfestimate <fmri_acfestimate>` · :doc:`fmri_csdist <fmri_csdist>` · :doc:`fmri_cleanclusters <fmri_cleanclusters>` · :doc:`fmri_tfce <fmri_tfce>`

