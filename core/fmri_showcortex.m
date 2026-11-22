function fmri_showcortex(data, az, el, light, climits, crop, maskalpha, cmap, surfmaterial)
% FMRI_SHOWCORTEX  Cortical surface rendering of a statistical or continuous map.
%
% Renders a continuous-valued brain map projected onto a cortical surface
% mesh using colour-coded patches. More informative than fmri_show3d for
% continuous maps such as z-statistics or correlation values.
%
% Usage:
%   fmri_showcortex(data)
%   fmri_showcortex(data, az, el, light, climits, crop, maskalpha, cmap, surfmaterial)
%
% Inputs:
%   DATA      - Brain map, vectorized (228453 x 1). Continuous values.
%   AZ        - Azimuth angle in degrees. Default: 0.
%   EL        - Elevation angle in degrees. Default: 0.
%   LIGHT     - Light source positions (K x 2) matrix [az1 el1; az2 el2; ...].
%               Default: [45 0; -45 0].
%   CLIMITS   - Colour axis limits [min max]. Default: [] = [min max] of the data.
%
%   THRESHOLDING
%   The anatomical volume defines the rendered surface, while DATA provides
%   the values used to colour it. CLIMITS controls the colour scale: values
%   outside the range receive the end colours rather than being hidden. Use
%   CROP to remove anatomy from the rendering.
%
%   For signed maps, symmetric limits such as [-z z] place zero at the centre
%   of the default diverging colormap, with negative values in blue and
%   positive values in red.
%
%   CROP      - Restricts which part of the SURFACE is drawn. Either a
%               bounding box [xmin xmax ymin ymax zmin zmax], or a binary mask
%               (228453 x 1 vectorized, or 91 x 109 x 91). Default: full brain.
%
%               The mask is applied to the ANATOMY, not to DATA: zeroed voxels
%               are cut away from the rendered surface, exposing structures
%               behind them, while the data values themselves are never
%               altered. This is how cut-away and single-hemisphere views are
%               made.
%   MASKALPHA - Opacity of the brain shell. Default: 0.05. Raise it
%               slightly (e.g. 0.1) to keep a ghost of the whole brain around
%               a cut-away region.
%   CMAP      - (N x 3) custom colormap. Default: fmri_divmap(256).
%   SURFMATERIAL - Surface reflectance: 'metal' (default, strong speculars),
%               'dull' (matte, much less washed out), or 'shiny'. If a bright
%               colormap combined with near-overhead lighting looks bleached,
%               'dull' is usually the fix.
%
% Examples:
%   fmri_showcortex(z_map)
%   fmri_showcortex(r_map, 180, 10, [], [0.2 0.8])
%
%   % cut away one quadrant to look inside
%   load standard_brain (supplies br, the 91x109x91 binary brain mask)
%   m = br;  m(1:45, 45:109, 46:91) = 0;
%   fmri_showcortex(tmap, 49, 29, [], [-2.44 2.44], m)
%
%   % left hemisphere only
%   v = zeros(91,109,91);  v(1:45,:,:) = 1;
%   fmri_showcortex(z_map, 180, 10, [], [], fmri_vol2vect(v))
%
% See also: fmri_show3d, fmri_showslices, fmri_braincake, fmri_regionmask,
% fmri_colorbar

if ndims(data)<3, data = fmri_vect2vol(data); end
if size(data,4)>1, disp('Data contains several scans, showing 1st scan only.'); data = data(:,:,:,1); end

% --- PARAMETER HANDLING: defaults first, struct overrides last ------------
% Struct and positional arguments cannot be mixed
if nargin >= 2 && isstruct(az) && nargin > 2
    error('fmri_showcortex:structAndPositional', ...
        ['A parameter struct cannot be combined with positional arguments: ' ...
         'the struct\noverrides them, so the positional values would be ' ...
         'silently discarded.']);
end

