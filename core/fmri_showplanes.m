function fmri_showplanes(data, coord, climits, cbar, cmap, overlayalpha, bgcolor, crosshaircolor, threshold)
% FMRI_SHOWPLANES  Three-plane (sagittal/coronal/axial) slice view with crosshair.
%
% Displays sagittal, coronal and axial slices intersecting at a selected voxel.
% A crosshair marks the selected location in each view, and the three slices
% are combined in a single figure.
%
% Usage:
%   fmri_showplanes(data)
%   fmri_showplanes(data, coord)
%   fmri_showplanes(data, coord, climits)
%   fmri_showplanes(data, coord, climits, cbar, cmap, overlayalpha, bgcolor,
%                   crosshaircolor, threshold)
%   fmri_showplanes(data, p)   % p from fmri_makevizpar, coord from p.coord
%
% Inputs:
%   DATA      - Continuous brain map, vectorized (228453 x 1).
%   COORD     - Voxel subscripts [x y z] of the crosshair centre.
%               Convert from MNI: coord = fmri_mni2sub([x y z]).
%   CLIMITS   - Colour axis limits [min max]. CLIMITS(1) also acts as a
%               display threshold: voxels below it are not drawn.
%               Default: [] = the full range of the data.
%   CBAR      - Show colourbar (1) or not (0). Default: 1.
%   CMAP      - (N x 3) colormap matrix. Default: fmri_divmap(256).
%   OVERLAYALPHA - Opacity of the activation overlay on the grey brain
%               (0 = invisible, 1 = opaque). Default: 1.
%   BGCOLOR   - Figure background: 'k' (default) or 'w', or an RGB triple.
%               Everything outside the brain is zero and therefore renders
%               black; 'w' inverts the surround for print figures.
%   CROSSHAIRCOLOR - RGB of the crosshair lines. Default: [0 1 0] (green).
%   THRESHOLD - Controls which voxels are displayed. Default: [].
%                 > 0 : display voxels with |value| >= THRESHOLD, retaining
%                       effects of both signs. CLIMITS(1) must be lower than
%                       THRESHOLD; zero is usually appropriate.
%                 = 0 : display all finite voxels. Use NaN to hide voxels.
%                 []  : display voxels with value >= CLIMITS(1). This legacy
%                       rule is mainly suitable for one-sided maps.
% 
% Examples:
%   fmri_showplanes(z_map, fmri_mni2sub([20 -58 18]))
%   fmri_showplanes(r_map, [46 64 37], [0.2 0.8])
%   fmri_showplanes(data)              % peak voxel, all defaults
%   fmri_showplanes(data, coord)       % specified coord, all defaults
%   fmri_showplanes(data, p)           % peak voxel, struct params (coord from p.coord)
%
% See also: fmri_showslices, fmri_showselectslices, fmri_showcortex,
%           fmri_makevizpar, fmri_mni2sub

if ndims(data)>2; data=fmri_vol2vect(data); end
if size(data,2)>1 disp('Data contains several scans, showing 1st scan only.'); data=data(:,1); end

% --- PARAMETER HANDLING: defaults first, struct overrides last ------------
% Struct and positional arguments cannot be mixed
if nargin >= 2 && isstruct(coord) && nargin > 2
    error('fmri_showplanes:structAndPositional', ...
        'A parameter struct cannot be combined with positional arguments.');
end

% Positional defaults
if nargin < 2 || isempty(coord),         coord = []; end % [] -> peak voxel
if nargin < 3,                           climits = []; end
if nargin < 4 || isempty(cbar),          cbar = 1;    end
if nargin < 5,                           cmap = [];   end
if nargin < 6 || isempty(overlayalpha),  overlayalpha = 1;   end
if nargin < 7 || isempty(bgcolor),       bgcolor = 'k'; end
if nargin < 8 || isempty(crosshaircolor), crosshaircolor = [0 1 0]; end
if nargin < 9,                           threshold = []; end

