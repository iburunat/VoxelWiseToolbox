fmri_simdata
============

Generates simulated 3D fMRI data for testing and demonstration.

Description
-----------

Generates realistic synthetic fMRI data consisting of spatially smooth activation blobs (sources) with realistic BOLD time courses embedded in noise. Neural-domain time courses (sparse event sequences) are convolved with the canonical HRF to produce BOLD-domain signals, making the output suitable for demonstrating the full regressor preparation pipeline. Participant variability is introduced via FFT phase perturbation of the base time courses. Output is compressed via SVD for memory efficiency and is immediately compatible with all fMRItoolbox functions via fmri_simget.

The first N_NETWORK blobs all share time course 1, simulating a distributed brain network that responds coherently to stimulus feature 1. Remaining blobs each have their own independent time course.

Spatial sources are placed within the standard MNI152 2mm brain mask (91x109x91), so all outputs are directly compatible with fmri_vol2vect, fmri_showslices, fmri_corregressor, and all other toolbox functions.

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
- **SIGMA_RATIO** -- Controls blob smoothness as a fraction of blob radius r. sigma = r \* sigma_ratio. Default: 0.5 (moderately compact). Smaller values (e.g. 0.3) give sharper blobs; larger values (e.g. 0.8) give more diffuse, spread-out blobs.
- **N_COMP** -- Number of SVD components for compression. Use 0 (default) for automatic selection retaining 95% of variance. Set explicitly (e.g. 20) to fix the number of components.
- **PHASE_STRENGTH** -- Controls inter-participant similarity via FFT phase perturbation strength. Range [0,1]: 0 = identical participants, 1 = fully decorrelated. Default: 0.2.
- **N_NETWORK** -- Number of blobs sharing time course 1 (network blobs). Default: 3. The last floor(N_NETWORK/3) network blobs are driven by -TC1 (negative correlation with regressor). Must be <= N_SOURCES. Use W_participants.neural(:,1,p) as regressor (after HRF convolution) to recover the full network — positive blobs appear in p_pos map, negative blobs in p_neg map.
- **DO_PLOT** -- Display diagnostic figures (1) or suppress (0). Default: 0.
- **WANT_FULL** -- Assemble the full 4D volumes (output 5)? true forces it, false suppresses it, [] (default) assembles when nargout>=5. Pass false when you need SIM but not the volumes: they cost roughly 110 MB per participant and are discarded anyway.

Outputs
-------

- **X_COMPRESSED** -- Cell array {1 x N_PARTICIPANTS} of SVD-compressed data. Each cell contains a struct with fields U, S, V. Use fmri_simget to reconstruct participant volumes.
- **S_3D** -- Spatial source maps (91 x 109 x 91 x N_SOURCES). S_3D(:,:,:,k) is the k-th activation blob.
- **W_PARTICIPANTS** -- Struct with two fields: .neural (T x N_SOURCES x N_PARTICIPANTS): sparse event sequences in neural/stimulus domain. .bold   (T x N_SOURCES x N_PARTICIPANTS): HRF-convolved BOLD-domain time courses used in volume assembly. Use .neural(:,1,p) as stimulus regressor — after HRF convolution it recovers the N_NETWORK distributed blobs.
- **SVD_INFO** -- Struct array (1 x N_PARTICIPANTS) with SVD basis and volume dimension fields. Required by fmri_simget.
- **X_FULL** -- Cell array {1 x N_PARTICIPANTS} of full 4D volumes (91 x 109 x 91 x T). Assembly is controlled by WANT_FULL; by default it happens when nargout >= 5.

Examples
--------

.. code-block:: matlab

   % Default: 10 sources, first 3 share time course 1 (network)
   [X_comp, S_3D, W, svd_info] = fmri_simdata(10, 8, 200, 2);
   % W.neural(:,1,1) correlates with blobs 1,2,3 after HRF convolution

   % Custom network size: first 5 blobs share time course 1
   [X_comp, S_3D, W, svd_info] = fmri_simdata(10, 8, 200, 2, [], [], [], 5);

See Also
--------

:doc:`fmri_simget <fmri_simget>` · :doc:`fmri_doublegamma <fmri_doublegamma>` · :doc:`fmri_vol2vect <fmri_vol2vect>` · :doc:`fmri_corregressor <fmri_corregressor>`

