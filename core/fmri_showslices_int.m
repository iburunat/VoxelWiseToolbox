function fmri_showslices_int(data, plane, interval, color, txt, overlayalpha, labels)
% FMRI_SHOWSLICES_INT  Displays integer-labelled brain data as a coloured slice mosaic.
%
% Displays an integer-valued brain map, such as an atlas, cluster map or
% network parcellation, as a slice mosaic. Each non-zero integer label is
% shown in a distinct colour. This is the integer-map counterpart of
% fmri_showslices, which is for continuous maps (z, r, t, ...).
%
% Usage:
%   fmri_showslices_int(data)
%   fmri_showslices_int(data, plane, interval, color, txt, overlayalpha)
%   fmri_showslices_int(data, plane, interval, color, txt, overlayalpha, labels)
%   fmri_showslices_int(data, p)        % p from fmri_makevizpar
%
% Inputs:
%   DATA       - Integer brain map, vectorized (228453 x 1) or a volume
%                (91 x 109 x 91). Each unique non-zero integer is a label and
%                is drawn in the colour COLOR(label,:). A 4D input is collapsed
%                to a single label map, with volume k contributing label k.
%   PLANE      - Slice plane: 1 = axial (default), 2 = sagittal.
%                (3 = coronal is not yet implemented; see Notes.)
%   INTERVAL   - Voxel spacing between displayed slices: 1 or 2. Default: 2.
%   COLOR      - N x 3 RGB matrix, one row per label. Row L is the colour of
%                label L. Default: an 8-colour set. There must be at least as
%                many rows as the largest label in the data.
%   TXT        - If nonzero/true, print each slice's position on the tile.
%                Default: 1. Labels are MNI millimetres on the axis being
%                sliced - z for an axial mosaic, x for a sagittal one -
%                matching the coordinates fmri_regiontable reports, not the
%                1-91 grid index.
%   OVERLAYALPHA - Opacity of the label colours over the brain shell (0-1).
%                Default: 1 (opaque).
%   LABELS     - Cell array of strings, one per label, naming label 1 to
%                max(label). Default: {} (no key). When given, a key is drawn
%                in a panel to the right of the mosaic, using the same colours
%                as the map, and the figure widens to make room. About 12
%                entries is the practical limit; beyond that the key is still
%                drawn, with a warning, but is too dense to read.
%
%   Alternatively, pass a parameter struct P from fmri_makevizpar as the second
%   argument. Fields used: plane, interval, color, txt (as TXT), overlayalpha,
%   labels.
%
% Examples:
%   fmri_showslices_int(atlas_map)
%   fmri_showslices_int(region_map, 1, 2, colors, 1, 0.85, region_names)
%
%   % Cluster map from fmri_findclusters, one distinct colour per cluster
%   clusters = fmri_findclusters(t_map > 4.14, 18);
%   fmri_showslices_int(clusters, 1, 2, fmri_distinctcolors(max(clusters)))
%   fmri_showslices_int(roi_indices, 1, 2, hsv(20))
%   p = fmri_makevizpar('plane', 2, 'interval', 2);
%   fmri_showslices_int(atlas_map, p)
%
% Notes:
%   Coronal display (plane = 3) is documented in fmri_makevizpar for
%   consistency across the toolbox but is not yet implemented here; passing
%   plane = 3 raises an error.
%
%   Requires graybrain.mat (the greyscale template shell) on the path.
%
% See also: fmri_showslices, fmri_showselectslices_int, fmri_show3dba, fmri_makevizpar

% ---- PARAMETER HANDLING: defaults first, struct overrides last ------------
% Struct and positional arguments cannot be mixed
if nargin >= 2 && isstruct(plane) && nargin > 2
    error('fmri_showslices_int:structAndPositional', ...
        'A parameter struct cannot be combined with positional arguments.');
end

% Positional defaults
if nargin < 2 || isempty(plane),    plane    = 1;  end
if nargin < 3 || isempty(interval), interval = 2;  end
if nargin < 4 || isempty(color),    color    = [1 0 0;0 1 0;0 0 1;1 1 0;1 0 1;0 1 1;1 1 1;1 .5 0]; end
if nargin < 5 || isempty(txt),      txt      = 1;  end
if nargin < 6 || isempty(overlayalpha),    overlayalpha    = 1;  end
if nargin < 7 || isempty(labels),          labels          = {}; end

% Struct overrides (if a struct was passed as the second argument)
if nargin >= 2 && isstruct(plane)
    p = plane;  plane = 1;                   % Reset plane so it doesn't remain a struct
    if isfield(p,'plane'),    plane    = p.plane;    end
    if isfield(p,'interval'), interval = p.interval; end
    if isfield(p,'color'),    color    = p.color;    end
    if isfield(p,'txt'),      txt      = p.txt;      end
    if isfield(p,'overlayalpha'),    overlayalpha    = p.overlayalpha;    end
    if isfield(p,'labels'),   labels   = p.labels;   end
    
end

if ~ismember(plane, [1 2])
    if plane == 3
        error('fmri_showslices_int:coronalNotSupported', ...
              'Coronal display (plane = 3) is not yet implemented.');
    end
    error('fmri_showslices_int:badPlane', ...
          'PLANE must be 1 (axial) or 2 (sagittal).');
end
if ~ismember(interval, [1 2])
    error('fmri_showslices_int:badInterval', 'INTERVAL must be 1 or 2.');
end

% ---- to volume, then collapse any 4th dimension to a single label map --
if ndims(data) < 3
    data = fmri_vect2vol(data);
end
temp = zeros(91, 109, 91);
for k = 1:size(data, 4)
    temp = max(temp, k * data(:, :, :, k));    
end

