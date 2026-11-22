function fmri_show3d(data, az, el, level, surfalpha, color, maskalpha, crop, greypar, labels)
% FMRI_SHOW3D  3D isosurface rendering of brain activation.
%
% Displays one or more brain maps as coloured 3D surfaces within a transparent
% brain shell. Useful for visualising activations, networks and regions of
% interest.
%
% Usage:
%   fmri_show3d(data)
%   fmri_show3d(data, az, el, level, surfalpha, color, maskalpha, crop, greypar)
%   fmri_show3d(data, [], [], [], [], [], [], [], [], labels)  % with labels
%
% Inputs:
%   DATA      - fMRI data, vectorized (228453 x N) or volume (91x109x91xN).
%               Binary masks or continuous maps, one per column. Each column is
%               drawn as a single surface in one colour; magnitude is not
%               colour-coded. For that, see FMRI_BRAINCAKE or FMRI_SHOWSLICES.
%               A label map (atlas or cluster indices) is drawn as one surface
%               covering all labels, provided LEVEL is below 1; pass one column
%               per label to colour them separately, as in the example below.
%   AZ        - Azimuth angle for view in degrees. Default: 0.
%   EL        - Elevation angle for view in degrees. Default: 0.
%   LEVEL     - Value at which the surface is drawn, in the units of DATA.
%               One scalar, applied to all maps. For a continuous map, your
%               statistical threshold (e.g. 3.5); for a binary mask, a value in
%               (0,1). Default: 0.1.
%               On a mask, LEVEL also sets how much the surfaces are enlarged.
%               0.5 draws them at their true size but renders a single voxel at
%               a sixth of its volume, which makes cluster edges look eroded.
%               The default of 0.1 draws a single voxel at nearly full size and
%               a large cluster about a third over. Use 0.5 when extents are
%               being compared, 0.1 when the figure should read cleanly.
%   SURFALPHA - Opacity of activation surface (0=transparent, 1=opaque). Default: 1.
%   COLOR     - (N x 3) RGB matrix: one colour per data column.
%               Default: [1 0 0; 0 1 0; 0 0 1; 1 1 0; 1 0 1; 0 1 1].
%   MASKALPHA - Opacity of the background brain shell. Default: 0.10.
%   CROP      - Bounding box [xmin xmax ymin ymax zmin zmax] to restrict
%               rendering to a sub-volume, or a mask vector. Default: full brain.
%   GREYPAR   - Depth-shading strength for the activation surfaces, 0-1.
%               Higher values give stronger front-to-back shading. Default: 0.4.
%   LABELS    - Cell array of strings (N x 1) with one label per map.
%               If provided, displays a legend with these labels. Default: [].
%
% Examples:
%   % a binary region or network mask
%   fmri_show3d(net1, 180, 10, 0.5, 0.8, [1 0 0], 0.1)
%
%   % a t map, thresholded at t = 3.5 by LEVEL
%   fmri_show3d(t_map, 40, 15, 3.5)
%
%   % positive and negative clusters of the same t map, in two colours
%   fmri_show3d([t_map -t_map], 40, 15, 3.5, 1, [1 0 0; 0 0 1])
%
%   % three networks with a legend
%   fmri_show3d([net1 net2 net3], 40, 15, 0.5, 1, [1 0 0; 0 1 0; 0 0 1], ...
%               [], [], [], {'Auditory','Motor','Default'})
%
% Notes:
%   Isosurface rendering under-draws anything one voxel thick: at LEVEL 0.5 an
%   isolated voxel is drawn at about a sixth of its size. The default LEVEL of
%   0.1 compensates by enlarging every surface instead. Use the slice viewers
%   when extents matter.
%
% See also: fmri_show3dba, fmri_showcortex, fmri_showslices,
% fmri_braincake, fmri_colorbar

if ndims(data)<3, data = fmri_vect2vol(data); end

% Accept fmri_makevizpar struct as second argument
if nargin >= 2 && isstruct(az) && nargin > 2
    error('fmri_show3d:structAndPositional', ...
        ['A parameter struct cannot be combined with positional arguments: ' ...
         'the struct\noverrides them, so the positional values would be ' ...
         'silently discarded.']);
end

% ---- PARAMETER DEFAULTS ----
if nargin < 2 || isempty(az),        az        = 0;    end
if nargin < 3 || isempty(el),        el        = 0;    end
if nargin < 4 || isempty(level),     level     = 0.1;  end
if nargin < 5 || isempty(surfalpha), surfalpha  = 1;    end
if nargin < 6 || isempty(color),     color     = [1 0 0;0 1 0;0 0 1;1 1 0;1 0 1;0 1 1;0 0 0;1 1 1]; end
if nargin < 7 || isempty(maskalpha), maskalpha = 0.10; end
if nargin < 8 || isempty(crop),      crop      = [1 91 1 109 1 91]; end
if nargin < 9 || isempty(greypar),   greypar   = 0.4;  end
if nargin < 10 || isempty(labels),   labels    = {};   end

