% VoxelWise Toolbox — Lightweight MATLAB toolbox for transparent fMRI analysis
%
% Run fmritoolbox_setup.m to add the toolbox to your MATLAB path.
% Type "help <function_name>" for detailed documentation on any function.
%
% Voxelwise analysis of fMRI data on the MNI152 2mm grid (91x109x91,
% 228453 in-brain voxels). Every function takes and returns data in that
% single layout, so any function composes with any other.
%
% Requires MATLAB R2019a or later. No other MathWorks toolbox is needed:
% R2019a is the release in which xcorr, used by fmri_effdf, moved into base
% MATLAB from the Signal Processing Toolbox.
%
% 83 public functions. Internal helpers live in core/private/ and are
% deliberately not listed here.
%
% -------------------------------------------------------------------------
% I/O and NIfTI handling
% -------------------------------------------------------------------------
%   fmri_readnii                - Reads a 3D or 4D NIfTI (.nii) or Analyze (.img/.hdr) file.
%   fmri_export                 - Saves 3D or 4D volume data as a NIfTI file (.nii).
%   fmri_checknifti             - Warns if the bundled NIFTI toolbox is missing or unpatched.
%   fmri_tomni152               - Resamples an MNI-space NIfTI onto the toolbox 2mm grid.
%
% -------------------------------------------------------------------------
% Space, coordinates and reshaping
% -------------------------------------------------------------------------
%   fmri_vol2vect               - Vectorizes a 91x109x91 brain volume to a 228453-element vector.
%   fmri_vect2vol               - Devectorizes a 228453-element brain vector to a 91x109x91 volume.
%   fmri_mni2sub                - Converts MNI coordinates (mm) to voxel subscripts.
%   fmri_sub2mni                - Converts voxel subscripts to MNI coordinates (mm).
%   fmri_ind2sub                - Converts linear brain indices to voxel subscripts.
%   fmri_sub2ind                - Converts voxel subscripts to linear brain indices.
%   fmri_mni2tal                - Converts MNI152 coordinates to Talairach space.
%   fmri_mirror                 - Flips a vectorized brain map left-to-right (sagittal mirror).
%   fmri_voxdist                - Euclidean distance (mm) between brain voxels.
%   fmri_upsample               - Restores spatially downsampled fMRI data to full resolution.
%   fmri_downsample             - Spatially downsamples vectorized fMRI data by integer factor.
%
% -------------------------------------------------------------------------
% Temporal preprocessing
% -------------------------------------------------------------------------
%   fmri_detrend                - Removes low-frequency drift from fMRI data using spline fitting.
%   fmri_bandpassfilter         - Non-causal FFT-based bandpass filter for fMRI time series.
%   fmri_correctmovement        - Removes motion artefacts from fMRI data via regression.
%   fmri_tempsmooth             - Temporal Gaussian smoothing of fMRI time series.
%   fmri_zscorevoldata          - Voxelwise z-scoring of fMRI time series.
%   fmri_wiener                 - Wiener deconvolution: estimate neural signal from BOLD response.
%   fmri_doublegamma            - Double-gamma haemodynamic response function.
%
% -------------------------------------------------------------------------
% Atlases and regions of interest
% -------------------------------------------------------------------------
%   fmri_loadatlas              - Loads atlas ROI map and region labels by atlas number.
%   fmri_atlas                  - Lists all available atlases and their region counts.
%   fmri_regionmask             - Binary brain mask for one or more atlas regions.
%   fmri_spheremask             - Spherical ROI mask centred on a given voxel.
%   fmri_maskdata               - Applies a binary ROI mask to volume data.
%   fmri_regionnumber           - Looks up atlas ROI name and number for voxel coordinates.
%   fmri_regiontable            - Cluster and ROI table for a thresholded statistical map.
%   fmri_nregion                - Returns the region name(s) for one or more atlas ROI numbers.
%   fmri_vox2reg                - Averages voxel data within atlas ROIs to produce ROI-level data.
%   fmri_reg2vox                - Maps ROI-level data back to voxel space for visualisation.
%   fmri_banumber               - Shortcut for quick Brodmann lookups.
%
% -------------------------------------------------------------------------
% Analysis: effect estimation
% -------------------------------------------------------------------------
%   fmri_corregressor           - Voxelwise correlation of regressor(s) with fMRI data.
%   fmri_corrmat                - Column-wise pattern similarity matrix between two fMRI datasets.
%   fmri_corrvoldata            - Voxelwise Pearson correlation between two fMRI datasets.
%   fmri_xcorr                  - Voxelwise lagged cross-correlation between regressor and fMRI data.
%   fmri_partcorr               - Voxelwise partial correlation with confounds removed.
%   fmri_ppi                    - Voxelwise psychophysiological interaction (PPI) analysis.
%   fmri_rsa                    - Voxelwise representational similarity analysis (RSA).
%   fmri_isc                    - Voxelwise intersubject correlation (ISC).
%   fmri_rv2                    - Modified RV coefficient between two multivariate datasets.
%   fmri_dicemirror             - Mirrored Dice coefficient of a binary brain mask.
%
% -------------------------------------------------------------------------
% Statistical inference
% -------------------------------------------------------------------------
%   fmri_ttest                  - Voxelwise t-test across participants.
%   fmri_r2p                    - Converts Pearson correlation coefficient(s) to p-values.
%   fmri_p2r                    - Correlation value needed to reach a given p-threshold.
%   fmri_p2t                    - t-value needed to reach a given p-threshold.
%   fmri_fisherz                - Standardised Fisher z-score from a Pearson correlation.
%   fmri_fisherz2p              - Two-tailed p-value from a Fisher z-score.
%   fmri_effdf                  - Estimates effective degrees of freedom for correlated time series.
%   fmri_combinep               - Combine p-values across participants using meta-analytic methods.
%   fmri_tfce                   - Threshold-free cluster enhancement (TFCE) of a statistical map.
%   fmri_bwlabel                - Labels connected clusters in a 3D binary volume.
%   fmri_findclusters           - Finds and labels connected clusters in a binary brain map.
%   fmri_cleanclusters          - Removes small and sparse clusters from a thresholded map.
%   fmri_acfestimate            - Estimates the spatial smoothing KERNEL of the data.
%   fmri_csdist                 - Null cluster-size distribution from a smoothing kernel.
%   fmri_csthreshold            - Extracts critical cluster sizes from a CS distribution.
%   fmri_scramblephases         - Phase-scrambles a brain volume or time series.
%
% -------------------------------------------------------------------------
% Simulation and signal quality
% -------------------------------------------------------------------------
%   fmri_simdata                - Generates simulated 3D fMRI data for testing and demonstration.
%   fmri_simget                 - Extracts one participant's fMRI data from fmri_simdata output.
%   fmri_snri                   - Image-domain signal-to-noise ratio (SNR-i) for each fMRI scan.
%   fmri_snrt                   - Temporal signal-to-noise ratio (tSNR) for each brain voxel.
%   fmri_cnr                    - Temporal contrast-to-noise ratio (tCNR) for fMRI data.
%
% -------------------------------------------------------------------------
% Visualisation
% -------------------------------------------------------------------------
%   fmri_showslices             - Displays continuous brain data as a series of 2D slices.
%   fmri_showslices_int         - Displays integer-labelled brain data as a coloured slice mosaic.
%   fmri_showselectslices       - Displays continuous data on a user-specified set of slices.
%   fmri_showselectslices_int   - Displays integer data on user-specified axial slices.
%   fmri_showplanes             - Three-plane (sagittal/coronal/axial) slice view with crosshair.
%   fmri_showcortex             - Cortical surface rendering of a statistical or continuous map.
%   fmri_show3d                 - 3D isosurface rendering of brain activation.
%   fmri_show3dba               - 3D rendering of a map split by Brodmann area.
%   fmri_show3datlas            - 3D rendering of atlas regions as coloured isosurfaces.
%   fmri_show3dhalfbrains       - Plots activation on four lateral and medial hemisphere views.
%   fmri_braincake              - 3D layered-slice rendering of brain activation (brain cake).
%   fmri_brainvideo             - Creates a rotating 3D brain video from a brain map.
%   fmri_makevizpar             - Creates a visualization parameter structure with defaults.
%   fmri_bin                    - Bins continuous brain data into a set of discrete colour bands.
%   fmri_juicyslices            - Finds the slices carrying most of a map's signal.
%   fmri_divmap                 - Diverging blue-white-red colormap for thresholded statistical maps.
%   fmri_makecmap               - Builds a colormap from anchor colours and their positions.
%   fmri_distinctcolors         - Generates N perceptually distinguishable RGB colours.
%   fmri_createlegend           - Create a legend as an image for export.
%
% -------------------------------------------------------------------------
% Getting started
% -------------------------------------------------------------------------
%   demo/demo_preprocessing.m   - preprocessing chain, one participant
%   demo/demo_glm.m             - two-level GLM, simulated cohort
%   demo/demo_visualization.m   - every display function
%   demo/demo_naturalistic.m    - full naturalistic-stimulus pipeline
%
% Generated by tools/make_contents.m - do not edit by hand.
% Last generated: 2026-10-29

