function [ROI_nos, ROI_labels, atlas_name, reference] = fmri_loadatlas(atlasnumber)
% FMRI_LOADATLAS  Loads atlas ROI map and region labels by atlas number.
%
% Shared helper used internally by atlas functions. Returns the voxel-wise
% ROI index map and a cell array of region name strings for the requested
% atlas. All 19 atlases in the toolbox are supported.
%
% Usage:
%   T = fmri_loadatlas()            % metadata table for all atlases
%   [~, ~, T] = fmri_loadatlas()    % the same table, third-output form
%   [ROI_nos, ROI_labels]                    = fmri_loadatlas(atlasnumber)
%   [ROI_nos, ROI_labels, name, ref]         = fmri_loadatlas(atlasnumber)
%
% Inputs:
%   ATLASNUMBER - Atlas number (1-19). If omitted, returns only metadata.
%
% Outputs:
%   ROI_NOS    - Vectorized atlas map (228453 x 1).
%   ROI_LABELS - Cell array of region name strings {N x 1}.
%   ATLAS_NAME - Atlas name string (or full metadata cell array if no input).
%   REFERENCE  - Reference string.
%
% Examples:
%   fmri_loadatlas                  % print the table of all 19 atlases
%   T = fmri_loadatlas();           % the same table, as a MATLAB table
%
%   % AAL, with its name and citation
%   [nos, labels, name, ref] = fmri_loadatlas(1);
%   fprintf('%s (%s): %d labels\n', name, ref, numel(labels));
%
%   % Voxels belonging to the first region
%   mask = nos == 1;
%
% See also: fmri_atlas, fmri_regionmask, fmri_regionnumber, fmri_nregion

% Single source of truth for atlas metadata across the toolbox
atlases = {
     1, 'AAL / MarsBar',                             116,  'Tzourio-Mazoyer et al. (2002)';
     2, 'Harvard-Oxford Subcortical',                 21,  'Makris et al. (2006)';
     3, 'Harvard-Oxford Cortical',                    48,  'Makris et al. (2006)';
     4, 'Cerebellar (MNI152 FLIRT, affine)',          28,  'Diedrichsen et al. (2009)';
     5, 'Cerebellar (MNI152 FNIRT, nonlinear)',       28,  'Diedrichsen et al. (2009)';
     6, 'JHU White Matter Labels (ICBM-DTI-81)',      49,  'Hua et al. (2008)';
     7, 'JHU White Matter Tractography Atlas',        20,  'Hua et al. (2008)';
     8, 'Juelich Histological Atlas',                121,  'Eickhoff et al. (2005)';
     9, 'MNI Structural Atlas',                        9,  'Collins et al. (1995); Mazziotta et al. (2001)';
    10, 'Oxford-Imanova Striatal (structural)',        4,  'Tziortzi et al. (2011)';
    11, 'Oxford-Imanova Striatal (connectivity, 3)',   3,  'Tziortzi et al. (2011)';
    12, 'Oxford-Imanova Striatal (connectivity, 7)',   7,  'Tziortzi et al. (2011)';
    13, 'Oxford Thalamic Connectivity Probability',    7,  'Behrens et al. (2003)';
    14, 'Craddock Parcellation 200 ROI',              200, 'Craddock et al. (2012)';
    15, 'Craddock Parcellation 400 ROI',              400, 'Craddock et al. (2012)';
    16, 'Craddock Parcellation 600 ROI',              600, 'Craddock et al. (2012)';
    17, 'Craddock Parcellation 800 ROI',              800, 'Craddock et al. (2012)';
    18, 'Craddock Parcellation 950 ROI',              950, 'Craddock et al. (2012)';
    19, 'Brodmann Areas (Talairach Daemon)',           47, 'Lancaster et al. (2000); Maldjian et al. (2003)';
};

% The ROIs column is the number of LABELS each atlas defines, verified against
% the atlas files instead of quoted from the source papers. Several are lower
% in practice: regions that fall entirely outside the 228453-voxel brain mask
% are present as labels but contain no voxels. fmri_vox2reg warns when it meets
% them.

% If no atlas number requested, return Atlas Table
if nargin < 1 || isempty(atlasnumber)
    % --- create the table ---
    atlas_name = cell2table(atlases, ...
                   'VariableNames', {'ID','Name','ROIs','Reference'});

    % --- auto-display if no outputs requested ---
    if nargout == 0
        disp(atlas_name)
        return  
    end

    ROI_nos    = atlas_name;
    ROI_labels = {};
    reference  = [];
    return
end


% Look up metadata for requested atlas
idx = find([atlases{:,1}] == atlasnumber);
if isempty(idx)
    error('fmri_loadatlas:unknownAtlas', ...
        ['Atlas number %d not recognised. Valid range: 1-19.\n' ...
         'Call fmri_loadatlas with no arguments to list the available atlases.'], ...
        atlasnumber);
end
atlas_name = atlases{idx, 2};
reference  = atlases{idx, 4};

% Load atlas .mat file
switch atlasnumber
    case 1,  load MARSBARlookup
    case 2,  load SUBCORTICAL_HOlookup
    case 3,  load CORTICAL_HOlookup
    case 4,  load CEREBELLUM_MNIflirtlookup
    case 5,  load CEREBELLUM_MNIfnirtlookup
    case 6,  load WHITEMATTERlabels_JHUlookup
    case 7,  load WHITEMATTERtracts_JHUlookup
    case 8,  load JUELICHlookup
    case 9,  load MNIlookup
    case 10, load STRIATUMlookup
    case 11, load STRIATUM_CONN3lookup
    case 12, load STRIATUM_CONN7lookup
    case 13, load THALAMUSlookup
    case 14, load CRADDOCKlookup
    case 15, load CRADDOCKlookup400
    case 16, load CRADDOCKlookup600
    case 17, load CRADDOCKlookup800
    case 18, load CRADDOCKlookup950
    case 19, load BRODMANNlookup
             ROI_nos    = brodmann_nos;
             ROI_labels = brodmann_labels;
end

% --- Talairach Daemon Brodmann maps ---
% These are from Lancaster et al. (2000), as distributed with WFU PickAtlas
% (Maldjian et al., 2003). Cortex only: subcortical structures in the
% source file are dropped, so a subcortical voxel returns 0.
%
% Area 13 is insular cortex. Some sources state that areas 12-16 are absent
% in humans; that follows from their not appearing on Brodmann's published
% surface maps, since the insula is buried in the Sylvian fissure. He 
% recorded four human insular areas and identified them as 13-16 in 1914.

% --- Handle Craddock atlases: convert numeric cells to strings ---
if atlasnumber >= 14 && atlasnumber <= 18
    ROI_labels = cellfun(@num2str, ROI_labels, 'UniformOutput', false);
end

% Trim label whitespace because several atlases include trailing spaces
% (e.g., Harvard-Oxford, AAL, and JHU). These would prevent exact matching
% and consistent grouping by region name.
ROI_labels = strtrim(ROI_labels);

% Standardise ROI_nos to a 228453 x 1 vector. Most bundled atlases store it
% as a 91 x 109 x 91 volume, whereas the five Craddock atlases use a vector.
% Normalising the format here ensures that all callers receive vectorised
% region numbers without needing to handle both representations.
if ndims(ROI_nos) > 2
    ROI_nos = fmri_vol2vect(ROI_nos);
end