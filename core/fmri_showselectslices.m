function fmri_showselectslices(data, slices, climits, txt, overlayalpha, cbar, cmap, threshold)
% FMRI_SHOWSELECTSLICES  Displays continuous data on a user-specified set of slices.
%
% Displays a continuous brain map on selected axial slices, allowing specific
% anatomical levels to be shown instead of a regularly spaced mosaic.
% 
% Usage:
%   fmri_showselectslices(data, slices)
%   fmri_showselectslices(data, slices, climits)
%   fmri_showselectslices(data, slices, climits, txt, overlayalpha, cbar, cmap, threshold)
%   fmri_showselectslices(data, p)   % p from fmri_makevizpar, slices in p.slices
%
% Inputs:
%   DATA    - Continuous brain map, vectorized (228453 x 1).
%   SLICES  - Vector of axial slice indices to display (e.g. [20 35 50 65]).
%   CLIMITS - Colour limits [lo hi]. CLIMITS(1) also acts as a display
%             threshold: voxels below it are not drawn. Default: [] = the
%             full range of the data, [min max]. For a SIGNED statistical
%             map shown with the default diverging colormap, pass symmetric
%             limits so that neutral grey sits at zero:
%             m = max(abs(data));  ... , [-m m], ...
%   TXT    - Show slice labels: 1 = yes, 0 = no. Default: 1. Labels give the
%            slice position in MNI millimetres, matching the coordinates
%            reported by fmri_regiontable, not the 1-91 voxel index passed
%            in SLICES.
%   OVERLAYALPHA - Overlay opacity (0-1). Default: 1.
%   CBAR    - Show colourbar: 1=yes, 0=no. Default: 1.
%   CMAP    - Colormap, in any of three forms. Default: [] = the toolbox
%             diverging blue-white-red map, fmri_divmap(256), shared with
%             the other display functions so that panels agree.
%                  N x 3 matrix : used as given if it has enough rows, and
%                                 interpolated up from N anchor colours if
%                                 not, so [0 0 1; 1 1 1; 1 0 0] is a valid
%                                 three-colour diverging map.
%                  char/string  : the name of any MATLAB colormap function
%                                 ('hot', 'parula', 'turbo').
%                  []           : the shared default above.
%                For a signed map, pass a diverging map and symmetric CLIMITS
%                so that the neutral colour sits at zero.
%   THRESHOLD  - Controls which voxels are displayed. Default: [].
%                  > 0 : display voxels with |value| >= THRESHOLD, retaining
%                        effects of both signs. CLIMITS(1) must be lower than
%                        THRESHOLD; zero is usually appropriate.
%                  = 0 : display all finite voxels. Use NaN to hide voxels.
%                  []  : display voxels with value >= CLIMITS(1). This legacy
%                        rule is mainly suitable for one-sided maps.
%
%   Alternatively, pass a parameter struct P from fmri_makevizpar as the second
%   argument. Fields used: slices, climits, txt, overlayalpha, cbar, cmap, threshold.
%
% Examples:
%   fmri_showselectslices(z_map, [20 35 50 65])
%   fmri_showselectslices(r_map, [30 45 60], [0.2 0.7])
%
% See also: fmri_showslices, fmri_showselectslices_int, fmri_showplanes

VERT_PRINT_SIZE = 4;

% ---- Accept a fmri_makevizpar struct as the second argument -------------
if ndims(data)>2, data = fmri_vol2vect(data); end

% --- PARAMETER HANDLING: defaults first, struct overrides last ------------
% Struct and positional arguments cannot be mixed
if nargin >= 2 && isstruct(slices) && nargin > 2
    error('fmri_showselectslices:structAndPositional', ...
        'A parameter struct cannot be combined with positional arguments.');
end

% Positional defaults
if nargin < 3,                    climits   = []; end
if nargin < 4 || isempty(txt),    txt       = 1;  end
if nargin < 5 || isempty(overlayalpha),  overlayalpha     = 1;  end
if nargin < 6 || isempty(cbar),   cbar      = 1;  end
if nargin < 7,                    cmap      = []; end
if nargin < 8,                    threshold = []; end

% Struct overrides (if a struct was passed as the second argument)
if nargin >= 2 && isstruct(slices)
    p = slices;  slices = [];
    if isfield(p,'slices'),    slices    = p.slices;    end
    if isfield(p,'climits'),   climits   = p.climits;   end
    if isfield(p,'txt'),       txt       = p.txt;       end
    if isfield(p,'overlayalpha'),     overlayalpha     = p.overlayalpha;     end
    if isfield(p,'cbar'),      cbar      = p.cbar;      end
    if isfield(p,'cmap'),      cmap      = p.cmap;      end
    if isfield(p,'threshold'), threshold = p.threshold; end
end


% VALIDATE slices
if isempty(slices) || ~isvector(slices) || any(~isfinite(slices)) || any(slices < 1) || any(slices > 91)
    error('fmri_showselectslices:badSlices', ...
        ['SLICES must be a vector of valid axial slice indices (1-91).\n' ...
            'Got %s. Use fmri_juicyslices to choose slices automatically.'], ...
        mat2str(slices));
end

if size(data,2)>1, disp('Data contains several scans, showing 1st scan only.'); data=data(:,1); end

