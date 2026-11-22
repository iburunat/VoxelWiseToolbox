function fmri_showselectslices_int(data, slices, color, txt, overlayalpha, labels)
% FMRI_SHOWSELECTSLICES_INT  Displays integer data on user-specified axial slices.
%
% Displays selected axial slices from an integer-labelled brain map, using a
% distinct colour for each label. A sagittal locator panel on the left 
% marks the locations of the displayed slices with green lines. This
% is the integer-map counterpart of fmri_showselectslices (for continuous maps),
% and the select-slice counterpart of fmri_showslices_int (which shows a full
% mosaic).
%
% Usage:
%   fmri_showselectslices_int(data, slices)
%   fmri_showselectslices_int(data, slices, color, txt, overlayalpha)
%   fmri_showselectslices_int(data, slices, color, txt, overlayalpha, labels)
%   fmri_showselectslices_int(data, p)     % p from fmri_makevizpar
%
% Inputs:
%   DATA      - Integer brain map, vectorized (228453 x 1) or a volume
%               (91 x 109 x 91). Each unique non-zero integer is a label and is
%               drawn in colour COLOR(label,:). A 4D input is collapsed to a
%               single label map, with volume k contributing label k.
%   SLICES    - Vector of axial slice indices to display, e.g. [20 35 50 65].
%   COLOR     - N x 3 RGB matrix, one row per label. Row L is the colour of
%               label L, so COLOR must have at least max(label) rows.
%               Default: a 6-colour set.
%   TXT       - Show slice labels: 1 = yes, 0 = no. Default: 1. Labels give the
%               slice position in MNI millimetres, matching the coordinates
%               reported by fmri_regiontable, not the 1-91 voxel index passed
%               in SLICES.
%   OVERLAYALPHA - Opacity of the label colours over the brain shell (0-1).
%               Default: 1 (opaque). Overlayalpha=0 makes labels invisible;
%               overlayalpha=0.5 gives semi-transparent labels.
%   LABELS    - Cell array of strings, one per label, naming label 1 to
%               max(label). Default: {} (no key). When given, a key is drawn
%               in a panel to the right of the slices, using the same colours
%               as the map, and the figure widens to make room. About
%               12 entries is the practical limit; beyond that the key is
%               still drawn, with a warning, but is too dense to read.
%
%   Alternatively pass a parameter struct P from fmri_makevizpar as the second
%   argument. Fields used: slices, color (as COLOR), txt (as TXT),
%   overlayalpha, labels.
%
% Examples:
%   fmri_showselectslices_int(atlas_map, [20 35 50 65])
%   fmri_showselectslices_int(clusters, [30 50 70], hsv(10))
%   fmri_showselectslices_int(atlas_map, [20 40 60], hsv(21), 1)
%   fmri_showselectslices_int(region_map, sl, colors, 1, 0.85, region_names)
%
% Notes:
%   Requires graybrain.mat (the greyscale template shell) on the path. Only
%   axial slices are supported, matching fmri_showselectslices.
%
% See also: fmri_showselectslices, fmri_showslices_int, fmri_makevizpar

VERT_PRINT_SIZE = 4;
SLICE_H = 220;    

% ---- PARAMETER HANDLING: defaults first, struct overrides last ------------
% Struct and positional arguments cannot be mixed
if nargin >= 2 && isstruct(slices) && nargin > 2
    error('fmri_showselectslices_int:structAndPositional', ...
        'A parameter struct cannot be combined with positional arguments.');
end

% Positional defaults
if nargin < 3 || isempty(color), color = [1 0 0;0 1 0;0 0 1;1 1 0;1 0 1;0 1 1]; end
if nargin < 4 || isempty(txt),   txt   = 1; end
if nargin < 5 || isempty(overlayalpha), overlayalpha = 1; end
if nargin < 6 || isempty(labels), labels = {}; end

% Struct overrides (if a struct was passed as the second argument)
if nargin >= 2 && isstruct(slices)
    p = slices;  slices = [];
    if isfield(p,'slices'), slices = p.slices; end
    if isfield(p,'color'),  color  = p.color;  end
    if isfield(p,'txt'),    txt    = p.txt;    end
    if isfield(p,'overlayalpha'),  overlayalpha  = p.overlayalpha;  end
    if isfield(p,'labels'), labels = p.labels; end
end

% VALIDATE slices
if isempty(slices) || ~isvector(slices) || any(~isfinite(slices)) || any(slices < 1) || any(slices > 91)
    error('fmri_showselectslices_int:badSlices', ...
        ['SLICES must be a vector of valid axial slice indices (1-91).\n' ...
            'Got %s. Use fmri_juicyslices to choose slices automatically.'], ...
        mat2str(slices));
end

% ---- to volume ---------------------------------------------------------
if ndims(data) < 3
    data = fmri_vect2vol(data);
end

% color is indexed by label value, so it must span the largest label.
maxlabel = 0;
for m = 1:size(data, 4)
    maxlabel = max(maxlabel, m * max(max(max(data(:, :, :, m)))));
end
if maxlabel > size(color, 1)
    error('fmri_showselectslices_int:tooFewColours', ...
        ['DATA contains %d labels but COLOR has only %d rows.\n' ...
         'COLOR must have at least max(label) rows.'], maxlabel, size(color, 1));
end

N = length(slices);

