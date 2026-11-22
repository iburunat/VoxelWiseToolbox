function [mask, regionname] = fmri_regionmask(regionnumber, atlasnumber)
% FMRI_REGIONMASK  Binary brain mask for one or more atlas regions.
%
% Returns a vectorized binary mask (228453 x 1) that is 1 for all voxels
% belonging to the specified region(s) in the given atlas. Accepts a vector
% of region numbers to combine multiple ROIs into a single mask.
%
% Usage:
%   [mask, regionname] = fmri_regionmask(regionnumber)
%   [mask, regionname] = fmri_regionmask(regionnumber, atlasnumber)
%
% Inputs:
%   REGIONNUMBER  - Region number(s), scalar or vector. Use fmri_regionnumber
%                   to look up the number for a coordinate.
%   ATLASNUMBER   - Atlas number (see atlas list below). Default: 1 (AAL).
%
% Outputs:
%   MASK        - Logical vectorized mask (228453 x 1), true inside the
%                 region(s). Combining several regions gives their union.
%   REGIONNAME  - Cell array of region name strings for each requested number.
%
% Examples:
%   % Left hippocampus mask (AAL region 57)
%   mask = fmri_regionmask(57);
%
%   % Combine L+R hippocampus
%   mask = fmri_regionmask([57 58]);
%
%   % Sphere intersected with anatomical region
%   roi = fmri_spheremask(fmri_mni2sub([20 -58 18]), 5) & fmri_regionmask(6);
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
% See also: fmri_regionnumber, fmri_nregion, fmri_regiontable, fmri_spheremask

if nargin < 2 || isempty(atlasnumber), atlasnumber = 1; end
[ROI_nos, ROI_labels] = fmri_loadatlas(atlasnumber);

% fmri_loadatlas always returns vectorized ROI numbers, whatever format the
% atlas .mat file happens to use, so no conversion is needed here.

if isempty(regionnumber)
    % Derive the mask size from the atlas data, don't hard-code it
    mask = false(numel(ROI_nos), 1);
    regionname = {};
    return
end

regionnumber = regionnumber(:)';
if any(regionnumber < 1) || any(regionnumber > numel(ROI_labels)) || ...
   any(mod(regionnumber,1) ~= 0)
    error('fmri_regionmask:badRegion', ...
          ['Region numbers must be whole numbers in the range 1 to %d for ' ...
           'this atlas; got values from %g to %g.\n' ...
           'Use fmri_regionnumber to find the number for a coordinate.'], ...
          numel(ROI_labels), min(regionnumber), max(regionnumber));
end

% Create a logical mask for one or more regions in a single operation,
% ensuring a consistent output type.
mask = ismember(ROI_nos(:), regionnumber);

regionname = ROI_labels(regionnumber);

empty_regions = regionnumber(~ismember(regionnumber, unique(ROI_nos)));
if ~isempty(empty_regions)
    warning('fmri_regionmask:emptyRegion', ...
            ['Region(s) %s contain no voxels in the brain mask and ' ...
             'contribute nothing to the mask.'], ...
            mat2str(empty_regions));
end

