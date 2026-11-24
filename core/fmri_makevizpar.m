function p = fmri_makevizpar(varargin)
% FMRI_MAKEVIZPAR  Creates a visualization parameter structure with defaults.
%
% Returns a flat struct holding a default for every parameter used across the
% toolbox visualization functions. Each viewer reads only the fields it needs
% and ignores the rest, so one struct can drive several panels and guarantee
% they share their colour limits, colormap and threshold exactly.
%
% Usage:
%   p = fmri_makevizpar()
%   p = fmri_makevizpar('field', value, ...)
%
% Inputs:
%   Name-value pairs overriding any field below. An unrecognised name warns
%   and is ignored. An odd number of arguments is an error - note there is NO
%   leading function-name argument.
%
% Outputs:
%   Shared across viewers:
%
%   P.AZ           - Azimuth angle (degrees). Default: 40
%   P.EL           - Elevation angle (degrees). Default: 15
%   P.LABELS       - Legend labels, one per map, as a cell array of char.
%                    Default: {} (no legend). Used by fmri_show3d,
%                    fmri_showslices_int and fmri_showselectslices_int when
%                    DATA holds several maps as columns: one label per
%                    column, in the same order.
%   P.CLIMITS      - Colour axis limits [min max]. Default: [] (auto-scale)
%   P.THRESHOLD    - Display threshold, slice viewers. Default: [] (legacy rule)
%   P.CMAP         - N x 3 RGB colormap. Default: fmri_divmap(256)
%   P.COLOR        - N x 3 activation colours. Default: 6-colour set
%   P.MASKALPHA    - Brain shell opacity (0-1). Default: 0.08
%   P.LIGHT        - Light sources [az el; ...]. Default: [45 80; -45 80]
%   P.CBAR         - Show colourbar (0/1). Default: 1
%   P.OVERLAYALPHA - Overlay opacity, slice views. Default: 1
%   P.CROP         - Bounding box. Default: [1 91 1 109 1 91] (full brain)
%   P.GREYPAR      - Depth shading, 0=flat to 1=strong. Default: 0.4
%   P.TXT          - Show slice index on each tile (0/1). Default: 1
%   P.LEVEL        - Isosurface value (in data units, see fmri_show3d).
%                    Default: 0.1
%   P.SURFALPHA    - Activation surface opacity (0-1). Default: 1
%   P.PLANE        - 1=axial, 2=sagittal, 3=coronal. Default: 1. Not every
%                    viewer accepts all three. fmri_braincake implements all
%                    of them. fmri_showslices and fmri_showslices_int are
%                    axial and sagittal only and raise an error on 3. The
%                    fmri_showselectslices pair takes explicit slice indices,
%                    is axial only, and ignores this field. fmri_showplanes
%                    draws all three planes at once and reads P.COORD instead.
%   P.INTERVAL     - Voxel spacing between slices (1 or 2). Default: 2
%   P.SLICES       - Slice indices, e.g. [30 40 50]. Default: [20 30 40].
%   P.SURFMATERIAL - 'metal' (default), 'dull' or 'shiny'
%
%   THREE OPACITIES, AND WHICH IS WHICH
%   P.MASKALPHA      the transparent brain shell behind everything, 3D views
%   P.OVERLAYALPHA   the statistical overlay on a slice, 2D views
%   P.SURFALPHA      the activation isosurface itself, 3D views
%
%   They govern different objects and are not interchangeable. A viewer
%   reads only the ones that apply to it.
%
%
% fmri_show3d surface lighting:
%   P.SPECULAR_EXPONENT 0.25, P.SPECULAR_STRENGTH 0.75,
%   P.SPECULAR_REFLECTANCE 1, P.DIFFUSE_STRENGTH 0.75,
%   P.AMBIENT_STRENGTH 0.1, P.BACKFACE_LIGHTING 'reverselit'
%
% fmri_showplanes:
%   P.COORD          - Crosshair voxel [x y z]. Default: [45 63 36]
%   P.BGCOLOR        - Figure background RGB. Default: [0 0 0]
%   P.CROSSHAIRCOLOR - Crosshair RGB. Default: [0 1 0]
%
% fmri_braincake:
%   P.THICKNESS  - Slab thickness in voxels. Default: [] (3 per slice)
%   P.STACKDIR   - 1=vertical (default), 2=horizontal
%   P.INTERSLICE - Gap between slabs, % of slab size. Default: 2
%
% fmri_show3dhalfbrains:
%   P.MARGIN     - Inter-panel margin, % of panel size. Default: 10
%
% Examples:
%   % Set options once and pass the struct; the viewer reads every field it
%   % recognises, so nothing has to be re-typed in positional order.
%   p = fmri_makevizpar('az', 180, 'el', 10, 'maskalpha', 0.1);
%   fmri_show3d(data, p);
%
%   % Fields can also be set after construction:
%   p = fmri_makevizpar();
%   p.az = 180;  p.el = 10;  p.maskalpha = 0.1;
%   fmri_show3d(data, p);
%
%   % One struct, two viewers, guaranteed identical scaling:
%   p = fmri_makevizpar('climits', [-8 8], 'threshold', 4.14, ...
%                       'slices', [30 40 50]);
%   fmri_showslices(t_map, p);
%   fmri_showselectslices(t_map, p);
%
%   % The positional form remains available and is unaffected:
%   fmri_show3d(data, 180, 10, 0.9, 1, [1 0 0], 0.1);
%
% See also: fmri_show3d, fmri_showcortex, fmri_braincake, fmri_showslices,
%           fmri_showselectslices, fmri_showplanes, fmri_show3dhalfbrains


