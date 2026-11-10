fmri_rsa
========

Representational similarity analysis of a set of condition maps.

Description
-----------

If DATA is a 228453 x N matrix, the neural RDM is computed internally as 1 - fmri_corrmat(data) (correlation distance). If DATA is already an N x N matrix it is used directly as the neural RDM.

The model RDM is compared to the neural RDM using the upper triangle of both matrices (excluding the diagonal), with Spearman correlation by default (the model-to-neural relationship is monotonic but not necessarily linear).

Significance: the entries of an RDM are NOT independent -- each dissimilarity shares a condition with N-2 others -- so the analytic t-test, which treats the N\*(N-1)/2 entries as independent observations, understates the variance of the correlation and returns p-values that are too small. The size of the effect depends on RDM structure: in simulation the analytic false-positive rate stays near nominal for unstructured RDMs but rises into the low-teens percent (at nominal 5%%) for smooth or strongly clustered RDMs. Use the permutation test (NPERM > 0), which shuffles the condition labels (rows and columns of the model RDM together) and is the standard, calibrated test for RSA (Nili et al. 2014). The analytic p is retained only as a quick approximate guide, and a warning is issued (once per session) when used.

Usage
-----

.. code-block:: matlab

   rho                  = fmri_rsa(data, model_rdm)
   [rho, p]             = fmri_rsa(data, model_rdm)
   [rho, p, stats]      = fmri_rsa(data, model_rdm, 'nperm', 5000)
   [rho, p, stats]      = fmri_rsa(data, model_rdm, 'method', 'spearman')

Inputs
------

- **DATA** -- 228453 x N matrix (one map per condition/stimulus), from which the neural RDM is computed as 1 - fmri_corrmat(data), OR a pre-computed N x N neural RDM. A square input that is not 228453 rows is treated as a pre-computed RDM; if you have an ROI dataset that happens to be square (n_voxels equals n_conditions), compute the RDM yourself and pass it, to avoid the ambiguity.
- **MODEL_RDM** -- N x N model RDM (dissimilarity matrix) Values should be dissimilarities (larger = more dissimilar)
- **'method'** -- 'spearman' (default) or 'pearson'
- **'nperm'** -- number of permutations for p-value (default: 0)
- **'tail'** -- 'right' (default), 'left', or 'both'

Outputs
-------

- **RHO** -- scalar correlation between the neural and model RDMs (Spearman or Pearson). This compares whole RDMs; it is not a voxelwise or searchlight map.
- **P** -- p-value. Permutation-based if NPERM > 0 (recommended), else an analytic t-test that is ONLY valid as a rough guide (see note).
- **STATS** -- struct with fields: .z        : Fisher z-score .null     : null distribution (if nperm > 0) .method   : method used .nperm    : number of permutations run .df       : N\*(N-1)/2 - 2, the degrees of freedom of the analytic t-test. Reported for transparency; it is the quantity the independence assumption above overstates, so it is not a usable error estimate for the permutation result.

Examples
--------

.. code-block:: matlab

   % Basic RSA from condition maps
   model_rdm  = 1 - fmri_corrmat(feature_matrix');   % N x N model dissimilarity
   [rho, p]   = fmri_rsa(data, model_rdm)

   % RSA with permutation testing
   [rho, p, stats] = fmri_rsa(data, model_rdm, 'nperm', 5000)

   % Using pre-computed neural RDM
   neural_rdm = 1 - fmri_corrmat(data);
   [rho, p]   = fmri_rsa(neural_rdm, model_rdm)

References
----------

- Kriegeskorte, N., Mur, M. & Bandettini, P. (2008). Representational similarity analysis - connecting the branches of systems neuroscience. Frontiers in Systems Neuroscience, 2, 4.
- Nili, H., Wingfield, C., Walther, A., Su, L., Marslen-Wilson, W. &
- Kriegeskorte, N. (2014). A toolbox for representational similarity analysis. PLoS Computational Biology, 10(4), e1003553.

See Also
--------

:doc:`fmri_corrmat <fmri_corrmat>` · :doc:`fmri_corregressor <fmri_corregressor>` · :doc:`fmri_isc <fmri_isc>`