% Reserve space on the right for the key, as fmri_showselectslices does for
% its colourbar.
spwidth  = N*271 + 390;
keyscale = 1;                    % widening factor when a key is drawn
if ~isempty(labels)
    if maxlabel > numel(labels)
        error('fmri_showselectslices_int:labelCountMismatch', ...
              'DATA contains %d labels but LABELS has only %d entries.', ...
              maxlabel, numel(labels));
    end
    if numel(labels) > 12
        warning('fmri_showselectslices_int:manyLabels', ...
            ['%d labels will not fit legibly beside the slices.\n' ...
             'Show fewer regions, or omit LABELS and build a separate key ' ...
             'with fmri_createlegend.'], numel(labels));
    end
    KEY_FONTSIZE = 12;  KEY_MAXLEN = 22;
    % Reserve the key in pixels, converted to layout units, so it holds the
    % labels whatever N is.
    keypx    = 0.6*KEY_FONTSIZE*min(max(cellfun(@numel, labels)), KEY_MAXLEN) + 90;
    spwidth  = spwidth + keypx * 325 / SLICE_H;
    keyscale = spwidth / (N*271 + 390);
end

% ---- slice labels in MNI millimetres ------------------------------------
% Convert the selected axial slice indices to MNI z-coordinates for display.
% The x and y values are fixed placeholders because only z varies.
z_mm = fmri_sub2mni([repmat([46 64], N, 1), slices(:)]);
z_mm = round(z_mm(:, 3));

[x, y] = meshgrid(linspace(1, 109, 325), linspace(1, 91, 271));

% ---- figure sizing -----------------------------------------------------
clf
pos    = get(gcf, 'Position');
sliceh = SLICE_H;
pos(3) = round(spwidth * sliceh / 325);
figh   = sliceh;
yfrac  = sliceh / figh;              % vertical share for the slices
ybot   = (1 - yfrac) / 2;            % centred, key gets the full height
pos(4) = figh;
set(gcf, 'Position', pos);

pos    = get(gcf, 'PaperPosition');
pos(4) = VERT_PRINT_SIZE / yfrac;
pos(3) = spwidth * VERT_PRINT_SIZE / 325;   % same aspect as on screen
set(gcf, 'PaperPosition', pos);
set(gcf, 'Color', 'w')

% ---- greyscale template shell ------------------------------------------
load graybrain               % supplies gb, the greyscale anatomical background
gb = gb .^ 2;                % darken for contrast against the label colours

% ---- one panel per chosen axial slice ----------------------------------
for k = 1:N
    subplot('position', ...
        [390/spwidth + 271*(k-1)/spwidth  ybot  271/spwidth  yfrac])

    % interpolate the grey shell for this slice
    tmp2 = squeeze(gb(:, end:-1:1, slices(k), :));
    tmp3 = zeros(271, 325, 3);
    for m = 1:3
        tmp3(:, :, m) = interp2(tmp2(:, :, m), x, y);
    end
    tmp3 = tmp3 / max(tmp3(:));

    % interpolate the label map for this slice (collapsing any 4th dimension)
    dd = zeros(271, 325);
    for m = 1:size(data, 4)
        datatmp = round(interp2(data(:, end:-1:1, slices(k), m), x, y));
        dd = max(dd, m * datatmp);
    end

    % paint each present label in its colour with overlayalpha blending
    levels = setdiff(unique(dd(:)), 0);
    for n = 1:numel(levels)
        for m = 1:3
            ch = tmp3(:, :, m);
            mask = (dd == levels(n));
            % Blend: (1-overlayalpha)*background + overlayalpha*label_colour
            ch(mask) = (1-overlayalpha) * ch(mask) + overlayalpha * color(levels(n), m);
            tmp3(:, :, m) = ch;
        end
    end
    % transpose to image orientation and draw
    sl = zeros(325, 271, 3);
    for m = 1:3, sl(:, :, m) = tmp3(:, :, m)'; end
    image(sl); axis off
    if txt
        text(136, 290, sprintf('z = %d', z_mm(k)), 'color', 'w', ...
             'fontsize', 12, 'HorizontalAlignment', 'center', ...
             'VerticalAlignment', 'top')   % in MNI
    end
end

% ---- sagittal locator panel, with green lines at the chosen slices -----
subplot('position', [0  ybot  390/spwidth  yfrac])
tmp2 = squeeze(gb(45, :, end:-1:1, :));
tmp5 = zeros(325, 271, 3);
for m = 1:3
    tmp5(:, :, m) = interp2(tmp2(:, :, m), y', x');
end
tmp = zeros(271, 325, 3);
for k = 1:3
    tmp(:, :, k) = squeeze(tmp5(:, :, k)');
end
tmp = tmp / max(tmp(:));

col = [.5 1 .5];                          % green locator lines
tmp(271 - 3*slices + 3, :, 1) = col(1);
tmp(271 - 3*slices + 3, :, 2) = col(2);
tmp(271 - 3*slices + 3, :, 3) = col(3);

tmp = max(tmp, 0); tmp = min(tmp, 1);
image(tmp); axis off

% ---- key, when labels were supplied -------------------------------------
if ~isempty(labels)
    keyh = min(0.95, 22*numel(labels)/figh);         % about 22 px a row
    pad = 10 * 325 / SLICE_H;                     % 10 px, in layout units
    axl = axes('Position', [(N*271 + 390 + pad)/spwidth  0.5 - keyh/2  ...
                            (keypx*325/SLICE_H - 2*pad)/spwidth  keyh]);
    fmri_createlegend(labels(:), color(1:numel(labels), :), 'Axes', axl, ...
                      'MaxLabelLength', KEY_MAXLEN, 'FontSize', KEY_FONTSIZE);
    % Match the key to the figure background, so the right-hand strip reads
    % as one surface rather than a white card dropped onto grey.
    set(axl, 'Color', get(gcf, 'Color'), ...
             'XColor', 'none', 'YColor', 'none', 'Box', 'off');
end

end