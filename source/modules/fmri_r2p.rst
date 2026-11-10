fmri_r2p
========

Converts Pearson correlation coefficient(s) to p-values.

Description
-----------

Transforms a correlation coefficient r to a p-value using the Fisher z-transformation followed by normal-distribution inference. Supports one-tailed and two-tailed tests, and handles both scalar and map inputs.

Usage
-----

.. code-block:: matlab

   [p_pos, p_neg] = fmri_r2p(r, df)
   [p_pos, p_neg] = fmri_r2p(r, df, tail)

Inputs
------

- **R** -- Correlation coefficient(s). Scalar, vector, or brain map (228453 x 1). Values should be in [-1, 1].
- **DF** -- Effective sample size, NOT N-2. For independent samples pass the number of observations N; the function applies the usual Fisher standardisation sqrt(DF-3) internally. For autocorrelated time series use fmri_effdf, which returns N when there is no autocorrelation and less when there is. Passing N-2 here would make the test conservative.
- **TAIL** -- Test direction: 2  = two-tailed (default) 1  = one-tailed, positive (r > 0) -1  = one-tailed, negative (r < 0)

Outputs
-------

- **P_POS** -- When TAIL = 2, the two-tailed p-value (identical to P_NEG; a two-tailed test has one p-value, which depends on \|r\| only, so correlations of either sign are treated symmetrically). When TAIL = 1, the one-tailed p-value for r > 0. Empty [] when TAIL = -1.
- **P_NEG** -- When TAIL = 2, the same two-tailed p-value as P_POS. When TAIL = -1, the one-tailed p-value for r < 0. Empty [] when TAIL = 1.

All returned p-values lie in [0, 1]. Thresholding a signed statistical map should use TAIL = 2 and the p-value alone; additionally requiring r > 0 would turn it into a one-tailed test at half the stated alpha.

Examples
--------

.. code-block:: matlab

   % Whole-brain significance map (two-tailed)
   r_map = fmri_corregressor(regressor, data);
   df    = size(data, 2) - 2;
   [p_pos, p_neg] = fmri_r2p(r_map, df);

   % Single correlation with autocorrelation-corrected df (positive)
   df = fmri_effdf(ts1, ts2);
   r  = corr(ts1, ts2);
   p  = fmri_r2p(r, df, 1);

   % One-tailed test for negative correlations
   [~, p_neg] = fmri_r2p(r_map, df, -1);

   % Threshold map at p < 0.001 (positive correlations)
   sig_map = p_pos < 0.001;
   fmri_showslices(sig_map, 1, 2)

DF CONTEXT - CHOOSING THE RIGHT VALUE
-------------------------------------

DF is the number of OBSERVATIONS, not the conventional N-2 of a t-test. This function works through the Fisher transform, whose standard error is 1/sqrt(DF-3); the "-3" is already the correction for having estimated a correlation. Subtracting 2 as well removes the same degrees of freedom twice and makes every p-value conservative.

FIRST LEVEL - one participant, correlation over TIME points.

Filtering and smoothing leave neighbouring time points dependent, so the nominal number of volumes overstates the information present:

.. code-block:: matlab

   df = fmri_effdf(regressor, data(v,:)');
   p  = fmri_r2p(r, df);

GROUP LEVEL - correlation across PARTICIPANTS.

The observations are participants, and temporal autocorrelation does not enter: it is a first-level concern.

.. code-block:: matlab

   df = size(participant_maps, 2);        % N, not N-2
   p  = fmri_r2p(rho, df);

PARTIAL CORRELATION - across participants, C confounds partialled out.

Each confound costs one degree of freedom:

.. code-block:: matlab

   df = N - C;                            % not N-C-2, not N-C-1
   p  = fmri_r2p(rho, df);

These three cases were previously undocumented, and both a manuscript example and a proposed convenience wrapper got the partial-correlation case wrong in the same direction (N-C-2 and N-C-1 respectively). The rule is that DF counts observations minus confounds; the function subtracts the 3 itself.

A wrapper that selected DF automatically from an analysis "type" was considered and rejected. It cannot know whether a given N counts time points or participants - that is exactly the judgement the user has to make - so it would have concealed the choice while still requiring it to be right.

See Also
--------

:doc:`fmri_fisherz <fmri_fisherz>` · :doc:`fmri_fisherz2p <fmri_fisherz2p>` · :doc:`fmri_effdf <fmri_effdf>` · :doc:`fmri_cleanclusters <fmri_cleanclusters>` · :doc:`fmri_tfce <fmri_tfce>`

