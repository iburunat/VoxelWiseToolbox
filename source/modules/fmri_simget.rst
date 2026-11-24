fmri_simget
===========

Extracts one participant's fMRI data from fmri_simdata output.

Description
-----------

Reconstructs the 4D fMRI volume (or 228453 x T brain vector) for a single participant from the SVD-compressed output of fmri_simdata.

Usage
-----

.. code-block:: matlab

   data = fmri_simget(X_compressed, svd_info, p)       % 228453 x T
   X4D  = fmri_simget(X_compressed, svd_info, p, 0)    % 91 x 109 x 91 x T

Inputs
------

- **X_COMPRESSED** -- Cell array {1 x N_PARTICIPANTS} of SVD-compressed data. Each cell contains a struct with fields U, S, V. Reconstruct one participant at a time.
- **SVD_INFO** -- Struct array (1 x N) with the singular values and volume dimensions, as returned by fmri_simdata.
- **P** -- Participant index (integer in [1, N]).
- **AS_VECTOR** -- If 1 (default), return vectorized brain data (228453 x T). If 0, return the full 4D volume (91 x 109 x 91 x T).

Outputs
-------

- **OUT** -- Reconstructed fMRI data: vectorized brain data (228453 x T) by default, or the 4D volume (91 x 109 x 91 x T) if AS_VECTOR = 0.

Examples
--------

.. code-block:: matlab

   % Analyse one participant: reconstruct, then correlate with the task
   [X_comp, S_3D, W, svd_info] = fmri_simdata(10, 8, 200, 2);
   data = fmri_simget(X_comp, svd_info, 1);        % participant 1, 228453 x T
   r    = fmri_corregressor(W.bold(:, 1, 1), data);
   fmri_showslices(r, 1, 2, [-0.8 0.8]);

   % A map purely for trying the display functions: no data and no analysis,
   % just the source maps combined with chosen weights, two positive and two
   % negative. This is NOT a statistical map; see demo_glm.
   S   = fmri_vol2vect(S_3D);                      % 228453 x N_SOURCES
   map = S(:, 1:4) * [3 2.7 -3 -2.4]';
   fmri_showslices(map, 1, 2, [-4 4], [], [], 1, [], 1);

Notes
-----

fmri_simdata uses truncated SVD compression, retaining enough components to explain 95% of the variance by default. The reconstructed data are therefore a low-rank approximation of the simulated data. For the exact simulated volumes, request X_FULL from fmri_simdata.

See Also
--------

:doc:`fmri_simdata <fmri_simdata>` · :doc:`fmri_vol2vect <fmri_vol2vect>` · :doc:`fmri_vect2vol <fmri_vect2vol>`

