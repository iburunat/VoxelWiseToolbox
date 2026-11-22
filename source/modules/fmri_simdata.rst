fmri_simdata
============

Generates simulated 3D fMRI data for testing and demonstration.

Description
-----------

Generates synthetic fMRI data: spatially smooth activation sources with HRF-convolved time courses, plus additive noise. It returns each participant's data, the source maps and time courses used to generate them, and SIM, which contains the known ground truth for evaluating analysis results.

Each source begins as a sparse train of neural events, which is convolved with a canonical HRF to give the BOLD time course written into the data. Participants differ because each one's event train is given a different random jitter of its Fourier phases before that convolution.

The first N_NETWORK sources (3 by default) share one time course, so together they act as a distributed network: some follow it directly and the rest follow its inverse. Read sim.design.network.sign for which is which. Every other source has a time course of its own, and those are made uncorrelated with each other after HRF convolution, so no accidental resemblance between them can masquerade as signal in the ground truth.

Participant data are compressed with a truncated SVD and reconstructed by fmri_simget, vectorised (228453 x T) by default or as a 4D volume.

Usage
-----

.. code-block:: matlab

   [X_compressed, S_3D, W_participants, svd_info] = fmri_simdata()
   [X_compressed, S_3D, W_participants, svd_info, X_full, sim] = fmri_simdata(...)

Inputs
------

- **N_SOURCES** -- Number of spatial activation sources (blobs). Default: 10.
- **N_PARTICIPANTS** -- Number of simulated participants. Default: 2.
- **T** -- Number of time points per participant. Default: 200.
- **TR** -- Repetition time in seconds. Used for HRF generation. Default: 2.
- **SIGMA_RATIO** -- Controls blob smoothness as a fraction of blob radius r. sigma = r \* sigma_ratio. Default: 0.5 (moderately compact). Smaller values (e.g., 0.3) give sharper blobs; larger values (e.g., 0.8) give more diffuse, spread-out blobs.
- **N_COMP** -- Number of SVD components to keep. Default 0 keeps enough for 95% of the variance - but the simulated noise is full rank and holds most of it, so that is nearly all of them (177 of 200 in one default run). Set a small number to compress harder, at the cost of a coarser reconstruction.
- **PHASE_STRENGTH** -- How much the Fourier phases are jittered to make participants differ. Range [0,1]: 0 leaves them identical, larger values differ more, but even 1 does not make them independent; the HRF smooths much of the jitter away. Default: 0.2.
- **N_NETWORK** -- How many sources share time course 1. Default: 3, and at most N_SOURCES. The last floor(N_NETWORK/3) follow its inverse; sim.design.network.sign records which. To recover the network, convolve W_participants.neural(:,1,p) with the HRF and correlate; positive sources give positive r, negative ones negative r.
- **DO_PLOT** -- Display diagnostic figures (1) or suppress (0). Default: 0.
- **WANT_FULL** -- Assemble the full 4D volumes (X_FULL, the fifth output)? true forces it, false suppresses it, [] (default) assembles when nargout >= 5. They cost 91\*109\*91\*T\*8 bytes, about 1.4 GB per participant at T = 200, so pass false when you need SIM but not the volumes.
- **NOISE_FWHM** -- Spatial smoothing applied to the additive noise, in voxels (FWHM). Default 0, which gives spatially INDEPENDENT noise - unlike real fMRI, where acquisition and registration leave the noise smooth. Set it (3 is a realistic value) when the method under test depends on spatial autocorrelation, such as cluster-extent inference. The noise SD is preserved either way.

Outputs
-------

- **X_COMPRESSED** -- Cell array {1 x N_PARTICIPANTS} of SVD-compressed data. Each cell contains a struct with fields U, S, V. Use fmri_simget to reconstruct the data, vectorised by default.
- **S_3D** -- Spatial source maps (91 x 109 x 91 x N_SOURCES). S_3D(:,:,:,k) is the k-th source's spatial map.
- **W_PARTICIPANTS** -- Struct with two fields: .neural (T x N_SOURCES x N_PARTICIPANTS): sparse event sequences in neural/stimulus domain. .bold   (T x N_SOURCES x N_PARTICIPANTS): HRF-convolved BOLD-domain time courses used in volume assembly. Use .neural(:,1,p) as the stimulus regressor: after HRF convolution it recovers the N_NETWORK distributed sources.
- **SVD_INFO** -- Struct array (1 x N_PARTICIPANTS). XDIM, YDIM and ZDIM are the volume dimensions fmri_simget needs; S is the full singular-value matrix, kept so the variance spectrum can be inspected when choosing N_COMP.
- **X_FULL** -- Cell array {1 x N_PARTICIPANTS} of full 4D volumes (91 x 109 x 91 x T). Assembly is controlled by WANT_FULL; by default it happens when nargout >= 5.
- **SIM** -- Struct recording what was generated. Fields: .params  the inputs used .mask    the voxel-indexing convention .design  network indices and polarities, source centres and radii .gram    correlations between source time courses .norm    per-voxel normalising denominator .truth   expected voxel-to-source correlations, .latent and .population SIM.truth.latent(:,k) and SIM.truth.population(:,k) are correlations with source k's time course, not maps of its spatial territory.

Examples
--------

.. code-block:: matlab

   % Default network: 10 sources, the first 3 sharing time course 1
   [X_comp, S_3D, W, svd_info] = fmri_simdata(10, 8, 200, 2);
   % W.neural(:,1,1) correlates with sources 1,2,3 after HRF convolution

   % Custom network size: first 5 sources share time course 1
   [X_comp, S_3D, W, svd_info] = fmri_simdata(10, 8, 200, 2, [], [], [], 5);

Notes
-----

Data reconstructed by fmri_simget spans only N_COMP temporal components, not T, so its temporal covariance is not the simulated one - markedly so at small N_COMP. Treat degrees of freedom taken from T with caution, or use X_FULL.

See Also
--------

:doc:`fmri_simget <fmri_simget>` · :doc:`fmri_doublegamma <fmri_doublegamma>` · :doc:`fmri_vol2vect <fmri_vol2vect>` · :doc:`fmri_corregressor <fmri_corregressor>`

