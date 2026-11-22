function h = fmri_colorbar(cmap, climits, varargin)
% FMRI_COLORBAR  Standalone colour scale, in a window of its own.
%
% Reproduces the value-to-colour mapping a viewer used, as a bar that can be
% placed beside a figure that carries no scale of its own: fmri_braincake,
% fmri_showcortex, fmri_show3d, or a panel assembled by hand.
%
% Usage:
%   h = fmri_colorbar(cmap, climits)
%   h = fmri_colorbar(cmap, climits, 'Threshold', t_crit)
%   h = fmri_colorbar(cmap, climits, 'Ticks', [-8 -4 0 4 8], 'Label', 't')
%
% Inputs:
%   CMAP     - N x 3 colormap, the one passed to the viewer.
%   CLIMITS  - [min max], the limits passed to the viewer. These two fix the
%              mapping: a value V is drawn in the colour at row
%              1 + (V - CLIMITS(1))/diff(CLIMITS) * (N-1).
%
%   Name-value pairs:
%   'Threshold'   - Scalar. Adds ticks at -THRESHOLD and +THRESHOLD, marking
%                   where a grey plateau or display threshold begins.
%                   Default: [].
%   'Ticks'       - Explicit tick values; overrides THRESHOLD. Default: [].
%   'Label'       - Text beside the bar, e.g. 't'. Default: ''.
%   'Orientation' - 'vertical' (default) or 'horizontal'.
%   'FontSize'    - Tick label size. Default: 12.
%   'Position'    - Figure position [x y w h] in pixels. Default: a bar of
%                   160 x 420 (or 420 x 140 horizontal) at the right edge of
%                   the primary screen, clear of the figure it annotates.
%
% Outputs:
%   H        - Figure handle, for exportgraphics or further adjustment.
%
% Examples:
%   fmri_braincake(t_map, -90, 20, 1, sl.axial, 4, 2, 0.08, cl, [], 10, cmap);
%   fmri_colorbar(cmap, cl, 'Threshold', t_crit, 'Label', 't');
%
%   % horizontal bar, for placing under a montage
%   fmri_colorbar(cmap, cl, 'Orientation', 'horizontal', 'Label', 't');
%
% See also: fmri_createlegend, fmri_braincake, fmri_showcortex, fmri_divmap

p = inputParser;
p.addRequired('cmap',    @(x) isnumeric(x) && size(x,2)==3 && size(x,1)>1);
p.addRequired('climits', @(x) isnumeric(x) && numel(x)==2 && x(2)>x(1));
p.addParameter('Threshold', [], @(x) isempty(x) || isscalar(x));
p.addParameter('Ticks', [], @isnumeric);
p.addParameter('Label', '', @(x) ischar(x) || isstring(x));
p.addParameter('Orientation', 'vertical', ...
               @(x) any(strcmpi(x, {'vertical','horizontal'})));
p.addParameter('FontSize', 12, @isscalar);
p.addParameter('Position', [], @(x) isempty(x) || numel(x)==4);
p.parse(cmap, climits, varargin{:});
r = p.Results;

n = size(cmap, 1);
if ~isempty(r.Ticks)
    ticks = unique(r.Ticks(:)');
elseif ~isempty(r.Threshold)
    ticks = unique([climits(1) -abs(r.Threshold) abs(r.Threshold) climits(2)]);
else
    ticks = [];
end

vert = strcmpi(r.Orientation, 'vertical');
if vert, sz = [160 420]; else, sz = [420 140]; end
if isempty(r.Position)
    ss = get(0, 'ScreenSize');                 % right edge, below the menu bar
    r.Position = [ss(3)-sz(1)-40, ss(4)-sz(2)-120, sz];
end
h = figure('Color','w', 'Name','Colour scale', 'NumberTitle','off', ...
           'Position', r.Position);

if vert
    ax = axes('Position',[0.12 0.08 0.28 0.84]);
    image(ax, [0 1], climits, (1:n)');
    set(ax, 'YDir','normal', 'XTick',[], 'YAxisLocation','right');
    if ~isempty(ticks),   set(ax, 'YTick', ticks); end
    if ~isempty(r.Label), ylabel(ax, r.Label);     end
else
    ax = axes('Position',[0.08 0.45 0.84 0.22]);
    image(ax, climits, [0 1], 1:n);
    set(ax, 'YTick',[], 'XAxisLocation','bottom');
    if ~isempty(ticks),   set(ax, 'XTick', ticks); end
    if ~isempty(r.Label), xlabel(ax, r.Label);     end
end
colormap(ax, cmap);
set(ax, 'TickDir','out', 'Box','off', 'FontSize', r.FontSize);
end