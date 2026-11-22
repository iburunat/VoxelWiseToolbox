fmri_partcorr
=============

Computes voxelwise partial correlations controlling for confounds.

Description
-----------

At each voxel, correlates the brain data Y with the regressor x after removing the effects of one or more confound variables Z. Observations may be participants in a second-level analysis or time points in a first-level analysis.

**The partial correlation is obtained by:**

1. Regressing Z out of both x and Y (separately)
2. Correlating the residuals

Usage
-----

.. code-block:: matlab

   rho = fmri_partcorr(Y, x, Z)

Inputs
------

- **Y** -- Brain data: one vectorised map per observation, in either layout. 228453 x N is canonical and matches every other function; N x 228453 is also accepted. N is participants for a second-level analysis, or time points for a first-level one.
- **X** -- Regressor of interest, (observations x 1). At the second level a participant-level variable such as age, a behavioural score or group membership; at the first level, a time-varying regressor.
- **Z** -- Confound regressors, (observations x C) for C confounds. E.g. [age, sex, total-intracranial-volume].

Outputs
-------

- **RHO** -- Partial correlation map, vectorized (228453 x 1). Values are Pearson r after controlling for Z.

Examples
--------

.. code-block:: matlab

   % Correlate musical ability with brain activity, controlling for age
   rho = fmri_partcorr(subj_maps, musical_score, age_vector);
   fmri_showslices(rho, 1, 2, [0.2 0.7])

   % Multiple confounds
   rho = fmri_partcorr(subj_maps, IQ, [age, sex, education]);

Notes
-----

All inputs are z-scored internally. Y, x and Z must contain the same number of observations. In Y, observations correspond to the dimension other than the 228453-voxel dimension.

To obtain p-values, pass RHO and the adjusted sample size to fmri_r2p. Subtract one for each confound in Z:

- **p = fmri_r2p(rho, N** -- size(Z,2));                  % independent observations
- **p = fmri_r2p(rho, fmri_effdf(x,x)** -- size(Z,2));    % autocorrelated time points

Use the first form for independent observations, such as participants in a group analysis, and the second for autocorrelated time-series data. Do not subtract an additional 2, because fmri_r2p already applies the Fisher correction using sqrt(df-3).

See Also
--------

:doc:`fmri_corregressor <fmri_corregressor>` · :doc:`fmri_r2p <fmri_r2p>` · :doc:`fmri_effdf <fmri_effdf>`

