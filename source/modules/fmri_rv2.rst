fmri_rv2
========

Modified RV coefficient between two multivariate datasets.

Description
-----------

Computes the modified RV coefficient (RV2; Smilde et al., 2009) between two voxel-by-time fMRI datasets. The coefficient quantifies similarity between the time-by-time configuration matrices of the two datasets after removing diagonal elements, which reduces the positive bias of the classical RV coefficient in high-dimensional settings.

Each input is treated as a matrix of size [V x T], where rows are voxels and columns are time points. For each dataset, voxel time series are mean-centered across time, and a time-by-time configuration matrix is computed as X' \* X. The modified RV coefficient is then calculated from the off-diagonal elements only.

Usage
-----

.. code-block:: matlab

   rv2 = fmri_rv2(vol1, vol2)

Inputs
------

- **vol1, vol2** -- Voxel-by-time matrices [V x T]. Both must have the same number of time points.

Outputs
-------

- **rv2** -- Modified RV coefficient (scalar, range [-1 1]).

Examples
--------

.. code-block:: matlab

   rv2 = fmri_rv2(data_subj1, data_subj2);

References
----------

- Smilde, A. K., Kiers, H. A. L., Bijlsma, S., Rubingh, C. M., & van Erk, M. J. (2009). Matrix correlations for high-dimensional data: the modified RV-coefficient. Bioinformatics, 25(3), 401-405.

See Also
--------

:doc:`fmri_corrmat <fmri_corrmat>` · :doc:`fmri_corrvoldata <fmri_corrvoldata>` · :doc:`fmri_rsa <fmri_rsa>`

