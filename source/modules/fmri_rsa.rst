fmri_rsa
========

Representational similarity analysis of a set of condition maps.

Description
-----------

Compares the dissimilarity structure of a set of brain maps with the structure a model predicts. A neural RDM is built from the condition maps, or supplied ready-made, and the upper triangles of the two RDMs are correlated to give a single scalar for the whole set, not a voxelwise map. Set 'nperm' above zero for the calibrated permutation test.

.. code-block:: matlab

   If DATA contains condition maps (228453 x N), the neural RDM is computed
   as correlation distance: 1 - fmri_corrmat(data). An N x N input is treated
   as a pre-computed neural RDM.

The neural and model RDMs are compared using their upper triangles, excluding the diagonal. Spearman correlation is used by default.

For significance testing, use NPERM > 0. RDM entries are not independent because each condition contributes to several dissimilarities, making the analytic p-value potentially too small. The permutation test preserves the RDM structure by shuffling condition labels in the model RDM. The analytic p-value is retained only as a quick approximation and produces a warning.

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