% ---- mask to the brain and check the colormap has enough colours -------
load graybrain            % provides gb (91 x 109 x 91 x 3 greyscale shell)
mask = sum(gb, 4) > 1;
d    = temp .* (mask > 0);

if max(d(:)) > size(color, 1)
    error('fmri_showslices_int:tooFewColours', ...
        ['DATA contains %d labels but COLOR has only %d rows.\n' ...
         'COLOR must have at least max(label) rows.'], max(d(:)), size(color, 1));
end

% Reserve space on the right for the key, when labels were supplied.
keyscale = 1;
if ~isempty(labels)
    if max(d(:)) > numel(labels)
        error('fmri_showslices_int:labelCountMismatch', ...
              'DATA contains %d labels but LABELS has only %d entries.', ...
              max(d(:)), numel(labels));
    end
    if numel(labels) > 12
        warning('fmri_showslices_int:manyLabels', ...
            ['%d labels will not fit legibly beside the mosaic.\n' ...
             'Show fewer regions, or omit LABELS and build a separate key ' ...
             'with fmri_createlegend.'], numel(labels));
    end
    keyscale = 1.35;
end

% ---- paint each label colour into the grey shell (direct blending) -----
gb = gb .^ 2;
ddd = gb;  % Start with original grey brain
for level = 1:max(d(:))
    if any(d(:) == level)  % Only if label exists
        for k = 1:3
            tmp = squeeze(ddd(:, :, :, k));
            idx = (d == level);
            tmp(idx) = (1 - overlayalpha) * tmp(idx) + overlayalpha * color(level, k);
            ddd(:, :, :, k) = tmp;
        end
    end
end

% ---- slice labels in MNI millimetres ------------------------------------
idx_all = (1:91)';
if plane == 1
    mm       = fmri_sub2mni([repmat([46 64], 91, 1), idx_all]);
    mm_label = round(mm(:, 3));
else
    mm       = fmri_sub2mni([idx_all, repmat([64 37], 91, 1)]);
    mm_label = round(mm(:, 1));
end

% ---- lay the slices out as a mosaic ------------------------------------
if plane == 1                       % axial
    if interval == 1
        for k = 1:72
            x = mod(k-1, 9); y = floor((k-1)/9);
            subplot('position', [x/9/keyscale y/8 1/9/keyscale 1/8])
            image(squeeze(ddd(:, :, 5+k, :)));
            % if txt, text(10, 10, num2str(5+k), 'color', 'w'); end
            if txt, text(10, 10, num2str(mm_label(5+k)), 'color', 'w'); end
            
            axis off
        end
    else                                % interval == 2
        for k = 1:36
            x = mod(k-1, 6); y = floor((k-1)/6);
            subplot('position', [x/6/keyscale y/6 1/6/keyscale 1/6])
            image(squeeze(ddd(:, :, 6+2*k, :)));
            % if txt, text(10, 10, num2str(6+2*k), 'color', 'w'); end
            if txt, text(10, 10, num2str(mm_label(6+2*k)), 'color', 'w'); end
            axis off
        end
    end

elseif plane == 2                   % sagittal
    tmp = zeros(91, 109, 3);
    if interval == 1
        for k = 1:72
            x = mod(k-1, 9); y = floor((k-1)/9);
            subplot('position', [x/9/keyscale y/8 1/9/keyscale 1/8])
            tmp2 = squeeze(ddd(10+k, :, end:-1:1, :));
            for m = 1:3, tmp(:, :, m) = squeeze(tmp2(:, :, m))'; end
            image(tmp)
            % if txt, text(10, 10, num2str(10+k), 'color', 'w'); end
            if txt, text(10, 10, num2str(mm_label(10+k)), 'color', 'w'); end
            axis off
        end
    else                                % interval == 2
        for k = 1:36
            ind = 2*k + 9;
            x = mod(k-1, 6); y = floor((k-1)/6);
            subplot('position', [x/6/keyscale y/6 1/6/keyscale 1/6])
            tmp2 = squeeze(ddd(ind, :, end:-1:1, :));
            for m = 1:3, tmp(:, :, m) = squeeze(tmp2(:, :, m))'; end
            image(tmp)
            % if txt, text(10, 10, num2str(ind), 'color', 'w'); end
            if txt, text(10, 10, num2str(mm_label(ind)), 'color', 'w'); end
            axis off
        end
    end
  
end

% ---- preserve slice proportions -----------------------------------------
% Set the figure aspect ratio from the mosaic layout and slice dimensions so
% axial and sagittal slices are displayed without distortion. Keep this
% adjustment outside the plane-specific branches so it applies to both.
if interval == 1
    tile = [9 8];       % 9 columns x 8 rows
else
    tile = [6 6];
end

slice_aspect = size(ddd,2) / size(ddd,1);   % 109/91, both planes
fig_aspect   = keyscale * (tile(1)/tile(2)) * slice_aspect;

pos = get(gcf,'Position');       pos(3) = fig_aspect*pos(4);  set(gcf,'Position',pos);
pos = get(gcf,'PaperPosition');  pos(3) = fig_aspect*pos(4);  set(gcf,'PaperPosition',pos);

% ---- key, when labels were supplied -------------------------------------
if ~isempty(labels)
    keyh = min(0.80, 0.07*numel(labels) + 0.04);     % fit the panel to its rows
    axl  = axes('Position', [1/keyscale + 0.01  0.5 - keyh/2  ...
                             1 - 1/keyscale - 0.03  keyh]);
    fmri_createlegend(labels(:), color(1:numel(labels), :), 'Axes', axl, ...
                      'MaxLabelLength', 22, 'FontSize', 12);
    set(axl, 'Color', get(gcf, 'Color'), ...
             'XColor', 'none', 'YColor', 'none', 'Box', 'off');
end

end