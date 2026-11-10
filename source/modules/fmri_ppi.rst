fmri_ppi
========

Voxelwise psychophysiological interaction (PPI) analysis.

Description
-----------

Fits the PPI model of Friston et al. (1997) at every voxel and returns the interaction beta: where connectivity with a seed region CHANGES as a function of a psychological variable.

Usage
-----

.. code-block:: matlab

   beta_ppi = fmri_ppi(data, seed_mask, psych)
   [beta_ppi, beta_seed, beta_psych] = fmri_ppi(data, seed_mask, psych)

Inputs
------

- **DATA** -- fMRI time series, vectorized (228453 x T).
- **SEED_MASK** -- Seed region, 228453 x 1, logical or binary. The seed time series is the mean across its voxels.
- **PSYCH** -- Psychological regressor, T x 1, ALREADY CONVOLVED with the HRF. For a block design this is a boxcar convolved with the HRF; for a naturalistic paradigm it is a continuous stimulus feature (acoustic envelope, event-boundary density) convolved likewise. Convolve with fmri_doublegamma before calling - the function does not do it for you, so the same regressor can be reused across analyses.

Outputs
-------

- **BETA_PPI** -- 228453 x 1, the INTERACTION beta. The quantity of interest.
- **BETA_SEED** -- 228453 x 1, seed main effect (task-independent connectivity).
- **BETA_PSYCH** -- 228453 x 1, psychological main effect (task activation).

**The model:**

.. code-block:: matlab

   Y = b_ppi*(seed .* psych) + b_seed*seed + b_psych*psych + b_0 + e

The two main effects are included as nuisance terms so that BETA_PPI reflects connectivity change attributable to the interaction, over and above seed activity and task activation on their own. Omitting them makes the interaction term absorb both, and the result is not a PPI.

A METHODOLOGICAL LIMITATION, STATED PLAINLY

The interaction is formed in the BOLD domain, as in the original Friston formulation: the measured seed time series is multiplied by the convolved psychological regressor. Gitelman et al. (2003) showed this is biased, because the interaction is a NEURAL event and convolution does not commute with multiplication:

.. code-block:: matlab

   conv(neural_seed .* psych, hrf)  ~=  conv(neural_seed, hrf) .* psych

The stricter approach deconvolves the seed to the neural domain, forms the interaction there, and reconvolves. This toolbox ships fmri_wiener for the deconvolution step, so that route is available:

.. code-block:: matlab

   seed_neural = fmri_wiener(seed_ts, hrf, reg);
   interaction = conv(seed_neural .* psych_neural, hrf);

The BOLD-domain form is retained here because it remains the most widely reported version and is adequate for block designs with long blocks, where the two forms converge. For event-related or fast naturalistic designs the difference matters, and the deconvolved route should be preferred.

A NOTE ON BETA_SEED

The seed regressor is the MEAN over seed voxels, so it carries measurement error. A regressor measured with error has its coefficient attenuated toward zero (regression dilution), so BETA_SEED systematically underestimates the true seed coupling - by about 5% in a smoke test with 10 seed voxels at modest noise. This is inherent to seed-based methods, not specific to this implementation. Larger and cleaner seeds reduce it. BETA_PPI is much less affected, because the interaction term's error is second order.

GROUP INFERENCE
---------------

BETA_PPI is a regression coefficient, not a correlation. Do NOT apply fmri_fisherz to it: that is atanh, defined for correlations in [-1, 1], and betas are unbounded. Collect one beta map per participant and test them directly:

.. code-block:: matlab

   beta_all(:, s) = fmri_ppi(data_s, seed_mask, psych_s);
   [t, p, df]     = fmri_ttest(beta_all);

Examples
--------

.. code-block:: matlab

   % Hippocampal seed, block design
   seed_mask  = fmri_regionmask(57);              % AAL left hippocampus
   hrf        = fmri_doublegamma(0:TR:30)';
   psych_conv = conv(psych_raw, hrf);
   psych_conv = psych_conv(1:size(data, 2));      % causal, trim to T
   beta_ppi   = fmri_ppi(data, seed_mask, psych_conv);

   % Display at the threshold the analysis can actually resolve
   fmri_showslices(beta_ppi, 1, 2, [-0.5 0.5], [], [], 1, [], 0.1);

References
----------

- Friston, K.J., Buechel, C., Fink, G.R., Morris, J., Rolls, E. & Dolan, R.J. (1997). Psychophysiological and modulatory interactions in neuroimaging.
- NeuroImage, 6(3), 218-229.
- Gitelman, D.R., Penny, W.D., Ashburner, J. & Friston, K.J. (2003). Modeling regional and psychophysiologic interactions in fMRI: the importance of hemodynamic deconvolution. NeuroImage, 19(1), 200-207.

See Also
--------

:doc:`fmri_corregressor <fmri_corregressor>` · :doc:`fmri_partcorr <fmri_partcorr>` · :doc:`fmri_regionmask <fmri_regionmask>` · :doc:`fmri_doublegamma <fmri_doublegamma>` · :doc:`fmri_wiener <fmri_wiener>` · :doc:`fmri_ttest <fmri_ttest>`

