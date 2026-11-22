function vox = fmri_reg2vox(reg, atlas)
% FMRI_REG2VOX  Maps ROI-level data back to voxel space for visualisation.
%
% Assigns each voxel the value of its corresponding atlas ROI, expanding
% an ROI-level statistical map or time series into a full voxel-level brain
% map. Inverse of fmri_vox2reg.
%
% Usage:
%   vox = fmri_reg2vox(reg, atlas)
%
% Inputs:
%   REG    - ROI-level data: (R x 1) statistical map or (R x T) time series,
%            where R is the number of ROIs in the selected atlas.
%   ATLAS  - Atlas number (see atlas list below). Default: 1 (AAL).
%
% Outputs:
%   VOX  - Voxel-level map (228453 x 1) or time series (228453 x T).
%          Each voxel takes the value of its atlas ROI; voxels with no
%          atlas label are set to zero.
%
% Examples:
%   vox_map = fmri_reg2vox(roi_stats, 3);   % Harvard-Oxford Cortical
%   fmri_showslices(vox_map, 1, 2, [0 5])
%
% Atlas numbers:
%    1  = AAL / MarsBar (Automated Anatomical Labeling, 116 ROIs, default)
%    2  = Harvard-Oxford Subcortical Structural Atlas (21 ROIs)
%    3  = Harvard-Oxford Cortical Structural Atlas (48 ROIs)
%    4  = Cerebellar Atlas (MNI152, FLIRT affine, 28 ROIs)
%    5  = Cerebellar Atlas (MNI152, FNIRT nonlinear, 28 ROIs)
%    6  = JHU ICBM-DTI-81 White-Matter Labels (49 ROIs)
%    7  = JHU White-Matter Tractography Atlas (20 ROIs)
%    8  = Juelich Histological Atlas (121 ROIs)
%    9  = MNI Structural Atlas (9 ROIs)
%   10  = Oxford-Imanova Striatal Structural Atlas (4 ROIs)
%   11  = Oxford-Imanova Striatal Connectivity Atlas, 3 sub-regions
%   12  = Oxford-Imanova Striatal Connectivity Atlas, 7 sub-regions
%   13  = Oxford Thalamic Connectivity Probability Atlas (7 ROIs)
%   14  = Craddock Parcellation 200 ROI
%   15  = Craddock Parcellation 400 ROI
%   16  = Craddock Parcellation 600 ROI
%   17  = Craddock Parcellation 800 ROI
%   18  = Craddock Parcellation 950 ROI
%   19  = Brodmann Areas (47 regions)
%
% See also: fmri_vox2reg, fmri_regionmask, fmri_regionnumber

if nargin < 2 || isempty(atlas), atlas = 1; end
[ROI_nos, ROI_labels] = fmri_loadatlas(atlas);

% fmri_loadatlas always returns vectorized ROI numbers, whatever format the
% atlas .mat file happens to use, so no conversion is needed here.
roi = ROI_nos;

roi  = roi(:);
nreg = numel(ROI_labels);   % one row per atlas LABEL, as fmri_vox2reg returns

if size(reg,1) < nreg
    error('fmri_reg2vox:tooFewRegions', ...
          ['REG has %d rows but the atlas defines %d regions.\n' ...
           'REG must have one row per atlas region.'], size(reg,1), nreg);
end

% Use the atlas labels as direct row indices into REG, assigning all labelled
% voxels in one operation. Derive the output size from ROI instead of
% hard-coding the number of voxels.
vox    = zeros(numel(roi), size(reg,2));
inside = roi > 0;                        % unlabelled voxels stay 0
vox(inside, :) = reg(roi(inside), :);
