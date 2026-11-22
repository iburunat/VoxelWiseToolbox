function info = fmri_show3datlas(atlasnumber, regions, surfalpha, az, el, maskalpha, greypar)
% FMRI_SHOW3DATLAS  3D rendering of atlas regions as coloured isosurfaces.
%
% Displays selected regions from a toolbox atlas as coloured 3D surfaces on
% a transparent brain shell. A legend shows abbreviated region names, while
% INFO returns the full names.
%
% Usage:
%   fmri_show3datlas(atlasnumber)
%   fmri_show3datlas(atlasnumber, regions)
%   fmri_show3datlas(atlasnumber, regions, surfalpha)
%   fmri_show3datlas(atlasnumber, regions, surfalpha, az, el, maskalpha)
%   fmri_show3datlas(atlasnumber, p)           % p from fmri_makevizpar
%   info = fmri_show3datlas(...)
%
% Inputs:
%   ATLASNUMBER - Atlas number (1-19). Run fmri_atlas() to list atlases.
%   REGIONS     - Region numbers to display. Default: all regions present in
%                 the brain mask. If more than 40 regions would be displayed,
%                 the function asks for confirmation because the result may be
%                 slow and difficult to interpret.
%   SURFALPHA   - Region-surface opacity, from 0 (transparent) to 1 (opaque).
%                 Default: 1. Pass one value for all regions or one value per
%                 displayed region. Lower values help reveal deeper structures.
%   AZ, EL      - View azimuth and elevation in degrees. Default: 0, 0.
%   MASKALPHA   - Opacity of the surrounding brain shell, 0 (hidden) to 1
%                 (opaque). Default: 0.05.
%   GREYPAR     - Depth shading, 0 to 1. Fades far surfaces toward white, so
%                 they read paler than the legend swatches. Default: 0.4;
%                 lower it to match the key, 0 turns it off.
% 
%   Alternatively pass a parameter struct P from fmri_makevizpar as the second
%   argument, in place of REGIONS. Fields used: surfalpha, az, el, maskalpha.
%
% Outputs:
%   INFO - Struct describing what was drawn:
%          .atlas          atlas name string
%          .regions        region numbers shown (K x 1)
%          .names          full region names (K x 1 cell)
%          .abbrev         abbreviated names used in the legend (K x 1 cell)
%          .colors         RGB colour per region (K x 3), matching the legend
%          .surfalpha      opacity used for the region surfaces
%          .maskalpha      opacity used for the brain shell
%          .ax             axis handle of the rendering
%
% Examples:
%   % Whole small atlas
%   fmri_show3datlas(9);                       % MNI Structural (9 regions)
%
%   % A chosen subset of a large atlas, from a specific view
%   info = fmri_show3datlas(1, [1 2 37 38], 0.5, 120, 20);   % AAL: 4 regions
%   info.names        % full names of what was drawn
%
%   % Make deep structures visible through the cortex with lower opacity
%   fmri_show3datlas(2, [], 0.3);              % Harvard-Oxford Subcortical
%
% Notes:
%   Colours come from fmri_distinctcolors, so adjacent regions are as visually
%   separable as possible, and the same colour is used for a region's surface
%   and its legend swatch. 
%
% See also: fmri_show3d, fmri_loadatlas, fmri_atlas, fmri_distinctcolors,
%           fmri_regionmask

% ---- load the atlas ------------------------------------------------------
[ROI_nos, ROI_labels, atlas_name] = fmri_loadatlas(atlasnumber);

if nargin >= 2 && isstruct(regions) && nargin > 2
    error('fmri_show3datlas:structAndPositional', ...
        'A parameter struct cannot be combined with positional arguments.');
end
if nargin >= 2 && isstruct(regions)
    p = regions;  regions = [];
    if isfield(p,'surfalpha'), surfalpha = p.surfalpha; end
    if isfield(p,'az'),           az       = p.az;           end
    if isfield(p,'el'),           el       = p.el;           end
    if isfield(p,'maskalpha'), maskalpha = p.maskalpha; end
    if isfield(p,'greypar'),   greypar   = p.greypar;   end
end

% Region numbers that actually have voxels inside the brain mask.
present = unique(ROI_nos(ROI_nos > 0));