lightpar = struct('se', 0.25, 'ss', 0.75, 'sr', 1, ...
                  'ds', 0.75, 'as', 0.1,  'bf', 'reverselit');

% Struct override (if a struct was passed as the second argument)
if nargin >= 2 && isstruct(az)
    p = az;  az = 0;
    if isfield(p,'az'),        az        = p.az;        end
    if isfield(p,'el'),        el        = p.el;        end
    if isfield(p,'level') && ~isempty(p.level), level = p.level; end
    if isfield(p,'surfalpha'), surfalpha = p.surfalpha;  end
    if isfield(p,'color'),     color     = p.color;     end
    if isfield(p,'maskalpha'), maskalpha = p.maskalpha; end
    if isfield(p,'crop'),      crop      = p.crop;      end
    if isfield(p,'greypar'),   greypar   = p.greypar;   end
    if isfield(p,'labels'),    labels    = p.labels;    end
    if isfield(p,'specular_exponent'),    lightpar.se = p.specular_exponent;    end
    if isfield(p,'specular_strength'),    lightpar.ss = p.specular_strength;    end
    if isfield(p,'specular_reflectance'), lightpar.sr = p.specular_reflectance; end
    if isfield(p,'diffuse_strength'),     lightpar.ds = p.diffuse_strength;     end
    if isfield(p,'ambient_strength'),     lightpar.as = p.ambient_strength;     end
    if isfield(p,'backface_lighting'),    lightpar.bf = p.backface_lighting;    end
end

% ---- CHECK MAP COUNT ----
nMaps = size(data,4);

% Validate labels
if ~isempty(labels)
    if ~iscell(labels)
        error('fmri_show3d:labelsNotCell', 'LABELS must be a cell array of strings.');
    end
    if numel(labels) ~= nMaps
        error('fmri_show3d:labelCountMismatch', ...
            ['Number of labels (%d) does not match number of maps (%d).'], ...
            numel(labels), nMaps);
    end
    % Convert to column cell array if needed
    if size(labels,1) == 1
        labels = labels';
    end
end

% Validate surfalpha
if isscalar(surfalpha)
    surfalpha = repmat(surfalpha, nMaps, 1);
elseif numel(surfalpha) ~= nMaps
    error('fmri_show3d:surfalphaLengthMismatch', ...
          ['SURFALPHA must be a scalar or have one value per map ' ...
           '(%d given for %d maps).'], numel(surfalpha), nMaps);
end

