function fmri_show3dhalfbrains(data, level, surfalpha, color, maskalpha, margin)
% FMRI_SHOW3DHALFBRAINS  Plots activation on four lateral and medial hemisphere views.
%
% Renders the left and right hemispheres separately (both lateral and medial
% views) and displays them as a single composite figure. The four panels are:
%        Left lateral | Left medial | Right medial | Right lateral
%
% Usage:
%   fmri_show3dhalfbrains(data)
%   fmri_show3dhalfbrains(data, level, surfalpha, color, maskalpha, margin)
%   fmri_show3dhalfbrains(data, p)        % p from fmri_makevizpar
%
% Inputs:
%   DATA       - fMRI data, vectorized (228453 x n) or volume (91x109x91xn).
%                Binary or continuous values; each column is rendered separately.
%   LEVEL      - Isosurface threshold level. Default: 0.1
%   SURFALPHA  - Opacity of activation surface. Default: 1
%   COLOR      - N x 3 colormap matrix; row k = colour for data column k.
%                Default: [1 0 0; 0 1 0; 0 0 1; 1 1 0; 1 0 1; 0 1 1]
%   MASKALPHA  - Opacity of the transparent brain shell. Default: 0.08
%   MARGIN     - Inter-panel margin as a percentage of panel width. Default: 10
%
%   Alternatively, pass a parameter struct P from fmri_makevizpar as the second
%   argument. Fields used: level, surfalpha, color, maskalpha, margin.
%
% Examples:
%   fmri_show3dhalfbrains(activation_map)
%   fmri_show3dhalfbrains(data, 0.5, 0.8, [1 0 0; 0 0 1], 0.1)
%
% See also: fmri_show3d, fmri_showcortex, fmri_showslices

% --- PARAMETER HANDLING: defaults first, struct overrides last ------------
% Struct and positional arguments cannot be mixed
if nargin >= 2 && isstruct(level) && nargin > 2
    error('fmri_show3dhalfbrains:structAndPositional', ...
        'A parameter struct cannot be combined with positional arguments.');
end

% Positional defaults
if nargin < 2 || isempty(level),     level      = 0.1;  end
if nargin < 3 || isempty(surfalpha), surfalpha  = 1;    end
if nargin < 4 || isempty(color),     color      = [1 0 0;0 1 0;0 0 1;1 1 0;1 0 1;0 1 1]; end
if nargin < 5 || isempty(maskalpha), maskalpha  = 0.08; end
if nargin < 6 || isempty(margin),    margin     = 10;   end

% Struct overrides (if a struct was passed as the second argument)
if nargin >= 2 && isstruct(level)
    p = level;  level = 0.1;                 % Reset level so it doesn't remain a struct
    if isfield(p,'level'),     level     = p.level;     end
    if isfield(p,'surfalpha'), surfalpha = p.surfalpha;  end
    if isfield(p,'color'),     color     = p.color;     end
    if isfield(p,'maskalpha'), maskalpha = p.maskalpha; end
    if isfield(p,'margin'),    margin    = p.margin;    end
end

% Pass SURFALPHA directly to fmri_show3d, which expands scalar values and
% checks that vector values match the number of maps.

crops = { [1  46 1 109 1 91], ...   % left hemisphere  (lateral)
          [1  46 1 109 1 91], ...   % left hemisphere  (medial)
          [46 91 1 109 1 91], ...   % right hemisphere (medial)
          [46 91 1 109 1 91] };     % right hemisphere (lateral)
azs   = [180, 0, 180, 0];

% Render each view into an offscreen figure and capture it.
imgs = cell(1, 4);
for m = 1:4
    fig = figure('Visible', 'off');
    fmri_show3d(data, azs(m), 0, level, surfalpha, color, maskalpha, crops{m});
    set(gca, 'Position', [0 0 1 1]);
    drawnow;
    frame      = getframe(fig);
    imgs{m}    = frame.cdata;
    close(fig);
end

% Crop each image to remove whitespace, then concatenate horizontally
composite = {};
for m = 1:4
    img = double(imgs{m});

    % Find the columns that actually contain the brain.
    bg   = squeeze(mean([img(1,1,:), img(1,end,:), img(end,1,:), img(end,end,:)], 2));
    if m == 1, bgpad = bg; end
    dev  = sum(sum(abs(img - reshape(bg,1,1,3)), 1), 3);
    dev  = squeeze(dev);

    bright  = dev > 0.02 * max(dev);
    first_c = find(bright, 1, 'first');
    last_c  = find(bright, 1, 'last');
    if isempty(first_c)
        first_c = 1; last_c = size(img,2);
    end

    devr    = squeeze(sum(sum(abs(img - reshape(bg,1,1,3)), 2), 3));
    brightr = devr > 0.02 * max(devr);
    first_r = find(brightr, 1, 'first');
    last_r  = find(brightr, 1, 'last');
    if isempty(first_r)
        first_r = 1; last_r = size(img,1);
    end

    padx    = round(margin/100 * (last_c - first_c + 1));
    pady    = round(margin/100 * (last_r - first_r + 1));
    padL    = padx;
    padR    = padx;
    edgepad = round(1.5 * padx);
    if m == 1, padL = edgepad; end
    if m == 4, padR = edgepad; end

    left_c  = max(1,           first_c - padL);
    right_c = min(size(img,2), last_c  + padR);
    top_r   = max(1,           first_r - pady);
    bot_r   = min(size(img,1), last_r  + pady);

    composite{m} = imgs{m}(top_r:bot_r, left_c:right_c, :); %#ok<AGROW>
end

% Pad to a common height before joining.
h = max(cellfun(@(x) size(x,1), composite));
for m = 1:4
    d = h - size(composite{m},1);
    if d > 0
        dtop = floor(d/2);
        dbot = d - dtop;
        w    = size(composite{m},2);
        c    = size(composite{m},3);
        padT = repmat(reshape(bgpad, 1, 1, []), dtop, w, 1);
        padB = repmat(reshape(bgpad, 1, 1, []), dbot, w, 1);
        composite{m} = cast([padT; double(composite{m}); padB], 'like', composite{m});
    end
end
composite = horzcat(composite{:});

% Display composite figure.
aspect = size(composite,2) / size(composite,1);
winH   = 260;
winW   = round(winH * aspect);
maxW   = 1600;
if winW > maxW
    winW = maxW;
    winH = round(winW / aspect);
end

hf = figure('Color', 'w');
pos = get(hf, 'Position');
set(hf, 'Position', [pos(1) pos(2) winW winH]);

ax = axes('Parent', hf, 'Position', [0 0 1 1]);
set(ax, 'LooseInset', [0 0 0 0]);
image(composite, 'Parent', ax);
axis(ax, 'image');
axis(ax, 'off');

set(hf, 'PaperUnits', 'inches');
set(hf, 'PaperPosition', [0 0 4*aspect 4]);