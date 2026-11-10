fmri_ttest
==========

Voxelwise t-test across participants.

Description
-----------

Runs a t-test at every voxel and returns the t-statistic, the p-value and the degrees of freedom. Covers the three designs used in fMRI group analysis, and offers a permutation alternative when the normality assumption is doubtful.

Usage
-----

.. code-block:: matlab

   [t, p, df] = fmri_ttest(x)                       % one-sample, x vs 0
   [t, p, df] = fmri_ttest(x, y)                    % two-sample, x vs y
   [t, p, df] = fmri_ttest(x, y, 'paired', true)    % paired
   [t, p, df] = fmri_ttest(x, [], 'nperm', 5000)    % permutation, one-sample

Inputs
------

- **DATA1** -- Voxels x participants. One column per participant.
- **DATA2** -- Optional second group, voxels x participants. Leave empty ([]) for a one-sample test. For a PAIRED test the columns must correspond, i.e. column k of each is the same participant.

*Name-value options*

- **'paired'** -- true for a paired test (requires equal numbers of columns). Default: false.
- **'tail'** -- 'both' (default), 'right' (DATA1 > DATA2), or 'left'.
- **'nperm'** -- 0 (default) for the parametric p-value. Above 0, p comes from a permutation null instead: sign flips for one-sample and paired designs, and group-label shuffles for two-sample designs. The observed t-statistic and degrees of freedom are unchanged; only the method used to calculate p differs. Each permutation recomputes the whole map, so whole-brain analyses can take several minutes. Progress is reported approximately every 10%.

Outputs
-------

- **T** -- Voxels x 1 t-statistic.
- **P** -- Voxels x 1 p-value.
- **DF** -- Degrees of freedom (scalar).

WHICH TEST, AND WHY IT MATTERS FOR fMRI
---------------------------------------

ONE-SAMPLE is the standard group analysis: each participant contributes one map (a contrast, or a Fisher-z transformed correlation), and the question is whether the effect differs from zero across participants. The degrees of freedom are N-1, where N is the number of PARTICIPANTS, not time points. This is why temporal autocorrelation does not enter: the observations being tested are participants, and the null variance is estimated from the spread between them. See fmri_effdf for the separate first-level problem.

TWO-SAMPLE compares independent groups, e.g. patients against controls.

PAIRED compares two conditions measured in the same participants, e.g. pre- against post-intervention. It is a one-sample test on the differences, and is more sensitive than a two-sample test when the pairing is real.

PREPARING THE INPUT
-------------------

If the per-participant maps are CORRELATIONS, transform them before testing:

.. code-block:: matlab

   z_maps = atanh(r_maps);          % variance-stabilising
   [t, p] = fmri_ttest(z_maps);

Use plain atanh, NOT fmri_fisherz. fmri_fisherz returns the standardised test statistic atanh(r)\*sqrt(df-3), which already divides by a standard error; feeding it to a t-test would divide by a standard error twice. See the note in fmri_fisherz.

VOXELS WITH NO VARIANCE, OR WITH MISSING DATA
---------------------------------------------

Where a voxel is constant across participants the standard error is zero and t would be Inf or NaN. The same applies where any participant contributes a non-finite value, which makes the mean and standard deviation non-finite. Such voxels are set to t = 0, p = 1: no variance and no data both mean no evidence, which is the honest reading and keeps the maps finite for downstream cluster steps.

Examples
--------

.. code-block:: matlab

   % Standard group analysis from per-participant correlation maps
   z_maps  = atanh(r_maps);                 % voxels x participants
   [t, p]  = fmri_ttest(z_maps);
   sig     = p < 0.001;
   fmri_showslices(t, 1, 2, [-6 6], [], [], 1, [], fmri_p2t(0.001, size(z_maps,2)-1));

   % Patients vs controls
   [t, p, df] = fmri_ttest(z_patients, z_controls);

   % Permutation p-values, for small N or non-normal data
   [t, p] = fmri_ttest(z_maps, [], 'nperm', 5000);

See Also
--------

:doc:`fmri_p2t <fmri_p2t>` · :doc:`fmri_p2r <fmri_p2r>` · :doc:`fmri_r2p <fmri_r2p>` · :doc:`fmri_fisherz <fmri_fisherz>` · :doc:`fmri_effdf <fmri_effdf>` · :doc:`fmri_cleanclusters <fmri_cleanclusters>` · :doc:`fmri_tfce <fmri_tfce>`