% Positional defaults
if nargin < 2 || isempty(az),           az           = 0;             end
if nargin < 3 || isempty(el),           el           = 0;             end
if nargin < 4 || isempty(light),        light        = [45 0; -45 0]; end
if nargin < 5,                          climits      = [];            end
if nargin < 6 || isempty(crop),         crop         = [1 91 1 109 1 91]; end
if nargin < 7 || isempty(maskalpha),    maskalpha    = 0.05;          end
if nargin < 8,                          cmap         = [];            end
if nargin < 9 || isempty(surfmaterial), surfmaterial = 'metal';       end

% Struct overrides (if a struct was passed as the second argument)
if nargin >= 2 && isstruct(az)
    p = az;  az = 0;                    % Reset az so it doesn't remain a struct
    if isfield(p,'az'),           az           = p.az;           end
    if isfield(p,'el'),           el           = p.el;           end
    if isfield(p,'light'),        light        = p.light;        end
    if isfield(p,'climits'),      climits      = p.climits;      end
    if isfield(p,'crop'),         crop         = p.crop;         end
    if isfield(p,'maskalpha'),    maskalpha    = p.maskalpha;    end
    if isfield(p,'cmap'),         cmap         = p.cmap;         end
    if isfield(p,'surfmaterial'), surfmaterial = p.surfmaterial; end
end

% DEFAULT COLORMAP
if isempty(cmap)
    cmap = fmri_divmap(256);
end

load standard_brain_NZ % supplies A, the 91x109x91 template intensity image
A = A(91:-1:1,:,:);

if size(crop,1) == 1 && size(crop,2) == 6
    cropmask = zeros(91,109,91);
    cropmask(crop(1):crop(2), crop(3):crop(4), crop(5):crop(6)) = 1;
else
    cropmask = crop;
    if ndims(cropmask) < 3
        cropmask = fmri_vect2vol(cropmask);
    end
end
cropmask = cropmask(91:-1:1,:,:);
mask2 = double(A) .* cropmask;

data = data(end:-1:1,:,:);
lev = 5500;

% Auto colour limits when none were given: the full range of the data.
if isempty(climits)
    vals = data(isfinite(data) & data ~= 0);
    if isempty(vals)
        climits = [0 1];
    else
        climits = [min(vals) max(vals)];
    end
    if climits(1) == climits(2)
        climits = climits + [-0.5 0.5];
    end
end

% plot brain mask

% Check if there's any surface to render
if max(mask2(:)) < lev || sum(mask2(:) > 0) == 0
    % No surface in this crop - skip rendering
    warning('fmri_showcortex:emptyCrop', ...
        ['No brain surface remains after cropping: CROP excludes the whole ' ...
         'brain,\nso there is nothing to render. Check the bounding box or ' ...
         'mask passed as CROP.']);
    return
end

clf
hshell = patch(isosurface(A, lev));
daspect([1 1.1 1]);
isonormals(mask2, hshell);
set(hshell, 'facecolor', [0.5 0.5 0.5], 'edgecolor', 'none');
alpha(hshell, maskalpha);
axis vis3d;
axis off;
view(az, el);
axis manual; % freeze axis

% actual plotting starts here
% plot head surface
[faces, verts, colors] = isosurface(mask2, lev, data);
hsurf = patch('Vertices', verts, 'Faces', faces, ...
    'FaceVertexCData', colors, ...
    'FaceColor', 'interp', ...
    'edgecolor', 'interp');

isonormals(mask2, hsurf);
set(hsurf, 'edgecolor', 'none');
alpha(hsurf, 1);
for l = 1:size(light, 1)
    lightangle(az + light(l,1), light(l,2));
end

lighting phong;
material(surfmaterial);
axis off;
colormap(cmap);
if exist('clim', 'builtin') == 5
    clim(climits);
else
    caxis(climits);         %#ok<CAXIS>
end
view(az, el);
axis xy;
set(gcf, 'Color', 'w');