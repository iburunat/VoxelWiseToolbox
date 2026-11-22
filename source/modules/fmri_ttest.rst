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
- **'nperm'** -- Number of permutations used to calculate p-values. Default: 0, which uses the parametric t-distribution. For one-sample and paired tests, permutations randomly flip participant signs; for two-sample tests, they shuffle group labels. The observed t-statistic and degrees of freedom are unchanged. Whole-brain permutation tests may take several minutes, with progress reported approximately every 10%.

Outputs
-------

- **T** -- Voxels x 1 t-statistic.
- **P** -- Voxels x 1 p-value.
- **DF** -- Degrees of freedom (scalar).

CHOOSING THE TEST
-----------------

ONE-SAMPLE tests whether participant-level values differ from zero. In a typical group analysis, each participant contributes one contrast map or Fisher-z-transformed correlation map. The degrees of freedom are N-1, where N is the number of participants. Temporal autocorrelation is a first-level concern and does not enter this group-level test.

TWO-SAMPLE compares two independent groups, such as patients and controls.

PAIRED compares two measurements from the same participants, such as pre- and post-intervention values. It is equivalent to a one-sample test on the within-participant differences.

PREPARING CORRELATION MAPS
--------------------------

**Transform participant-level correlation maps before testing:**

.. code-block:: matlab

   z_maps = atanh(r_maps);
   [t, p] = fmri_ttest(z_maps);

Use ATANH rather than fmri_fisherz. fmri_fisherz also standardises the transformed correlations by sqrt(df-3), which is not appropriate before a group t-test.

CONSTANT OR NON-FINITE VOXELS
-----------------------------

Voxels with zero variance across participants, or with any non-finite participant value, cannot produce a valid t-statistic. They are returned as t = 0 and p = 1, keeping the output finite for subsequent analyses.

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