% ---- decide which regions to draw ----------------------------------------
if nargin < 2 || isempty(regions)
    regions = present;
else
    regions = regions(:);
    missing = regions(~ismember(regions, present));
    if ~isempty(missing)
        warning('fmri_show3datlas:missingRegions', ...
            ['These requested regions have no voxels in the brain mask and ' ...
             'will be skipped: %s'], mat2str(missing'));
        regions = regions(ismember(regions, present));
    end
end

if isempty(regions)
    error('fmri_show3datlas:nothingToShow', ...
          ['No renderable regions.\n' ...
           'Run fmri_atlas(%d) to see which regions have voxels in the mask.'], ...
          atlasnumber);
end

% ---- guard against rendering an overwhelming number of regions -----------
% Above 40 regions the plot is slow to build and the legend is unreadable, so
% confirm before proceeding and give the user the chance to cancel and pass a
% subset instead.
nreg = numel(regions);
if nreg > 40
    prompt = sprintf(['You are about to render %d regions. This is slow and ' ...
                      'the legend will be dense.\nContinue anyway? Cancel to ' ...
                      'select a subset via the REGIONS argument. [y/N]: '], nreg);
    answer = input(prompt, 's');
    if isempty(answer) || ~strncmpi(answer, 'y', 1)
        fprintf(['Cancelled. Re-run with a subset, e.g.\n' ...
                 '    fmri_show3datlas(%d, [1 2 3]);\n'], atlasnumber);
        info = struct('atlas', atlas_name, 'regions', [], 'names', {{}}, ...
                      'abbrev', {{}}, 'colors', [], 'surfalpha', [], ...
                      'maskalpha', [], 'ax', []);
        return
    end
end

% ---- build one binary map per region, and pick distinct colours ----------
region_maps = zeros(numel(ROI_nos), nreg);
for k = 1:nreg
    region_maps(:, k) = double(ROI_nos == regions(k));
end
colors = fmri_distinctcolors(nreg);

if ~exist('surfalpha','var') || isempty(surfalpha), surfalpha = 1; end
if ~exist('az','var')    || isempty(az),    az    = 0;   end
if ~exist('el','var')    || isempty(el),    el    = 0;   end
if ~exist('maskalpha','var') || isempty(maskalpha), maskalpha = 0.05; end
if ~exist('greypar','var')   || isempty(greypar),   greypar   = 0.4;  end

% Validate surfalpha
if ~isscalar(surfalpha) && numel(surfalpha) ~= nreg
    error('fmri_show3datlas:surfalphaLength', ...
          ['SURFALPHA must be a scalar or have one value per shown region ' ...
           '(%d given for %d regions).\n' ...
           'Note that regions absent from the brain mask are dropped, which ' ...
           'may change the count.'], numel(surfalpha), nreg);
end
if any(surfalpha < 0 | surfalpha > 1)
    error('fmri_show3datlas:surfalphaRange', ...
          'SURFALPHA values must lie in [0, 1]; got %s.', mat2str(surfalpha(:)'));
end

if ~isscalar(maskalpha) || maskalpha < 0 || maskalpha > 1
    error('fmri_show3datlas:maskalphaRange', ...
          'MASKALPHA must be a scalar in [0, 1]; got %s.', mat2str(maskalpha));
end

% ---- names and abbreviated legend ----------------------------------------
names  = cell(nreg, 1);
abbrev = cell(nreg, 1);
for k = 1:nreg
    if regions(k) <= numel(ROI_labels)
        names{k} = ROI_labels{regions(k)};
    else
        names{k} = sprintf('region %d', regions(k));
    end
    abbrev{k} = abbreviate_region(names{k});
end

fmri_show3d(region_maps, az, el, [], surfalpha, colors, maskalpha, [], greypar, abbrev);
set(gcf, 'Name', atlas_name, 'NumberTitle', 'off');
ax = gca;

% ---- return description ---------------------------------------------------
info = struct('atlas', atlas_name, 'regions', regions, 'names', {names}, ...
              'abbrev', {abbrev}, 'colors', colors, 'surfalpha', surfalpha, ...
              'maskalpha', maskalpha, 'greypar', greypar, 'ax', ax);
end