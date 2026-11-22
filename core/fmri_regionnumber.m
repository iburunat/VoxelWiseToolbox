function [list_of_regions, regionnumber] = fmri_regionnumber(coords, atlasnumber)
% FMRI_REGIONNUMBER  Looks up atlas ROI name and number for voxel coordinates.
%
% Return region name(s) and number(s) for voxel coordinate(s)
% For each voxel location (subscript space), returns the name and index of
% the atlas region that contains it. Handles single or multiple coordinates.
% For a single coordinate, LIST_OF_REGIONS is returned as a character
% vector. For multiple coordinates, it is returned as an N x 1 cell array.
%
% Usage:
%   [list_of_regions, regionnumber] = fmri_regionnumber(coords)
%   [list_of_regions, regionnumber] = fmri_regionnumber(coords, atlas)
%
% Inputs:
%   COORDS  - Voxel subscripts (N x 3): [x1 y1 z1; x2 y2 z2; ...].
%             1-based, x in [1 91], y in [1 109], z in [1 91].
%   ATLAS   - Atlas number (see atlas list below). Default: 1 (AAL).
%
% Outputs:
%   LIST_OF_REGIONS - Cell array of region name strings (N x 1).
%   REGIONNUMBER    - Region index numbers (N x 1). 0 = no atlas label.
%
% Examples:
%   [name, num] = fmri_regionnumber([46 64 37]);     % brain centre, AAL
%   [names, ~]  = fmri_regionnumber([30 50 40; 60 70 50], 3);
%
%   % From MNI millimetres: convert first, then look up
%   fmri_regionnumber(fmri_mni2sub([50 -20 6]), 8)   % Juelich: right TE 1.0
%
%   % Peak voxel of a statistical map
%   [~, peak]   = max(r_map);
%   [region, ~] = fmri_regionnumber(fmri_ind2sub(peak));
%
% Atlas numbers: run fmri_atlas() for the indexed list, or
% fmri_loadatlas() for the metadata table. 
%
% See also: fmri_loadatlas, fmri_ind2sub, fmri_sub2ind

% validate inputs
if size(coords,2) ~= 3
    error('fmri_regionnumber:badCoords', ...
        ['COORDS must be an N x 3 matrix of subscript coordinates [i j k].\n' ...
         'Got %s. For LINEAR indices, convert with fmri_ind2sub first; for MNI ' ...
         'millimetres,\nuse fmri_mni2sub.'], mat2str(size(coords)));
end

if any(coords(:,1) < 1 | coords(:,1) > 91) || ...
   any(coords(:,2) < 1 | coords(:,2) > 109) || ...
   any(coords(:,3) < 1 | coords(:,3) > 91)
    error('fmri_regionnumber:coordsOutOfRange', ...
        ['Coordinates fall outside the MNI152 2mm grid.\n' ...
         'Valid range: x = [1 91], y = [1 109], z = [1 91].\n' ...
         'Subscripts are 1-based voxel indices, not millimetres - use ' ...
         'fmri_mni2sub to convert.']);
end

if nargin < 2, atlasnumber = 1; end


[ROI_nos, ROI_labels] = fmri_loadatlas(atlasnumber);
ROI_vect = ROI_nos(:);

% Convert all coordinates to linear indices in one operation for efficient
% atlas lookup.
index = fmri_sub2ind(coords);

n = size(coords, 1);
list_of_regions = cell(n, 1);
regionnumber    = zeros(n, 1);

% NaN marks coordinates outside the brain mask; those have no atlas label.
inside = ~isnan(index);
regionnumber(inside) = ROI_vect(index(inside));

for k = 1:n
    if regionnumber(k) ~= 0
        list_of_regions{k} = ROI_labels{regionnumber(k)};
    else
        % fmri_regiontable relies on this exact label to identify and sort unlabelled
        % rows. Keep the label consistent across both functions.
        list_of_regions{k} = 'Unlabelled';
    end
end

% For a single coordinate, return the region name as a character vector
% rather than a 1 x 1 cell array.
if size(coords,1) == 1
    list_of_regions = list_of_regions{1};
end