% Struct overrides (if a struct was passed as the second argument)
if nargin >= 2 && isstruct(coord)
    p = coord;  coord = [];
    if isfield(p,'coord'),          coord          = p.coord;          end
    if isfield(p,'climits'),        climits        = p.climits;        end
    if isfield(p,'cbar'),           cbar           = p.cbar;           end
    if isfield(p,'cmap'),           cmap           = p.cmap;           end
    if isfield(p,'overlayalpha'),   overlayalpha        = p.overlayalpha;          end
    if isfield(p,'bgcolor'),        bgcolor        = p.bgcolor;        end
    if isfield(p,'crosshaircolor'), crosshaircolor = p.crosshaircolor; end
    if isfield(p,'threshold'),      threshold      = p.threshold;      end
end

% If coord is still empty, use the peak voxel
if isempty(coord), [~, coord] = max(data); end

% Validate coord
if length(coord)==1
    coord=fmri_ind2sub(coord);
end
if numel(coord)~=3
    error('fmri_showplanes:badCoord', ...
          'COORD must be [x y z] voxel subscripts or a single linear index.');
end
coord = round(coord(:)');

if any(coord < 1) || coord(1) > 91 || coord(2) > 109 || coord(3) > 91
    error('fmri_showplanes:coordOutOfBounds', ...
          ['COORD [%d %d %d] is outside the volume. Valid ranges are ' ...
           'x 1-91, y 1-109, z 1-91.\nTo convert from MNI use ' ...
           'fmri_mni2sub([x y z]).'], coord(1), coord(2), coord(3));
end

coord_mm = round(fmri_sub2mni(coord));

% If data is binary (only two unique values), scale slightly to avoid
% interpolation rounding errors
if length(unique(data))==2
    data=data*1.001; % some rounding error issue
end

% DEFAULT COLORMAP. 
if isempty(cmap)
    jetmap = fmri_divmap(256);
else
    jetmap = cmap;
end
colormap(jetmap)
ncolors = size(jetmap, 1);

% Auto colour limits when none were given: the full range of the data.
if isempty(climits)
    vals = data(isfinite(data) & data ~= 0);
    if isempty(vals), climits = [0 1]; else, climits = [min(vals) max(vals)]; end
    if climits(1) == climits(2), climits = climits + [-0.5 0.5]; end
end
data(data > climits(2)) = climits(2);
data(data < climits(1)) = climits(1);   % clip BOTH ends, not just the upper

% Decide which voxels are displayed
actmask = fmri_actmask(data, threshold, climits);

volactmask=fmri_vect2vol(actmask);
data(actmask)=floor((ncolors-1)*(data(actmask)-climits(1))/(climits(2)-climits(1)))+1;
datacol=zeros(size(data,1),3);
datacol(actmask,:)=jetmap(data(actmask),:);

volcol=fmri_vect2vol(datacol);

load graybrain % supplies gb, the greyscale anatomical background

% Background voxels: those where the template has no signal at all.
outside_brain = sum(gb, 4) == 0;

gb=gb.^3;

cl = crosshaircolor;   % crosshair line colour

ddd=zeros(91,109,91,3);
gbl=gb;

for k=1:3
    tmp=squeeze(gbl(:,:,:,k));
    tmpcol=volcol(:,:,:,k);
    tmp(volactmask>0)=overlayalpha*tmpcol((volactmask>0))+(1-overlayalpha)*tmp((volactmask>0));
    ddd(:,:,:,k) = tmp;
end

% Background fill
bgrgb = bg_to_rgb(bgcolor);
if any(bgrgb ~= 0)
    outside = outside_brain & ~(volactmask > 0);
    for k = 1:3
        ch = ddd(:,:,:,k);
        ch(outside) = bgrgb(k);
        ddd(:,:,:,k) = ch;
    end
end
for k=1:3
    ddd(coord(1),coord(2),6:86,k)=cl(k);
    ddd(6:86,coord(2),coord(3),k)=cl(k);
    ddd(coord(1),6:104,coord(3),k)=cl(k);
end

if cbar xsize=338; else xsize=309; end     

% Figure proportions, anchored on width
aspect = xsize/91;
pos = get(gcf,'Position');       pos(3) = 1000;  pos(4) = round(1000/aspect);
set(gcf,'Position',pos);
pos = get(gcf,'PaperPosition');  pos(3) = 8;     pos(4) = 8/aspect;
set(gcf,'PaperPosition',pos);

% Coordinate label size, scaled to the figure.
figpos  = get(gcf,'Position');
labelfs = max(8, min(24, round(figpos(4)/16)));

% Coordinate labels must contrast with whatever background was chosen.
bgrgb0 = bg_to_rgb(bgcolor);
if mean(bgrgb0) > 0.5
    labelcol = [0.05 0.05 0.05];      % dark text on a light background
else
    labelcol = [0.95 0.95 0.95];      % light text on a dark background
end

% sagittal view
[y,z]=meshgrid(linspace(1,109,325),linspace(1,91,271));
tmp=zeros(271,325,3);
subplot('position',[0 0 109/xsize 1])
tmp2=squeeze(ddd(coord(1),:,end:-1:1,:));
for k=1:3
    tmp(:,:,k)=interp2(squeeze(tmp2(:,:,k))',y,z);
end
image(tmp)
text(8,22,['x = ' num2str(coord_mm(1))],'color',labelcol,'fontsize',labelfs)
axis off

% coronal view
[x,z]=meshgrid(linspace(1,91,271),linspace(1,91,271));
subplot('position',[109/xsize 0 91/xsize 1]),
tmp2=(squeeze(ddd(:,coord(2),:,:)));
tmp3=zeros(271,271,3);
for k=1:3
    tmp3(:,:,k)=interp2(squeeze(tmp2(:,91:-1:1,k))',x,z);
end
image(tmp3)
text(8,22,['y = ' num2str(coord_mm(2))],'color',labelcol,'fontsize',labelfs)
axis off

% axial view
[x,y]=meshgrid(linspace(1,109,271),linspace(1,91,325));
subplot('position',[200/xsize 0 109/xsize 1]),
tmp4 = squeeze(ddd(:,:,coord(3),:));
tmp5=zeros(325,271,3);
for k=1:3
    tmp5(:,:,k)=interp2(squeeze(tmp4(:,:,k)),x,y);
end
image(tmp5)
text(8,22,['z = ' num2str(coord_mm(3))],'color',labelcol,'fontsize',labelfs)
axis off

% Background
set(gcf,'Color',bgcolor);

if cbar
   barx = 309/xsize + 0.005;
   h = colorbar('position',[barx .1 .02 .8]);
   l = get(h,'ylim');
   set(h,'ytick',[l(1) l(2)]);
   set(h,'yticklabel', {fmri_ticklabel(climits(1)), fmri_ticklabel(climits(2))}, ...
         'fontsize',12);
   set(h,'Color', labelcol);
end

% -------------------------------------------------------------------------
function rgb = bg_to_rgb(bg)
% Accepts 'k'/'w'/'r'... or an RGB triple, and returns an RGB triple.
if ischar(bg) || isstring(bg)
    switch lower(char(bg))
        case {'k','black'}, rgb = [0 0 0];
        case {'w','white'}, rgb = [1 1 1];
        case {'r','red'},   rgb = [1 0 0];
        case {'g','green'}, rgb = [0 1 0];
        case {'b','blue'},  rgb = [0 0 1];
        otherwise
            error('fmri_showplanes:badBgColor', ...
                  'BGCOLOR must be ''k'', ''w'', or an RGB triple.');
    end
else
    rgb = bg(:)';
    if numel(rgb) ~= 3 || any(rgb < 0) || any(rgb > 1)
        error('fmri_showplanes:badBgColor', ...
              'BGCOLOR as RGB must be three values in [0 1].');
    end
end