% Expand a single RGB colour to all maps; otherwise require an N x 3 matrix.
if isvector(color) && numel(color) == 3
    color = repmat(color(:)', nMaps, 1);
elseif size(color, 2) ~= 3
    error('fmri_show3d:badColor', ...
        'COLOR must be an N x 3 RGB matrix; got %d x %d.', ...
        size(color,1), size(color,2));
end

% ---- CHECK COLOR COUNT ----
if size(color, 1) < nMaps
    warning('fmri_show3d:tooFewColors', ...
        ['Only %d colors provided for %d maps.\n' ...
         'Generating %d distinct colors using fmri_distinctcolors.\n' ...
         'To control colors manually, provide a color matrix with at least %d rows.\n' ...
         'Example: colors = fmri_distinctcolors(%d); fmri_show3d(data, [], [], [], [], colors);'], ...
        size(color, 1), nMaps, nMaps, nMaps, nMaps);

    color = fmri_distinctcolors(nMaps);
end

% ---- LOAD BRAIN TEMPLATE ----
load standard_brain_NZ % supplies A, the 91x109x91 template image (int16, 0-8339)

% ---- APPLY CROP ----
% Keep template intensities for the shell, but use only its binary support to
% mask DATA.
if length(crop)==6
    cropmask=zeros(91,109,91);
    cropmask(crop(1):crop(2),crop(3):crop(4),crop(5):crop(6)) = 1;
    mask2=double(A).*cropmask;
else
    mask2=double(A).*fmri_vect2vol(crop);
end

data = data .* (mask2 > 0);   % implicit expansion over the 4th dimension

% A label map - atlas regions, cluster indices - carries several distinct
% positive values, none of which is a threshold, so LEVEL cannot mean the same
% thing for a label of 1 and a label of 8. When LEVEL is below 1 it cannot be
% a threshold on integer data either, so reduce such a map to its support and
% draw the union. To colour the labels separately, pass one column per label.
if level < 1
    for k = 1:size(data,4)
        dk = data(:,:,:,k);
        u  = unique(dk(dk ~= 0));
        if numel(u) > 1 && all(u > 0) && all(u == round(u))
            data(:,:,:,k) = dk > 0;
        end
    end
end

data=data(end:-1:1,:,:,:);
mask2=mask2(end:-1:1,:,:);

% ---- PLOT TRANSPARENT HEAD SURFACE TO INITIALIZE AXES ----
clf
hshell=patch(isosurface(A,5500));
isonormals(A,hshell)
set(hshell,'facecolor',[.5 .5 .5],'edgecolor','none');
daspect([1 1.1 1]);
alpha(hshell,0) % transparent
axis vis3d
axis off
view(0,0);
axis manual % freeze axis

% ---- PLOT BRAIN SURFACE ----
lev=5500;
hbrain=patch(isosurface(mask2,lev));
isonormals(mask2,hbrain)
set(hbrain,'facecolor',[.5 .5 .5],'edgecolor','none');
set(hbrain,'SpecularExponent',        lightpar.se);
set(hbrain,'SpecularStrength',        lightpar.ss);
set(hbrain,'SpecularColorReflectance',lightpar.sr);
set(hbrain,'DiffuseStrength',         lightpar.ds);
set(hbrain,'AmbientStrength',         lightpar.as);
set(hbrain,'BackFaceLighting',        lightpar.bf);
alpha(hbrain,maskalpha)
axis off

% ---- PLOT ACTIVATIONS ----
hold on
for m=1:nMaps
    q=patch(isosurface(data(:,:,:,m),level));
    qx=get(q,'XData'); qx=qx-46;
    qy=get(q,'YData'); qy=qy-55;
    qz=get(q,'ZData'); qz=qz-46;
    if size(qx,1)>0
        qq=[qx(1,:)' qy(1,:)' qz(1,:)'];

        s1 = sin(pi*el/180);
        c1 = cos(pi*el/180);
        s3 = sin(pi*az/180);
        c3 = cos(pi*az/180);

        R1 = [1 0 0; 0 c1 s1; 0 -s1 c1];
        R3 = [c3 -s3 0; s3 c3 0; 0 0 1];

        qqq=qq*R3*R1;
        w=-qqq(:,2);
        w=w/30;
        w=greypar*w+(1-greypar);
        w=max(w,-1);w=min(w,1);
        w=repmat(w,1,3);
        cm1=repmat(color(m,:),size(w,1),1);
        cm2=repmat([1 1 1],size(w,1),1);
        colmat=w.^2.*cm1 + (1-w.^2).*cm2;
        set(q,'FaceVertexCData',colmat, 'FaceColor','flat');
        isonormals(data(:,:,:,m),q)
        set(q,'edgecolor','none');
        alpha(q,surfalpha(m));
    end
end
set(gcf,'Color','w');
hold off

camlight(az+45,el+30);
lighting phong;
view(az,el);

set(gcf,'paperunits','inches')
set(gcf, 'PaperPosition',[0 0 12 8])
set(gca, 'position', [0.1 0.1 0.8 0.8])
set(gca, 'CameraViewAngle', 7.19636)


% ---- DRAW LEGEND IF LABELS PROVIDED ----
if ~isempty(labels)
    draw_legend(labels, color(1:nMaps,:));
end

end

% -------------------------------------------------------------------------
function draw_legend(labels, colors)
% Draws a legend with labels and colour swatches in a panel to the right.
%
% LABELS - Cell array of strings (N x 1)
% COLORS - N x 3 RGB matrix

n = numel(labels);
if n == 0, return; end

% Reserve width in proportion to the longest label, so a two-entry key does
% not leave a quarter of the figure empty. The brain is unaffected: it keeps
% 0.8 of the original width whatever f is, because the figure widens by 1/f.
maxlen = max(cellfun(@numel, labels));
panelw = min(0.32, max(0.12, 0.012 * min(maxlen, 25) + 0.05));
f      = 1 - panelw;                        % share of the new width kept for the brain

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

% Determine layout
perCol = 20;                               % entries per column
nCol   = ceil(n / perCol);
nRow   = min(n, perCol);

% Calculate legend dimensions
legend_height = 0.05 + (nRow / 20) * 0.85;
legend_y = 0.05 + (0.90 - legend_height) / 2;

% Create legend axes
axl = axes('Position', [0.9*f + 0.02, legend_y, 0.96 - 0.9*f, legend_height]);
hold(axl, 'on');
set(axl, 'XLim', [-0.1 nCol+0.1], 'YLim', [-0.1 nRow+0.1], ...
         'YDir', 'reverse', 'XTick', [], 'YTick', [], ...
         'Color', get(gcf, 'Color'), 'XColor', 'none', 'YColor', 'none', 'Box', 'off');

% Adjust font size based on number of entries
fs = 10;
if nRow > 15, fs = 9; end
if nRow > 25, fs = 8; end
if nRow > 35, fs = 7; end

% Truncate long labels
maxLabelLen = 25;
for k = 1:n
    label = labels{k};
    if length(label) > maxLabelLen
        label = [label(1:maxLabelLen-3) '...'];
    end

    col = floor((k-1) / perCol);
    row = mod(k-1, perCol) + 0.5;

    % Colour swatch
    patch(axl, col + [0.02 0.20 0.20 0.02], row + [-0.32 -0.32 0.32 0.32], ...
          colors(k,:), 'EdgeColor', 'none');

    % Label text
    text(axl, col + 0.28, row, label, ...
         'FontSize', fs, 'VerticalAlignment', 'middle', 'Color', 'k', ...
         'Interpreter', 'none');
end

hold(axl, 'off');
axes(ax3d);  % Return focus to 3D axes
end