% =========================================================================
% SHARED FIELDS (used by multiple functions)
% =========================================================================
p.az            = 40;          % Azimuth angle (degrees) — show3d, showcortex, braincake
p.el            = 15;          % Elevation angle (degrees) — show3d, showcortex, braincake
p.labels        = {};          % Legend labels, one per map — show3d
p.climits       = [];          % Colour limits [min max] — auto-scale from the data at plot time
p.threshold     = [];          % Display threshold — slice viewers
p.cmap          = fmri_divmap(256);   % N x 3 colormap — slice viewers, showcortex, braincake
p.color         = [1 0 0; 0 1 0; 0 0 1; 1 1 0; 1 0 1; 0 1 1]; % N x 3 activation colours
p.maskalpha     = 0.08;        % Brain shell opacity (0-1) — show3d, showcortex, braincake
p.light         = [45 80; -45 80]; % Light source matrix — show3d, showcortex
p.cbar          = 1;           % Show colourbar: 1=yes, 0=no — slice viewers
p.overlayalpha  = 1;           % Overlay opacity (slice views) — showslices, showselectslices, showplanes
p.crop          = [1 91 1 109 1 91]; % Bounding box [xmin xmax ymin ymax zmin zmax] — show3d, showcortex
p.greypar       = 0.4;         % Depth shading strength (0=flat, 1=strong) — show3d
p.txt           = 1;           % Show slice index (0/1)
p.level         = 0.1;         % Isosurface value, in data units (see fmri_show3d)
p.surfalpha     = 1;           % Surface opacity (0-1)
p.plane         = 1;           % Slice orientation: 1=axial, 2=sagittal, 3=coronal
p.interval      = 2;           % Voxel spacing between displayed slices (1 or 2)
p.slices        = [20 30 40];  % Vector of slice indices (e.g. [20 30 40 50])
                               % Must be set by the user; no sensible default.
p.surfmaterial  = 'metal';     % Surface finish: 'metal', 'dull', 'shiny' — show3d, showcortex, braincake

% =========================================================================
% FMRI_SHOW3D — 3D isosurface rendering
% =========================================================================
% fmri_show3d(data, p)
%   reads: az, el, level, surfalpha, color, maskalpha, crop, greypar,
%          specular_exponent, specular_strength, specular_reflectance,
%          diffuse_strength, ambient_strength, backface_lighting, light
p.specular_exponent     = 0.25;
p.specular_strength     = 0.75;
p.specular_reflectance  = 1;
p.diffuse_strength      = 0.75;
p.ambient_strength      = 0.1;
p.backface_lighting     = 'reverselit';

% =========================================================================
% FMRI_SHOWCORTEX — Cortical surface rendering
% =========================================================================
% fmri_showcortex(data, p)
%   reads: az, el, light, climits, crop, maskalpha, cmap, surfmaterial
%
% P.THRESHOLD and P.OVERLAYALPHA are not used by fmri_showcortex. CLIMITS
% controls the value-to-colour mapping, CROP limits the displayed anatomy,
% and MASKALPHA controls the opacity of the anatomical shell.
%
% These shared defaults differ from the positional defaults of
% fmri_showcortex. See that function's help for viewer-specific guidance on
% lighting, surface material and colormap selection.
% 
% =========================================================================
% FMRI_SHOWPLANES — Three-plane orthogonal view
% =========================================================================
% fmri_showplanes(data, p)
%   reads: coord, climits, cbar, cmap, overlayalpha, bgcolor, crosshaircolor, threshold
p.coord          = [45 63 36];  % Crosshair voxel [x y z] (grid centre)
p.bgcolor        = [0 0 0];     % Figure background [R G B]
p.crosshaircolor = [0 1 0];     % Crosshair colour (green against grey)

% =========================================================================
% FMRI_BRAINCAKE — 3D layered-slice rendering
% =========================================================================
% fmri_braincake(data, p)
%   reads: az, el, plane, slices, thickness, stackdir, maskalpha, climits, light, interslice, cmap, surfmaterial
p.thickness  = [];              % Slab thickness in voxels
p.stackdir   = 1;               % Cake stacking: 1=vertical, 2=horizontal
p.interslice = 2;                      % Gap between slabs (as percentage of slab size)

% =========================================================================
% FMRI_SHOW3DHALFBRAINS — Four-panel hemisphere views
% =========================================================================
% fmri_show3dhalfbrains(data, p)
%   reads: level, surfalpha, color, maskalpha, margin
p.margin     = 10;       % Inter-panel margin

% =========================================================================
% APPLY USER OVERRIDES
% =========================================================================
if mod(length(varargin), 2) ~= 0
    error('fmri_makevizpar:badArgs', 'Arguments must be name-value pairs.');
end


for k = 1:2:length(varargin)
    field = lower(varargin{k});
    if isfield(p, field)
        p.(field) = varargin{k+1};
    else
        warning('fmri_makevizpar:unknownField', 'Unknown parameter: %s', field);
    end
end
end