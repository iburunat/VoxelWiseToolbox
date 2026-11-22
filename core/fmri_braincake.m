function fmri_braincake(data, az, el, plane, slices, thickness, stackdir, maskalpha, climits, light, interslice, cmap, surfmaterial)
% FMRI_BRAINCAKE  3D layered-slice rendering of brain activation (brain cake).
%
% Renders the brain as a set of visible slabs separated in 3D space, with
% activation shown in colour on each slab face and a transparent brain shell
% surrounding them. Produces distinctive and informative figures for axial,
% sagittal, or coronal series.
%
% Usage:
%   fmri_braincake(data, az, el, plane, slices, thickness, stackdir, ...
%                  maskalpha, climits, light, interslice, cmap, surfmaterial)
%   fmri_braincake(data, p)        % p from fmri_makevizpar
%
% Inputs:
%   DATA        - Brain map, vectorized (228453 x N) or volume (91x109x91xN).
%   AZ          - Azimuth angle in degrees. Default: -90.
%   EL          - Elevation angle in degrees. Default: 10.
%   PLANE       - Slice orientation: 1=axial (default), 2=sagittal, 3=coronal.
%   SLICES      - Indices of visible slice positions (vector). E.g. [23 45 56].
%   THICKNESS   - Slab thickness: a scalar or one value per slice. Default: 3.
%                 Each slab extends away from the camera from its slice face.
%                 To tile adjacent slices, use [first diff(SLICES)] when viewed
%                 from the high side (axial EL >= 0, sagittal AZ < 90,
%                 coronal AZ >= 0), or [diff(SLICES) last] otherwise.
%                 Default: 3 for all slices.
%   STACKDIR    - Cake stacking: 1=vertical (default), 2=horizontal.
%   MASKALPHA   - Brain shell opacity (0=invisible, 1=opaque). Default: 0.
%   CLIMITS     - Colour axis limits [min max].
%   LIGHT       - Light source positions (K x 2) [az el; ...].
%                 Default: [45 80; -45 80].
%   INTERSLICE  - Gap between slabs, as a PERCENTAGE of slab size along the
%                 stacking direction (0 = slabs touch). Default: 2.
%   CMAP        - Colormap. Default: fmri_divmap(256).
%                   N x 3 matrix : used as given if it has at least 64 rows;
%                                  fewer rows are treated as anchor colours
%                                  and expanded with fmri_makecmap.
%                   scalar       : shorthand for a grey-yellow-red ramp
%                                  starting at that grey level, i.e.
%                                  [c c c; 1 1 0; 1 0 0].
%   SURFMATERIAL - Surface reflectance: 'metal' (default), 'dull', or 'shiny'.
%
% Examples:
%   fmri_braincake(z_map, -90, 90, 1, 20:5:70, 4)
%   fmri_braincake(r_map, 40, 20, 3, [30 50 70], 3, 1, 0.1, [0.2 0.8])
%
% See also: fmri_show3d, fmri_showcortex, fmri_showslices, fmri_colorbar

% --- PARAMETER HANDLING: defaults first, struct overrides last ------------
% Struct and positional arguments cannot be mixed
if nargin >= 2 && isstruct(az) && nargin > 2
    error('fmri_braincake:structAndPositional', ...
        ['A parameter struct cannot be combined with positional arguments: ' ...
         'the struct\noverrides them, so the positional values would be ' ...
         'silently discarded.']);
end

% Positional defaults
if nargin < 2  || isempty(az),           az           = -90;   end
if nargin < 3  || isempty(el),           el           = 10;    end
if nargin < 4  || isempty(plane),        plane        = 1;     end
if nargin < 5  || isempty(slices),       slices       = [20 40 55 60 70]; end
if nargin < 6,                           thickness    = [];    end
if nargin < 7  || isempty(stackdir),     stackdir     = 1;     end
if nargin < 8  || isempty(maskalpha),    maskalpha    = 0;     end
if nargin < 9,                           climits      = [];    end
if nargin < 10 || isempty(light),        light        = [45 80; -45 80]; end
if nargin < 11 || isempty(interslice),   interslice   = 2;     end
if nargin < 12,                          cmap         = [];    end
if nargin < 13 || isempty(surfmaterial), surfmaterial = 'metal'; end

