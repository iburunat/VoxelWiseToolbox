demo_glm
========

% DEMO_GLM  Two-level analysis on simulated fMRI data

Description
-----------

The shortest complete path from simulated data to a thresholded, labelled group map: simulate a cohort, correlate a regressor with every voxel for each participant, test those maps across participants, clean the result and label it anatomically.

WHAT THIS DEMO IS FOR
---------------------

Learning the two-level workflow and the toolbox's calling conventions. It answers three questions: what happens at the first level, what happens at the second, and whether the result matches the signal that was planted.

It is NOT a corrected analysis. The surviving clusters come from an uncorrected voxel threshold (p < 0.001) plus a fixed minimum extent. For the correction methods see demo_csizeestimation (Ledberg cluster extent) and demo_tfce (threshold-free cluster enhancement). For quantitative recovery scoring - precision, recall, source leakage - see validate_glm_recovery.

**Steps:**

1. Simulate a 20-participant cohort        fmri_simdata
2. First level: one map per participant    fmri_corregressor
3. Second level: group t-test              fmri_ttest
4. Threshold and clean clusters            fmri_cleanclusters
5. Label regions and compare with truth    fmri_regiontable

Self-contained: it simulates its own data and needs no scanner data and nothing beyond base MATLAB.

See Also
--------

:doc:`fmri_simdata <../modules/fmri_simdata>` · :doc:`fmri_simget <../modules/fmri_simget>` · :doc:`fmri_corregressor <../modules/fmri_corregressor>` · :doc:`fmri_ttest <../modules/fmri_ttest>` · :doc:`fmri_cleanclusters <../modules/fmri_cleanclusters>` · :doc:`fmri_regiontable <../modules/fmri_regiontable>` · :doc:`fmri_p2t <../modules/fmri_p2t>` · :doc:`demo_tfce <demo_tfce>` · :doc:`demo_csizeestimation <demo_csizeestimation>` · :doc:`demo_preprocessing <demo_preprocessing>` · ``validate_glm_recovery``

