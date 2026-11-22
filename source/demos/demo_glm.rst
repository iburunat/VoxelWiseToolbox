demo_glm
========

% DEMO_GLM  Two-level fMRI analysis with a single task regressor

Description
-----------

Demonstrates a two-level analysis of simulated fMRI data. A voxelwise correlation map is calculated for each participant and then tested across participants. The recovered group map is compared with the expected signal.

This introductory demo uses an uncorrected voxel threshold of p < 0.001 and a fixed 20-voxel extent. See demo_csizeestimation and demo_tfce for multiple-comparison methods.

**Steps:**

1. Simulate a 20-participant cohort                           fmri_simdata
2. First level: correlate the task regressor with each voxel  fmri_corregressor
3. Second level: test the participant maps at group level     fmri_ttest
4. Threshold the result and remove small clusters             fmri_cleanclusters
5. Label the surviving clusters and compare with truth        fmri_regiontable

See Also
--------

:doc:`fmri_simdata <../modules/fmri_simdata>` · :doc:`fmri_simget <../modules/fmri_simget>` · :doc:`fmri_corregressor <../modules/fmri_corregressor>` · :doc:`fmri_ttest <../modules/fmri_ttest>` · :doc:`fmri_cleanclusters <../modules/fmri_cleanclusters>` · :doc:`fmri_regiontable <../modules/fmri_regiontable>` · :doc:`fmri_p2t <../modules/fmri_p2t>` · :doc:`demo_tfce <demo_tfce>` · :doc:`demo_csizeestimation <demo_csizeestimation>` · :doc:`demo_preprocessing <demo_preprocessing>` · ``validate_glm_recovery``