% Struct overrides (if a struct was passed as the second argument)
if nargin >= 2 && isstruct(az)
    p = az;  az = -90;                   % Reset az so it doesn't remain a struct
    if isfield(p,'az'),           az           = p.az;           end
    if isfield(p,'el'),           el           = p.el;           end
    if isfield(p,'plane'),        plane        = p.plane;        end
    if isfield(p,'slices'),       slices       = p.slices;       end
    if isfield(p,'thickness'),    thickness    = p.thickness;    end
    if isfield(p,'stackdir'),     stackdir     = p.stackdir;     end
    if isfield(p,'maskalpha'),    maskalpha    = p.maskalpha;    end
    if isfield(p,'climits'),      climits      = p.climits;      end
    if isfield(p,'light'),        light        = p.light;        end
    if isfield(p,'interslice'),   interslice   = p.interslice;   end
    if isfield(p,'cmap'),         cmap         = p.cmap;         end
    if isfield(p,'surfmaterial'), surfmaterial = p.surfmaterial; end
end

% Convert input to volume (if needed)
if ndims(data) < 3
    data = fmri_vect2vol(data);
end

% DEFAULT COLORMAP: the toolbox diverging map, as used by the slice viewers.
if isempty(cmap)
    cmap = fmri_divmap(256);
end

% Auto-scale to the data range instead of an arbitrary [0 1], matching the
% slice functions. Values outside CLIMITS take the end colours.
if isempty(climits)
    vals = data(isfinite(data) & data ~= 0);
    if isempty(vals)
        climits = [0 1];
    else
        climits = [min(vals(:)) max(vals(:))];
    end
    if climits(1) == climits(2)
        climits = climits + [-0.5 0.5];
    end
end

slices = slices(:)';                      % accept row or column
if isempty(thickness)
    thickness = 3*ones(1, numel(slices));
elseif isscalar(thickness)
    thickness = thickness*ones(1, numel(slices));
end
if numel(thickness) ~= numel(slices)
    error('fmri_braincake:thicknessMismatch', ...
          'THICKNESS must be a scalar or have one entry per slice (%d given for %d slices).', ...
          numel(thickness), numel(slices));
end
if ~ismember(plane, [1 2 3])
    error('fmri_braincake:badPlane', 'PLANE must be 1 (axial), 2 (sagittal) or 3 (coronal).');
end

% set colormap
if isscalar(cmap)
    colorMap = [repmat(cmap,1,3); 1 1 0; 1 0 0];
else
    colorMap = cmap;
end

if size(colorMap, 1) < 64
    colorMap = fmri_makecmap(colorMap, [], 256);   % expand a few anchors
end

% Reorder THICKNESS with the same permutation.
[slices, sliceorder] = sort(slices, 'descend');
thickness = thickness(sliceorder);

% Slab images are rendered to disk, cropped, then concatenated. 
tmpdir = tempname;
mkdir(tmpdir);
cleanupTmp = onCleanup(@() rmdir(tmpdir, 's')); 
slicefile  = @(k) fullfile(tmpdir, sprintf('cakeSlice%d', k));
croppedfile= @(k) fullfile(tmpdir, sprintf('cakeSlice_cropped%d.tif', k));

% Render each slab into a PRIVATE figure of known size.
hcake = figure('Visible', 'off', 'Units', 'pixels', 'Position', [100 100 700 600]);
set(hcake, 'PaperPositionMode', 'auto');
cleanupFig = onCleanup(@() delete(hcake(ishghandle(hcake)))); 

% Determine which side of each slab faces the camera.
% Zero angles are treated as viewing the cut face, ensuring that
% az = 0 or el = 0 displays the activation.
front = (plane == 1 && el >= 0) || (plane == 2 && az < 90) || (plane == 3 && az >= 0);
for k=1:length(slices)
    figure(hcake);
    if plane == 1
        if front
            fmri_showcortex(data, az, el, light, climits, [1 91 1 109 max(1,slices(k)-thickness(k)) slices(k)], ...
                maskalpha, colorMap, surfmaterial);
        else
            fmri_showcortex(data, az, el, light, climits, [1 91 1 109 slices(k) min(91,slices(k)+thickness(k))], ...
                maskalpha, colorMap, surfmaterial)
        end
    elseif plane == 2
        if front
            fmri_showcortex(data, az, el, light, climits, [max(1,slices(k)-thickness(k)) slices(k) 1 109 1 91], ...
                maskalpha, colorMap, surfmaterial)
        else
            fmri_showcortex(data, az, el, light, climits, [slices(k) min(91,slices(k)+thickness(k)) 1 109 1 91], ...
                maskalpha, colorMap, surfmaterial)
        end
    elseif plane == 3
        if front
            fmri_showcortex(data, az, el, light, climits, [1 91 max(1,slices(k)-thickness(k)) slices(k) 1 91], ...
                maskalpha, colorMap, surfmaterial)
        else
            fmri_showcortex(data, az, el, light, climits, [1 91 slices(k) min(109,slices(k)+thickness(k)) 1 91], ...
                maskalpha, colorMap, surfmaterial)
        end
    end

    print('-dtiff','-r300', slicefile(k))
