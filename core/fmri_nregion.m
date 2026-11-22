function list_of_regions = fmri_nregion(number, atlas)
% FMRI_NREGION  Returns the region name(s) for one or more atlas ROI numbers.
%
% Performs the reverse lookup of fmri_regionnumber: given a region number
% (or list of numbers), returns the corresponding region label string(s)
% from the specified atlas.
%
% Usage:
%   list_of_regions = fmri_nregion(number)
%   list_of_regions = fmri_nregion(number, atlas)
%
% Inputs:
%   NUMBER  - Region number(s), scalar or vector.
%   ATLAS   - Atlas number (see atlas list below). Default: 1 (AAL).
%
% Outputs:
%   LIST_OF_REGIONS - Cell array of region name strings, one per input number.
%
% Examples:
%   name  = fmri_nregion(57);          % AAL region 57 name
%   names = fmri_nregion([1 3 5], 3);  % Harvard-Oxford Cortical regions
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
% See also: fmri_regionnumber, fmri_regionmask, fmri_regiontable

if nargin < 2 || isempty(atlas), atlas = 1; end

if isempty(number)
    list_of_regions = {};
    return
end

[~, ROI_labels] = fmri_loadatlas(atlas);

number = number(:)';
if any(number < 1) || any(number > numel(ROI_labels)) || any(mod(number,1) ~= 0)
    error('fmri_nregion:badRegion', ...
          ['Region numbers must be whole numbers in the range 1 to %d for ' ...
           'this atlas; got values from %g to %g.\n' ...
           'Use fmri_regionnumber to find the number for a coordinate.'], ...
          numel(ROI_labels), min(number), max(number));
end

% Return each label as a character vector. Atlas files may contain character,
% string, numeric or nested-cell labels, so convert each label individually
% to ensure a consistent output format.
list_of_regions = cell(1, numel(number));
for k = 1:numel(number)
    lab = ROI_labels{number(k)};
    while iscell(lab), lab = lab{1}; end     % unwrap nested cells
    if ischar(lab)
        list_of_regions{k} = lab;
    elseif isstring(lab)
        list_of_regions{k} = char(lab);
    else
        list_of_regions{k} = num2str(lab);
    end
end
end