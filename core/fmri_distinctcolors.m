function cmap = fmri_distinctcolors(n, seed)
% FMRI_DISTINCTCOLORS  Generates N perceptually distinguishable RGB colours.
%
% Produces a colormap with colours that are as perceptually different
% from each other as possible. Colour differences are measured in CIE
% L*a*b* space, which approximates how humans perceive differences
% between colours. This makes neighbouring labels in an atlas or
% cluster map easier to distinguish. Intended for categorical data
% (atlas regions, Brodmann areas, cluster indices), NOT continuous maps,
% which are better displayed using smooth colormaps such as jet or parula.
%
% Standard colormaps such as hsv become difficult to distinguish when
% many colours are needed. By maximising the perceptual differences
% between colours, this function produces more distinguishable palettes,
% even with 27 or 52 colours.
%
% Usage:
%   cmap = fmri_distinctcolors(n)
%   cmap = fmri_distinctcolors(n, seed)
%   fmri_distinctcolors(n)              % no output: previews the palette
%
% Inputs:
%   N     - Number of colours required.
%   SEED  - Random seed for the candidate pool, so the palette is reproducible.
%           Default: 0. Change it if you dislike the particular colours chosen.
%
% Outputs:
%   CMAP  - N x 3 RGB matrix, values in [0 1]. If called with no output
%           argument, the palette is drawn as numbered swatches instead, so it
%           can be inspected before use. Assigning the result keeps the
%           function silent, so calls from other toolbox functions never open a
%           figure.
%
% Examples:
%   fmri_distinctcolors(27)              % look at the colours first
%   cmap = fmri_distinctcolors(27);      % then use them
%   fmri_showslices_int(atlas_map, 1, 2, cmap)
%
%   cmap = fmri_distinctcolors(27, 5);   % reroll with a different seed
%   fmri_show3dba(thresh_map, 180, 10, [], [], fmri_distinctcolors(30))
%
% Notes:
%   Colours are selected to maximise their perceptual differences.
%   Very dark and very light colours are avoided to ensure good visibility
%   against the grey brain surface and white figure background.
% 
% See also: fmri_show3dba, fmri_showslices_int, fmri_showselectslices_int

if nargin < 2 || isempty(seed), seed = 0; end
if n < 1
    cmap = zeros(0, 3);
    return
end

% Candidate pool, avoiding near-black and near-white
rng_state = rng;                      % preserve the caller's RNG state
c = onCleanup(@() rng(rng_state));
rng(seed);
npool = 6000;
cand  = rand(npool, 3) * 0.85 + 0.10;

% Exclude low-saturation candidates to avoid palettes dominated by greys
% and pale colours. This ensures that selected colours remain vivid and
% easily distinguishable, particularly when only a few colours are needed.

mx  = max(cand, [], 2);
mn  = min(cand, [], 2);
sat = (mx - mn) ./ max(mx, eps);
cand = cand(sat >= 0.35, :);

lab = rgb2lab_local(cand);

% Select colours one at a time, always choosing the colour that is most
% different from those already selected. Start with a random colour so
% that different seeds produce genuinely different palettes.
idx      = zeros(n, 1);
first    = randi(size(cand, 1));
idx(1)   = first;
d        = sqrt(sum((lab - lab(first, :)).^2, 2));
for k = 2:n
    [~, nxt] = max(d);
    idx(k)   = nxt;
    d = min(d, sqrt(sum((lab - lab(nxt, :)).^2, 2)));
end

cmap = cand(idx, :);

% If called without an output argument, display the palette for visual
% inspection. If the colours are assigned to a variable, return the
% colormap without opening a figure.

if nargout == 0
    show_palette(cmap, seed);
    clear cmap
end
end

% -------------------------------------------------------------------------
function show_palette(cmap, seed)
% Draws the colours as numbered swatches so they can be inspected before use.
n = size(cmap, 1);
perRow = 13;                              % wrap long palettes
nRow   = ceil(n / perRow);
nCol   = min(n, perRow);

figure('Name', sprintf('fmri_distinctcolors(%d, %d)', n, seed), ...
       'NumberTitle', 'off', 'Color', 'w');
ax = axes('Position', [0.05 0.08 0.90 0.80]);
hold(ax, 'on');

for k = 1:n
    r = floor((k-1) / perRow);
    c = mod(k-1, perRow);
    patch(ax, c + [0 1 1 0], -r + [0 0 1 1], cmap(k,:), 'EdgeColor', 'none');
    % label in black or white, whichever contrasts with the swatch
    lum = 0.299*cmap(k,1) + 0.587*cmap(k,2) + 0.114*cmap(k,3);
    text(ax, c + 0.5, -r + 0.5, num2str(k), ...
         'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
         'Color', repmat(double(lum < 0.5), 1, 3), 'FontSize', 11);
end

set(ax, 'XLim', [0 nCol], 'YLim', [-(nRow-1) 1], ...
        'XTick', [], 'YTick', [], 'Box', 'off');
axis(ax, 'off');
title(ax, sprintf('%d colours (seed %d) - pass a different seed to reroll', ...
      n, seed), 'FontWeight', 'normal');
hold(ax, 'off');
end

% -------------------------------------------------------------------------
function lab = rgb2lab_local(rgb)
% sRGB to CIE L*a*b* (D65). Local implementation so the toolbox does not
% depend on the Image Processing Toolbox.
m = rgb;
lin = m;
sel = m > 0.04045;
lin(sel)  = ((m(sel) + 0.055) / 1.055) .^ 2.4;
lin(~sel) = m(~sel) / 12.92;

X = lin(:,1)*0.4124 + lin(:,2)*0.3576 + lin(:,3)*0.1805;
Y = lin(:,1)*0.2126 + lin(:,2)*0.7152 + lin(:,3)*0.0722;
Z = lin(:,1)*0.0193 + lin(:,2)*0.1192 + lin(:,3)*0.9505;

X = X / 0.95047;  Z = Z / 1.08883;

f = @(t) (t > 0.008856) .* t.^(1/3) + (t <= 0.008856) .* (7.787*t + 16/116);
fx = f(X); fy = f(Y); fz = f(Z);

lab = [116*fy - 16, 500*(fx - fy), 200*(fy - fz)];
end