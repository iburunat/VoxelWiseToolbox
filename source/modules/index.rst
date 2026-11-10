Function Library
================

Every function takes and returns data on the MNI152 2 mm grid
(91x109x91, 228453 in-brain voxels), so any function composes with
any other. Grouping follows ``Contents.m``.

I/O and NIfTI handling
----------------------

.. toctree::
   :maxdepth: 1

   fmri_readnii
   fmri_export
   fmri_checknifti
   fmri_tomni152

Space, coordinates and reshaping
--------------------------------

.. toctree::
   :maxdepth: 1

   fmri_vol2vect
   fmri_vect2vol
   fmri_mni2sub
   fmri_sub2mni
   fmri_ind2sub
   fmri_sub2ind
   fmri_mni2tal
   fmri_mirror
   fmri_voxdist
   fmri_upsample
   fmri_downsample

Temporal preprocessing
----------------------

.. toctree::
   :maxdepth: 1

   fmri_detrend
   fmri_bandpassfilter
   fmri_correctmovement
   fmri_tempsmooth
   fmri_zscorevoldata
   fmri_wiener
   fmri_doublegamma

Atlases and regions of interest
-------------------------------

.. toctree::
   :maxdepth: 1

   fmri_loadatlas
   fmri_atlas
   fmri_regionmask
   fmri_spheremask
   fmri_maskdata
   fmri_regionnumber
   fmri_regiontable
   fmri_nregion
   fmri_vox2reg
   fmri_reg2vox
   fmri_banumber

Analysis: effect estimation
---------------------------

.. toctree::
   :maxdepth: 1

   fmri_corregressor
   fmri_corrmat
   fmri_corrvoldata
   fmri_xcorr
   fmri_partcorr
   fmri_ppi
   fmri_rsa
   fmri_isc
   fmri_rv2
   fmri_dicemirror

Statistical inference
---------------------

.. toctree::
   :maxdepth: 1

   fmri_ttest
   fmri_r2p
   fmri_p2r
   fmri_p2t
   fmri_fisherz
   fmri_fisherz2p
   fmri_effdf
   fmri_combinep
   fmri_tfce
   fmri_bwlabel
   fmri_findclusters
   fmri_cleanclusters
   fmri_acfestimate
   fmri_csdist
   fmri_csthreshold
   fmri_scramblephases

Simulation and signal quality
-----------------------------

.. toctree::
   :maxdepth: 1

   fmri_simdata
   fmri_simget
   fmri_snri
   fmri_snrt
   fmri_cnr

Visualisation
-------------

.. toctree::
   :maxdepth: 1

   fmri_showslices
   fmri_showslices_int
   fmri_showselectslices
   fmri_showselectslices_int
   fmri_showplanes
   fmri_showcortex
   fmri_show3d
   fmri_show3dba
   fmri_show3datlas
   fmri_show3dhalfbrains
   fmri_braincake
   fmri_brainvideo
   fmri_makevizpar
   fmri_bin
   fmri_juicyslices
   fmri_divmap
   fmri_makecmap
   fmri_distinctcolors
   fmri_createlegend

