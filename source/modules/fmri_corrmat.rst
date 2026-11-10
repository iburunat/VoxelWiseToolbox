fmri_corrmat
============

Column-wise pattern similarity matrix between two fMRI datasets.

Description
-----------

Computes the Pearson correlation between every pair of columns across two multivariate datasets, yielding an output matrix of size Ncol1 × Ncol2. Columns can represent time points, trials, conditions, or group-level patterns. If a single dataset is provided, the result is the autocorrelation matrix of its columns (e.g., T × T for time points).

Usage
-----

.. code-block:: matlab

   c = fmri_corrmat(d1)       % autocorrelation of columns (Ncol × Ncol)
   c = fmri_corrmat(d1, d2)   % cross-correlation between two datasets (Ncol1 × Ncol2)

Inputs
------

- **D1** -- Multivariate data (e.g., voxels × columns); correlations are across rows
- **D2** -- Optional second dataset (same number of rows). Default: D2 = D1

Outputs
-------

- **C** -- Similarity matrix of Pearson correlations between columns of D1 and D2

Examples
--------

.. code-block:: matlab

   % Temporal similarity between time points
   c = fmri_corrmat(data);           % T × T matrix
   imagesc(c, [-1 1]); colorbar

   % Cross-condition / trial / group-level similarity
   c = fmri_corrmat(cond_data1, cond_data2);  % C1 × C2 matrix
   imagesc(c, [-1 1]); colorbar

See Also
--------

:doc:`fmri_corregressor <fmri_corregressor>` · :doc:`fmri_corrvoldata <fmri_corrvoldata>` · :doc:`fmri_rv2 <fmri_rv2>` · :doc:`fmri_rsa <fmri_rsa>`

