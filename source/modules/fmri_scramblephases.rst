fmri_scramblephases
===================

Phase-scrambles a brain volume or time series.

Description
-----------

Randomises the phase spectrum of the input while preserving the amplitude spectrum exactly. The result is a surrogate with the same spatial or temporal autocorrelation structure as the original but with shuffled phase relationships - the same power spectrum, with the signal destroyed.

Used to generate null distributions for permutation tests: correlating phase-randomised regressors with brain data gives pseudo-normal statistical images with the same autocorrelation as the true SI, which is the basis of the cluster-size correction in fmri_acfestimate and fmri_csdist.

Usage
-----

.. code-block:: matlab

   fs = fmri_scramblephases(f)        % scramble across ALL dimensions
   fs = fmri_scramblephases(f, dim)   % scramble along DIM only

Inputs
------

- **F** -- Data to scramble, real and finite: a vector (one time series), a volume (91 x 109 x 91), or a matrix (228453 x T).
- **DIM** -- Scramble along this dimension only, independently for every series along it. Default: empty, which scrambles across all dimensions at once. See WHICH FORM YOU WANT below.

Outputs
-------

- **FS** -- Phase-scrambled array, the same size and class as F. The result is real; the real() call in the code removes numerical dust only.

WHICH FORM YOU WANT
-------------------

Omitting DIM applies an N-dimensional FFT, which scrambles across every dimension jointly. That is right for a 3D volume, where the whole spatial structure is to be randomised, and harmless for a vector, which has only one dimension to scramble.

It is almost never right for a VOXELS x TIME matrix. Scrambling that jointly randomises phase across voxels as well as across time, destroying the spatial arrangement along with the temporal one. What is normally wanted is each voxel's own time series scrambled independently, preserving that voxel's temporal power spectrum:

.. code-block:: matlab

   fs = fmri_scramblephases(data, 2);     % data is 228453 x T

Passing a 2D matrix without DIM therefore raises a warning. Vectors and 3D volumes do not, since for them the joint form is the sensible one.

The DIM form is vectorised - one FFT over the whole array rather than a loop over voxels, which at 228453 voxels is the difference between seconds and hours. No loop is needed for per-voxel temporal scrambling.

HOW THE RANDOM PHASES ARE OBTAINED
----------------------------------

The phases come from the FFT of a REAL random array, angle(fftn(rand(...))), rather than from uniformly drawn angles. The transform of a real array is conjugate-symmetric, so those phases are antisymmetric, the surrogate is exactly real, and its amplitude spectrum is preserved to machine precision. Drawing angles directly would break that symmetry and leave an imaginary residue that has to be discarded, changing the spectrum slightly.

Examples
--------

.. code-block:: matlab

   % Surrogate volume with the same spatial autocorrelation
   vol_null = fmri_scramblephases(vol3d);

   % Null time series for every voxel, preserving each one's spectrum
   data_null = fmri_scramblephases(data, 2);        % 228453 x T

   % One regressor
   reg_null = fmri_scramblephases(reg, 1);          % T x 1

   % Null correlations for a permutation test
   r_null = fmri_corregressor(fmri_scramblephases(reg, 1), data);

References
----------

- Ebisuzaki, W. (1997). A method to estimate the statistical significance of a correlation when the data are serially correlated. Journal of
- Climate, 10(6), 2147-2153.
- Prichard, D. & Theiler, J. (1994). Generating surrogate data for time series with several simultaneously measured variables. Physical Review
- Letters, 73(7), 951-954.

See Also
--------

:doc:`fmri_acfestimate <fmri_acfestimate>` · :doc:`fmri_corregressor <fmri_corregressor>` · :doc:`fmri_csdist <fmri_csdist>`