end

delete(hcake(ishghandle(hcake)));   % close the private slab figure

for k=1:length(slices)
    T=imread([slicefile(k) '.tif']);
    xsum=sum(sum(T,3));
    ysum=sum(sum(T,3),2);

    if stackdir == 1
        ytopedge=find(ysum<max(ysum),1,'first');
        ybottomedge=find(ysum<max(ysum),1,'last');
        if isempty(ytopedge), ytopedge=1; ybottomedge=length(ysum); end
        imwrite(T(ytopedge:ybottomedge,:,:), croppedfile(k), 'compression', 'none')
        
    else
        xleftedge=find(xsum<max(xsum),1,'first');
        xrightedge=find(xsum<max(xsum),1,'last');
        if isempty(xleftedge), xleftedge=1; xrightedge=length(xsum); end
        imwrite(T(:,xleftedge:xrightedge,:), croppedfile(k), 'compression', 'none')
    end
end

% read images from disk and concatenate
tmp = cell(1, length(slices));
for m=1:length(slices)
   tmp{m}=imread(croppedfile(m));
end

% Each slab is cropped independently, so they can differ by a pixel or two in
% the dimension being matched. Pad to the largest before concatenating.
if stackdir==1
    w = max(cellfun(@(x) size(x,2), tmp));
    for m=1:numel(tmp)
        d = w - size(tmp{m},2);
        if d>0
            pad = ones(size(tmp{m},1), d, size(tmp{m},3), 'like', tmp{m}) * 255;
            tmp{m} = [tmp{m} pad];
        end
    end
    gap = round(interslice/100 * mean(cellfun(@(x) size(x,1), tmp)));
    if gap > 0
        blank = ones(gap, w, size(tmp{1},3), 'like', tmp{1}) * 255;
        for m = 1:numel(tmp)-1, tmp{m} = [tmp{m}; blank]; end
    end
    img = vertcat(tmp{:});
else
    h = max(cellfun(@(x) size(x,1), tmp));
    for m=1:numel(tmp)
        d = h - size(tmp{m},1);
        if d>0
            pad = ones(d, size(tmp{m},2), size(tmp{m},3), 'like', tmp{m}) * 255;
            tmp{m} = [tmp{m}; pad];
        end
    end
    gap = round(interslice/100 * mean(cellfun(@(x) size(x,2), tmp)));
    if gap > 0
        blank = ones(h, gap, size(tmp{1},3), 'like', tmp{1}) * 255;
        for m = 1:numel(tmp)-1, tmp{m} = [tmp{m} blank]; end
    end
    img = horzcat(tmp{:});
end

% ---- ADD MARGINS ON ALL FOUR SIDES ----
margin_percent = 0.04;  % 4% margin on each side (adjust as needed)
padval = img(1,1,:);
margin_px = round(margin_percent * size(img,1));

% Add top and bottom margins
img = cat(1, ...
    repmat(padval, margin_px, size(img,2), 1), ...
    img, ...
    repmat(padval, margin_px, size(img,2), 1));

% Add left and right margins
img = cat(2, ...
    repmat(padval, size(img,1), margin_px, 1), ...
    img, ...
    repmat(padval, size(img,1), margin_px, 1));

% ---- DISPLAY FIGURE WITH CORRECT ASPECT ----
aspect = size(img,2) / size(img,1);
figure('Color','w');
pos = get(gcf,'Position');
if aspect >= 1
    pos(3) = min(1400, round(pos(4)*aspect));
    pos(4) = round(pos(3)/aspect);
else
    pos(4) = min(900, round(pos(3)/aspect));
    pos(3) = round(pos(4)*aspect);
end
set(gcf, 'Position', pos);
set(gcf, 'PaperUnits','points', 'PaperPosition', [0 0 size(img,2) size(img,1)]);

ax = axes('Position',[0 0 1 1]);
image(img, 'Parent', ax);
axis(ax, 'image');
axis(ax, 'off');