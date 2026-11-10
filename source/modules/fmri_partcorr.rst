fmri_partcorr
=============

Voxelwise partial correlation with confounds removed.

Description
-----------

Computes the partial correlation between a brain map Y and a regressor x, controlling for one or more confound variables Z, at every voxel. The observations are usually participants, which makes this a second-level analysis; they can equally be time points, for a first-level use.

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

All inputs are z-scored internally. Y, x and Z must agree on the number of OBSERVATIONS - which for Y is whichever of its two dimensions is not 228453, since either orientation is accepted.

For significance testing, pass RHO to fmri_r2p. fmri_r2p expects an EFFECTIVE SAMPLE SIZE (it applies the Fisher sqrt(df-3) internally), so controlling q = size(Z,2) nuisance regressors means reducing that sample size by q. With N observations:

- **p = fmri_r2p(rho, N** -- size(Z,2));                  % independent
- **p = fmri_r2p(rho, fmri_effdf(x, x)** -- size(Z,2));   % autocorrelated

The second form is for a FIRST-level use, where the observations are time points. At the second level the observations are participants and are independent, so the first form applies (Section 6.2 of the paper makes the same point about the group t-test). Do NOT subtract an extra 2: that would double-count, since fmri_r2p already accounts for the estimated correlation via sqrt(df-3).

See Also
--------

:doc:`fmri_corregressor <fmri_corregressor>` · :doc:`fmri_r2p <fmri_r2p>` · :doc:`fmri_effdf <fmri_effdf>`

