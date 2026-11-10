function fmri_atlas(atlas)
% FMRI_ATLAS  Lists all available atlases and their region counts.
%
% Usage:
%   fmri_atlas()     % print full atlas list
%   fmri_atlas(n)    % print region list for atlas n
%
% Inputs:
%   ATLAS - Atlas number (1-19). If omitted, the table of all atlases is
%           printed instead of a region list.
%
% Examples:
%   fmri_atlas          % the 19 atlases, region counts and references
%   fmri_atlas(1)       % the 116 AAL / MarsBar regions
%   fmri_atlas(19)      % Brodmann areas, cortex only
%
% See also: fmri_loadatlas, fmri_regionmask, fmri_regionnumber, fmri_nregion


[~, ~, atlases] = fmri_loadatlas();   % fetch metadata table

if nargin == 0
    fprintf('\n%-4s  %-46s  %-5s  %s\n', '#', 'Atlas', 'ROIs', 'Reference');
    fprintf('%s\n', repmat('-', 1, 90));

    % Convert numeric ROIs to strings
    roi_str = string(atlases.ROIs);
    roi_str = cellstr(roi_str);

    % Print atlas table
    for k = 1:height(atlases)
        fprintf('%-4d  %-46s  %-5s  %s\n', atlases.ID(k), atlases.Name{k}, roi_str{k}, atlases.Reference{k});
    end

    fprintf('\nUsage: fmri_atlas(n) to list region names for atlas n.\n\n');

else
    % Find requested atlas
    idx = find(atlases.ID == atlas, 1);

    if isempty(idx)
        error('fmri_atlas:badAtlas', ...
            'Atlas %d not found. Run fmri_atlas() to see valid numbers.', atlas);
    end

    fprintf('\n=== Atlas %d: %s ===\n', atlases.ID(idx), atlases.Name{idx});

    % Region count is taken from the label list itself rather than the metadata
    % column, so the display cannot silently truncate if the two disagree.
    % fmri_loadatlas returns char labels for every atlas, including Craddock
    % (whose labels are the region numbers as text), so no special case is
    % needed here.
    [ROI_nos, ROI_labels] = fmri_loadatlas(atlas);
    regions = ROI_labels;

    % Flag regions that have no voxels inside the brain mask: they are listed
    % by the atlas but cannot be returned by any lookup.
    present = unique(ROI_nos(ROI_nos > 0));

    for k = 1:numel(regions)
        if ismember(k, present)
            fprintf('  %3d  %s\n', k, regions{k});
        else
            fprintf('  %3d  %s   (no voxels in brain mask)\n', k, regions{k});
        end
    end

    nempty = numel(regions) - numel(present);
    if nempty > 0
        fprintf('\n  %d of %d regions have no voxels in the brain mask.\n', ...
                nempty, numel(regions));
    end

    fprintf('\n');
end
