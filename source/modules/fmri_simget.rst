fmri_simget
===========

Extracts one participant's fMRI data from fmri_simdata output.

Description
-----------

Reconstructs the 4D fMRI volume (or 228453 x T brain vector) for a single participant from the SVD-compressed output of fmri_simdata.

Usage
-----

.. code-block:: matlab

   X4D  = fmri_simget(X_compressed, svd_info, p)
   data = fmri_simget(X_compressed, svd_info, p, 1)

Inputs
------

- **X_COMPRESSED** -- Cell array {1 x N} of compressed participant data, as returned by fmri_simdata.
- **SVD_INFO** -- Struct array (1 x N) with SVD bases and volume dimensions, as returned by fmri_simdata.
- **P** -- Participant index (integer in [1, N]).
- **AS_VECTOR** -- If 1 (default), return vectorized brain data (228453 x T). If 0, return the full 4D volume (91 x 109 x 91 x T).

Outputs
-------

- **OUT** -- Reconstructed fMRI data: vectorized brain data (228453 x T) by default, or the 4D volume (91 x 109 x 91 x T) if AS_VECTOR = 0.

Examples
--------

.. code-block:: matlab

   % Extract participant 2 as 4D volume
   X4D  = fmri_simget(X_comp, svd_info, 2);

   % Extract directly as brain vector for analysis
   data = fmri_simget(X_comp, svd_info, 1, 1);   % 228453 x T
   r    = fmri_corregressor(regressor, data);

Notes
-----

fmri_simdata stores each participant as a TRUNCATED SVD (by default enough components for 95%% of variance), so this reconstruction is a low-rank approximation, not the exact simulated data. That is by design, for memory efficiency, and is appropriate for testing and demonstration. If you need the exact data, request the 5th output X_FULL from fmri_simdata, or reconstruct from the full bases in SVD_INFO (U_full, S, V_full).

See Also
--------

:doc:`fmri_simdata <fmri_simdata>` · :doc:`fmri_vol2vect <fmri_vol2vect>` · :doc:`fmri_vect2vol <fmri_vect2vol>`

