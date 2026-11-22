fmri_isc
========

Voxelwise intersubject correlation (ISC).

Description
-----------

Computes intersubject correlation (ISC) at each voxel, measuring the similarity of participants' time series while they experience the same stimulus. Participant data can be supplied as an in-memory array or read from disk one participant at a time, allowing full-resolution datasets to be analysed with substantially lower memory requirements.

Leave-one-out ISC (Hasson et al., 2004): at each voxel, correlate each participant's time series with the mean of the others, then average the correlations in Fisher-z space.

Pairwise ISC: at each voxel, correlate every pair of participants and average the N\*(N-1)/2 correlations in Fisher-z space. Values are typically lower than leave-one-out ISC because a group mean is generally less noisy than an individual time series.

.. code-block:: matlab

   Permutation p-values: independently phase-scramble each participant's time
   series at every voxel, preserving its power spectrum while disrupting
   intersubject synchrony. The p-value is the proportion of permutations with
   ISC equal to or greater than the observed value, using a standard +1
   correction to prevent p = 0.

Usage
-----

.. code-block:: matlab

   isc      = fmri_isc(data)
   isc      = fmri_isc(data, method)
   [isc, p] = fmri_isc(data, method, n_perm)

Inputs
------

- **DATA** -- Participants' time series, in any of three forms: \* 228453 x T x N numeric array (all participants in memory) \* cell array of paths to .mat files, one per participant \* path to a directory containing one .mat file per participant The latter two options read one participant at a time and are recommended for full-resolution datasets. For example, data with 228453 voxels, 451 volumes and 15 participants require 12.4 GB in memory, compared with about 1.7 GB when streamed. Each .mat file must contain a single variable, or one named 'data' or 'voldata'. Streaming supports only 'leaveoneout' without permutations. Pairwise ISC and permutation testing require repeated access to every participant and are therefore available only for in-memory data.
- **METHOD** -- 'leaveoneout' (default) or 'pairwise'.
- **N_PERM** -- Number of phase-scrambling permutations for p-values (default 0, no permutation testing).

Outputs
-------

- **ISC** -- 228453 x 1 vector of ISC values, obtained by Fisher-z averaging participant correlations. Voxels where the correlation is undefined, such as a zero-variance time series in any participant, are returned as NaN.
- **P** -- 228453 x 1 vector of permutation p-values, or [] if N_PERM = 0. Voxels with non-finite ISC are assigned p = 1.

Examples
--------

.. code-block:: matlab

   isc = fmri_isc(data);
   [isc, p] = fmri_isc(data, 'leaveoneout', 1000);
   fmri_showslices(isc .* (p < 0.05), 1, 2, [0.1 0.6]);

References
----------

- Hasson, U., Nir, Y., Levy, I., Fuhrmann, G. & Malach, R. (2004). Intersubject synchronization of cortical activity during natural vision.
- Science, 303(5664), 1634-1640.
- Nastase, S.A., Gazzola, V., Hasson, U. & Keysers, C. (2019). Measuring shared responses across subjects using intersubject correlation. Social Cognitive and Affective Neuroscience, 14(6), 667-685.

See Also
--------

:doc:`fmri_corrvoldata <fmri_corrvoldata>` · :doc:`fmri_fisherz <fmri_fisherz>` · :doc:`fmri_scramblephases <fmri_scramblephases>`

