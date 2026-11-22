function fmri_show3dba(data, az, el, level, surfalpha, color, maskalpha, crop, greypar)
% FMRI_SHOW3DBA  3D rendering of a map split by Brodmann area.
%
% Splits a thresholded brain map by Brodmann area and renders each area as a
% separately coloured isosurface, with a legend listing the area numbers beside
% the brain. Useful for seeing which Brodmann areas a contrast involves.
%
% Usage:
%   fmri_show3dba(data)
%   fmri_show3dba(data, az, el, level, surfalpha, color, maskalpha, crop)
%   fmri_show3dba(data, p)        % p from fmri_makevizpar
%
% Inputs:
%   DATA      - Brain map, vectorized (228453 x 1). Voxels at or above LEVEL
%               are assigned to Brodmann areas. Pass either a thresholded map
%               with LEVEL in (0,1), or the map itself with LEVEL set to your
%               statistical threshold. The two give near-identical surfaces.
%   AZ        - Azimuth angle in degrees. Default: 0.
%   EL        - Elevation angle in degrees. Default: 0.
%   LEVEL     - Isosurface value, in the units of DATA, and also the cut-off
%               deciding which areas appear. Default: 0.1, which enlarges the
%               surfaces so small pieces stay visible; use 0.5 to draw them at
%               their true size. See fmri_show3d.
%   SURFALPHA - Opacity of the area surfaces, scalar or one value per area.
%               Default: 1.
%   COLOR     - N x 3 RGB matrix, one colour per Brodmann area found.
%               Default: fmri_distinctcolors(number of areas), which keeps the
%               colours perceptually distinguishable however many areas there
%               are. Supplying fewer rows than there are areas warns, and the
%               palette is replaced by fmri_distinctcolors.
%   MASKALPHA - Opacity of the background brain shell. Default: 0.05.
%   CROP      - Bounding box [xmin xmax ymin ymax zmin zmax], or a mask.
%               Default: full brain.
%
%   Alternatively pass a parameter struct P from fmri_makevizpar as the second
%   argument. Fields used: az, el, level, surfalpha, color, maskalpha, crop.
%
% Examples:
%   fmri_show3dba(thresh_map)
%   fmri_show3dba(thresh_map, 180, 10)
%   fmri_show3dba(thresh_map, fmri_makevizpar('az', 180, 'el', 10))
%
% Notes:
%   The map is split by Brodmann area, and each area is rendered in a
%   different colour. Unlabelled and non-cortical voxels are not shown.
%
%   A fixed key beside the brain identifies the areas present.
%
% See also: fmri_show3d, fmri_show3datlas, fmri_showcortex, fmri_regiontable,
%           fmri_banumber, fmri_makevizpar

% LEVEL decides which voxels count as active
if nargin >= 2 && isstruct(az) && isfield(az,'level'), level = az.level; end
level_given = exist('level','var') == 1 && ~isempty(level);
if ~level_given, level = 0.1; end

% A label map carries several distinct positive values, none of which is a
% threshold, so LEVEL cannot mean the same thing for a label of 1 and a label
% of 8. With no LEVEL given, reduce it to its support before the split.
if ~level_given
    u = unique(data(data ~= 0));
    if numel(u) > 1 && all(u > 0) && all(u == round(u))
        data = double(data > 0);
    end
end

% ---- split the map by Brodmann area ------------------------------------
[brv, brv_labels] = fmri_loadatlas(19);

bru = unique(brv(data ~= 0 & data >= level));
bru(bru == 0) = [];              % 0 is "no area", not a region

if isempty(bru)
    warning('fmri_show3dba:noAreas', ...
        ['No Brodmann areas found in the data; nothing to render.\n' ...
         'The Brodmann maps cover cortex only, so a map confined to white ' ...
         'matter,\ncerebellum or subcortex has no areas to split by.']);
    return
end

data2 = zeros(numel(data), numel(bru));
for k = 1:numel(bru)
    data2(:, k) = data .* (brv == bru(k));
end

% ---- parameter handling -------------------------------------------------
% Apply struct values before defaults. The default colours depend on the
% number of Brodmann areas found above.
if nargin >= 2 && isstruct(az) && nargin > 2
    error('fmri_show3dba:structAndPositional', ...
        ['A parameter struct cannot be combined with positional arguments: ' ...
         'the struct\noverrides them, so the positional values would be ' ...
         'silently discarded.']);
end
if nargin >= 2 && isstruct(az)
    p = az;  clear az
    if isfield(p,'az'),        az        = p.az;        end
    if isfield(p,'el'),        el        = p.el;        end
    if isfield(p,'level'),     level     = p.level;     end
    if isfield(p,'surfalpha'), surfalpha = p.surfalpha; end
    if isfield(p,'color'),     color     = p.color;     end
    if isfield(p,'maskalpha'), maskalpha = p.maskalpha; end
    if isfield(p,'crop'),      crop      = p.crop;      end