% Auto-scale the colour limits when none were given
% For a signed statistical map, use symmetric limits so that zero is centred
% in the default diverging colormap:
%
%     m = max(abs(data));
%     fmri_showselectslices(data, slices, [-m m])
if isempty(climits)
    finite_vals = data(isfinite(data) & data ~= 0);
    if isempty(finite_vals)
        climits = [0 1];
    else
        climits = [min(finite_vals) max(finite_vals)];
    end
    if climits(1) == climits(2), climits = climits + [-0.5 0.5]; end
end

N=length(slices);
% ---- slice labels in MNI millimetres ------------------------------------
% Convert the selected axial slice indices to MNI z-coordinates for display.
% The x and y values are fixed placeholders because only z varies.
z_mm = fmri_sub2mni([repmat([46 64], N, 1), slices(:)]);
z_mm = round(z_mm(:, 3));

[x,y]=meshgrid(linspace(1,109,325),linspace(1,91,271));

% COLORMAP. Default is now the diverging blue-grey-red map.
if isempty(cmap)
    resolved_cmap = fmri_divmap(256);
elseif ischar(cmap) || isstring(cmap)
    resolved_cmap = feval(char(cmap), 256);
elseif isnumeric(cmap) && size(cmap,2) == 3
    if size(cmap,1) >= 64
        resolved_cmap = cmap;                           % already fine-grained, keep it
    else
        resolved_cmap = fmri_makecmap(cmap, [], 256);   % expand a few anchor colours
    end
else
    error('fmri_showselectslices:badCmap', ...
          'CMAP must be [], an N x 3 matrix, or a colormap name.');
end

colormap(resolved_cmap)

data(data > climits(2)) = climits(2);
data(data < climits(1)) = climits(1);   

% Decide which voxels are displayed
actmask = fmri_actmask(data, threshold, climits);
volactmask=fmri_vect2vol(actmask);

nCol = size(resolved_cmap, 1);
data(actmask) = floor((nCol-1)*(data(actmask)-climits(1))/(climits(2)-climits(1))) + 1;
data(actmask) = min(max(data(actmask), 1), nCol);   % guard the endpoints
datacol=zeros(size(data,1),3);
datacol(actmask,:)=resolved_cmap(data(actmask),:);

volcol=fmri_vect2vol(datacol);

% set figure dimensions
clf
if ~cbar, spwidth = (N*271+390); else spwidth=1.15*(N*271+390); end

% ---- preserve figure proportions ----------------------------------------
% Set the figure aspect ratio from the combined width of the selected slices,
% orientation panel and optional colourbar, keeping the layout undistorted.
layout_aspect = spwidth / 325;

pos = get(gcf,'Position');
pos(3) = 1000;                       % width in pixels; height follows
pos(4) = round(pos(3) / layout_aspect);
set(gcf,'Position',pos);

pos = get(gcf,'PaperPosition');
pos(4) = VERT_PRINT_SIZE;
pos(3) = pos(4) * layout_aspect;
set(gcf,'PaperPosition',pos);

load graybrain % supplies gb, the greyscale anatomical background
gb=gb.^3;
ddd=zeros(91,109,91,3);

gbl=gb;
for k=1:3
    tmp=squeeze(gbl(:,:,:,k));
    tmpcol=volcol(:,:,:,k);
    tmp(volactmask>0)=overlayalpha*tmpcol((volactmask>0))+(1-overlayalpha)*tmp((volactmask>0));
    ddd(:,:,:,k) = tmp;
end

% plot horizontal slices
for k=1:N
    subplot('position',[390/spwidth+271*(k-1)/spwidth 0 271/spwidth 1])
    tmp2=squeeze(ddd(:,end:-1:1,slices(k),:));

    for m=1:3
        tmp3(:,:,m)=interp2(tmp2(:,:,m),x,y);
    end
    for m=1:3
        sl(:,:,m)=tmp3(:,:,m)';
    end
    image(sl);axis off
    if txt
    % 18 pt: these mosaics are reproduced about 25 mm tall in a journal
    % column, where a 12 pt label prints at roughly 5 pt. 
        text(100, 290, sprintf('z = %d', z_mm(k)), 'color', 'w', 'fontsize', 12, 'VerticalAlignment', 'top')
    end
        
end

% plot vertical slice with lines indicating the locations of horizontal slices
subplot('position',[271*0/spwidth 0 390/spwidth 1])
tmp2=squeeze(gb(45,:,end:-1:1,:));

for m=1:3
    tmp5(:,:,m)=interp2(tmp2(:,:,m),y',x');
end
tmp=zeros(271,325,3);
for k=1:3
    tmp(:,:,k)=squeeze(tmp5(:,:,k)');
end
col=[.5 1 .5];
tmp(271-3*slices+3,:,1)=col(1);
tmp(271-3*slices+3,:,2)=col(2);
tmp(271-3*slices+3,:,3)=col(3);

tmp=max(tmp,0); tmp=min(tmp,1);
image(tmp),axis off

if cbar
    h = colorbar('position', [.90 .1 .018 .8]);
    l = get(h, 'ylim');
    set(h, 'ytick', [l(1) l(2)]);
    set(h, 'yticklabel', {fmri_ticklabel(climits(1)), ...
                          fmri_ticklabel(climits(2))}, 'fontsize', 16);
end