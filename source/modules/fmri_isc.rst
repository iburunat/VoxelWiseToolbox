fmri_isc
========

Voxelwise intersubject correlation (ISC).

Description
-----------

Computes, at every in-brain voxel, how strongly participants' time series agree while they receive the same stimulus. Accepts participants as an in-memory array or streams them from disk one at a time, which is what makes a full-resolution cohort affordable.

Leave-one-out ISC (Hasson et al. 2004): for each participant, correlate their voxel time series with the mean of the other participants at the same voxel, then average the correlations across participants in Fisher-z space.

Pairwise ISC: correlate every pair of participants at each voxel and average all N\*(N-1)/2 correlations in Fisher-z space. Pairwise values are typically lower than leave-one-out values, because correlating against a less noisy group mean generally gives a higher correlation than correlating two individual participants.

Permutation p-values: each participant's per-voxel time series is phase- scrambled independently, preserving each voxel's temporal power spectrum while removing intersubject synchrony. The p-value is the fraction of permutations whose ISC reaches the observed one, with the standard +1 correction so it is never exactly zero.

Usage
-----

.. code-block:: matlab

   isc      = fmri_isc(data)
   isc      = fmri_isc(data, method)
   [isc, p] = fmri_isc(data, method, n_perm)

Inputs
------

- **DATA** -- Participants' time series, in any of three forms: \* 228453 x T x N numeric array (all participants in memory) \* cell array of paths to .mat files, one per participant \* path to a directory containing one .mat file per participant The latter two stream from disk and are the practical choice at full resolution: 228453 voxels x 451 volumes x 15 participants is 12.4 GB as an array, and the leave-one-out computation formerly allocated a further (N-1)-deep array per iteration, peaking near 24 GB. Streaming holds the running sum and one participant, about 1.7 GB. Each file must contain a single variable, or one named 'data' or 'voldata' - the same convention fmri_acfestimate uses. Streaming supports 'leaveoneout' without permutations. The pairwise method visits every pair and permutation tests rescramble every participant, so both would re-read the data many times over; the function says so rather than running for hours.
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