end

if ~exist('az','var')        || isempty(az),        az        = 0;    end
if ~exist('el','var')        || isempty(el),        el        = 0;    end
if ~exist('level','var')     || isempty(level),     level     = 0.1;  end
if ~exist('surfalpha','var') || isempty(surfalpha), surfalpha = 1;    end
if ~exist('maskalpha','var') || isempty(maskalpha), maskalpha = 0.05; end
if ~exist('crop','var')      || isempty(crop),      crop      = [1 91 1 109 1 91]; end
if ~exist('greypar','var')   || isempty(greypar), greypar = 0.4; end
if ~exist('color','var')     || isempty(color)
    % One perceptually distinct colour per area. A fixed palette repeated to
    % fill
    color = fmri_distinctcolors(numel(bru));
end

if size(color, 1) < numel(bru)
    warning('fmri_show3dba:tooFewColours', ...
        ['Only %d colours supplied for %d Brodmann areas, so the supplied ' ...
         'palette is ignored and replaced with fmri_distinctcolors(%d).\n' ...
         'Pass at least %d rows via COLOR (or p.color) to choose your own.'], ...
        size(color,1), numel(bru), numel(bru), numel(bru));
    color = fmri_distinctcolors(numel(bru));
end


% Pass SURFALPHA to fmri_show3d, which handles scalar expansion and validates
% one value per map.
% ---- render, then draw the key -----------------------------------------
fmri_show3d(data2, az, el, level, surfalpha, color, maskalpha, crop, greypar)
draw_area_legend(bru, color, brv_labels(bru));
end

% -------------------------------------------------------------------------
function draw_area_legend(bru, color,labels)
% Draw the area key beside the brain. Show abbreviated labels when provided;
% otherwise, show area numbers only.
n = numel(bru);
if n == 0, return; end
if nargin < 3, labels = {}; end
named = ~isempty(labels);

% Widen the figure so the brain renders at the same size as an fmri_show3d
% figure, with or without a key.
if named, panelw = 0.26; else, panelw = 0.17; end
f  = 1 - panelw - 0.02;                 % share of the new width kept for the brain
% Remember the width before widening, so repeated calls into the same figure
% widen from the original each time instead of compounding.
fp = get(gcf, 'Position');
if isappdata(gcf, 'fmri_basewidth')
    basew = getappdata(gcf, 'fmri_basewidth');
else
    basew = fp(3);
    setappdata(gcf, 'fmri_basewidth', basew);
end
set(gcf, 'Position', [fp(1) fp(2) basew/f fp(4)]);

pp = get(gcf, 'PaperPosition');
set(gcf, 'PaperPosition', [pp(1) pp(2) pp(3)/f pp(4)]);

ax3d = gca;
set(ax3d, 'Position', [0.1*f  0.1  0.8*f  0.8]);
perCol = 18;                               % entries per column
nCol   = ceil(n / perCol);
nRow   = min(n, perCol);

legend_height = 0.05 + (nRow / perCol) * 0.85;
legend_y      = 0.05 + (0.90 - legend_height) / 2;

axl = axes('Position', [0.9*f + 0.02, legend_y, 0.96 - 0.9*f, legend_height]);
hold(axl, 'on');
set(axl, 'XLim', [-0.1 nCol+0.1], 'YLim', [-0.1 nRow+0.1], ...
         'YDir', 'reverse', 'XTick', [], 'YTick', [], ...
         'Color', get(gcf, 'Color'), 'XColor', 'none', 'YColor', 'none', 'Box', 'off');
fs = 12;
if nRow > 14, fs = 10; end
if nRow > 24, fs = 8;  end

for k = 1:n
    col = floor((k-1) / perCol);
    row = mod(k-1, perCol) + 0.5;

    patch(axl, col + [0.08 0.30 0.30 0.08], row + [-0.32 -0.32 0.32 0.32], ...
          color(k,:), 'EdgeColor', 'none');

    if named
        txt = abbreviate_region(labels{k});
    else
        txt = num2str(bru(k));
    end
    text(axl, col + 0.38, row, txt, 'FontSize', fs, ...
         'VerticalAlignment', 'middle', 'Color', 'k', 'Interpreter', 'none');
end

% title(axl, 'Brodmann area', 'FontSize', fs + 1, 'Color', 'k');
hold(axl, 'off');

% Restore the 3D axes as the current axes without redrawing the figure.
set(gcf, 'CurrentAxes', ax3d);
end