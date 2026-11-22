function fmri_showslices(data, plane, interval, climits, txt, overlayalpha, cbar, cmap, threshold)
% FMRI_SHOWSLICES  Displays continuous brain data as a series of 2D slices.
%
% Renders a continuous-valued brain map as a mosaic of axial or sagittal
% slices overlaid on the greyscale brain template. Each slice is
% equally spaced by INTERVAL voxels. Suitable for statistical maps, correlation
% maps, tSNR maps, etc.
%
% Usage:
%   fmri_showslices(data)
%   fmri_showslices(data, plane, interval, climits)
%   fmri_showslices(data, plane, interval, climits, txt, overlayalpha, cbar, cmap, threshold)
%   fmri_showslices(data, p)        % p from fmri_makevizpar
%
% Inputs:
%   DATA       - Continuous brain map, vectorized (228453 x 1).
%   PLANE      - Slice plane: 1=axial (default), 2=sagittal
%   INTERVAL   - Voxel spacing between displayed slices (1 or 2). Default: 2.
%   CLIMITS    - Colour range [lo hi]. If THRESHOLD is empty, CLIMITS(1)
%                also sets the minimum displayed value. Default: [] selects
%                the range of the finite, non-zero data values, or [0 1] if
%                none are available. For signed maps, use symmetric limits
%                so that zero is centred in the diverging colormap:
%
%                     m = max(abs(data));
%                    climits = [-m m];
%
%   TXT        - Show each slice's position on the tile (0/1). Default: 1.
%                Labels are MNI millimetres on the axis being sliced - z for
%                an axial mosaic, x for a sagittal one - matching the
%                coordinates fmri_regiontable reports, not the 1-91 grid index.
%   OVERLAYALPHA - Opacity of the statistical overlay over the greyscale
%                  anatomy (0-1). Default: 1 (opaque). Below 1 the anatomy
%                  shows through the coloured voxels; 0 hides the overlay
%                  entirely. Only voxels selected by THRESHOLD are blended,
%                  so lowering it does not reveal sub-threshold values.
%   CBAR       - Show colourbar: 1=yes, 0=no. Default: 1.
%   CMAP       - Colormap, in any of three forms. Default: [] = the toolbox
%                diverging blue-white-red map, fmri_divmap(256), shared with
%                the other display functions so that panels agree.
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
%   argument. Fields used: plane, interval, climits, txt, overlayalpha, cbar,
%   cmap, threshold.
% 
% Examples:
%   % Defaults: axial mosaic, every 2nd slice, full-range diverging map
%   fmri_showslices(r_map)
%
%   % Signed statistical map: symmetric limits put the neutral colour at zero,
%   % and THRESHOLD hides the weak middle while keeping effects of both signs
%   m = max(abs(t_map));
%   fmri_showslices(t_map, 1, 2, [-m m], [], [], 1, [], t_crit)
%
%   % Sagittal, every slice, slice labels suppressed
%   fmri_showslices(r_map, 2, 1, [-0.7 0.7], 0)
%
%   % One-sided map with a named MATLAB colormap
%   fmri_showslices(tsnr, 1, 2, [0 100], [], [], 1, 'hot')
%
%   % Custom diverging map from three anchor colours, expanded to 256
%   fmri_showslices(r_map, 1, 2, [-0.7 0.7], [], [], 1, [0 0 0.8; 1 1 1; 1 0 0])
%
%   % Semi-transparent overlay, so the anatomy stays visible underneath
%   fmri_showslices(r_map, 1, 2, [-0.7 0.7], [], 0.6)
%
%   % Options as a struct, reusable across viewers
%   p = fmri_makevizpar('climits', [-m m], 'threshold', t_crit);
%   fmri_showslices(t_map, p)
%
% See also: fmri_showslices_int, fmri_showselectslices, fmri_showplanes,
%           fmri_makevizpar, fmri_divmap


% Accept fmri_makevizpar struct as second argument
if nargin >= 2 && isstruct(plane) && nargin > 2
    error('fmri_showslices:structAndPositional', ...
        'A parameter struct cannot be combined with positional arguments.');
end

if nargin < 2 || isempty(plane),     plane     = 1;  end
if nargin < 3 || isempty(interval),  interval  = 2;  end
if nargin < 4,                       climits   = []; end
if nargin < 5 || isempty(txt),       txt       = 1;  end
if nargin < 6 || isempty(overlayalpha),     overlayalpha     = 1;  end
if nargin < 7 || isempty(cbar),      cbar      = 1;  end
if nargin < 8,                       cmap      = []; end
if nargin < 9,                       threshold = []; end

if nargin >= 2 && isstruct(plane)
    p = plane;  plane = 1;
    if isfield(p,'plane'),     plane     = p.plane;     end
    if isfield(p,'interval'),  interval  = p.interval;  end
    if isfield(p,'climits'),   climits   = p.climits;   end
    if isfield(p,'txt'),       txt       = p.txt;       end
    if isfield(p,'overlayalpha'),  overlayalpha  = p.overlayalpha;     end
    if isfield(p,'cbar'),      cbar      = p.cbar;      end
    if isfield(p,'cmap'),      cmap      = p.cmap;      end
    if isfield(p,'threshold'), threshold = p.threshold; end
end

% ---- validate -----------------------------------------------------------
if ~ismember(plane, [1 2])
    if plane == 3
        error('fmri_showslices:coronalNotSupported', ...
              ['Coronal display (plane = 3) is not implemented for mosaics.\n' ...
               'Use fmri_braincake for coronal slabs or fmri_showplanes for ' ...
               'an orthogonal coronal section.']);
    end
    error('fmri_showslices:badPlane', ...
          'PLANE must be 1 (axial) or 2 (sagittal); got %s.', mat2str(plane));
end

if ~ismember(interval, [1 2])
    error('fmri_showslices:badInterval', ...
          'INTERVAL must be 1 or 2; got %s.', mat2str(interval));
end

% Convert input data only after validating the display parameters.
if ndims(data) > 2
    data = fmri_vol2vect(data);
end
if size(data, 2) > 1
    disp('Data contains several scans, showing 1st scan only.');
    data = data(:, 1);
end

% If CLIMITS is empty, use the range of the finite, non-zero data values.
% This avoids assuming whether the map is signed or one-sided. Because
% CLIMITS(1) also acts as the display threshold when THRESHOLD is empty,
% using the minimum retains all non-zero values.
%
% For signed maps, specify symmetric limits to centre zero in the diverging
% colormap:
%
%     m = max(abs(data));
%     fmri_showslices(data, 1, 2, [-m m])
if isempty(climits)
    finite_vals = data(isfinite(data) & data ~= 0);
    if isempty(finite_vals)
        climits = [0 1];
    else
        climits = [min(finite_vals) max(finite_vals)];
    end
    if climits(1) == climits(2), climits = climits + [-0.5 0.5]; end   % flat data
end

% Use the shared toolbox default: a 256-colour diverging blue-white-red map
% created by fmri_divmap, with neutral white at the centre. 
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
    error('fmri_showslices:badCmap', ...
          'CMAP must be [], an N x 3 matrix, or a colormap name.');
end

colormap(resolved_cmap);

% Clip to the colour range at BOTH ends.
data(data > climits(2)) = climits(2);
data(data < climits(1)) = climits(1);

% Decide which voxels are displayed.
actmask = fmri_actmask(data, threshold, climits);
volactmask=fmri_vect2vol(actmask);

ncolors = size(resolved_cmap, 1);
data(actmask) = floor((ncolors-1)*(data(actmask) - climits(1))/(climits(2) - climits(1))) + 1;
datacol=zeros(size(data,1),3);
datacol(actmask,:) = resolved_cmap(data(actmask),:);

volcol=fmri_vect2vol(datacol);

load graybrain % supplies gb, the greyscale anatomical background
ddd=zeros(91,109,91,3);

gbl=gb.^2;
for k=1:3
    tmp=squeeze(gbl(:,:,:,k));
    tmpcol=volcol(:,:,:,k);
    tmp(volactmask>0)=overlayalpha*tmpcol((volactmask>0))+(1-overlayalpha)*tmp((volactmask>0));
    ddd(:,:,:,k) = tmp;
end

if interval == 1
    if cbar
        spsize = [10.6 8 10.6 8];
    else
        spsize = [9 8 9 8];
    end
else  % interval == 2, validated above
    if cbar
        spsize = [7.1 6 7.1 6];
    else
        spsize = [6 6 6 6];
    end
end
       
% ---- slice labels in MNI millimetres ------------------------------------
% Label slices in MNI millimetres (not voxel indices).
idx_all = (1:91)';
if plane == 1
    mm       = fmri_sub2mni([repmat([46 64], 91, 1), idx_all]);
    mm_label = round(mm(:, 3));
else
    mm       = fmri_sub2mni([idx_all, repmat([64 37], 91, 1)]);
    mm_label = round(mm(:, 1));
end

if plane==1
    if interval==1
        for k=1:72
            x=mod(k-1,9); y=floor((k-1)/9);
            subplot('position',[x/spsize(1) y/spsize(2) 1/spsize(3) 1/spsize(4)]),
            
            image(squeeze(ddd(:,:,5+k,:)));
            if txt
                % text(10,10,num2str(5+k),'color','w')
                text(10,10,num2str(mm_label(5+k)),'color','w')
            end
            axis off
        end
    elseif interval==2
        
        for k=1:36
            x=mod(k-1,6); y=floor((k-1)/6);
            subplot('position',[x/spsize(1) y/spsize(2) 1/spsize(3) 1/spsize(4)]),
            
            image(squeeze(ddd(:,:,6+2*k,:)));
            if txt
                % text(10,10,num2str(6+2*k),'color','w')
                text(10,10,num2str(mm_label(6+2*k)),'color','w')
            end
            axis off
        end
    end
elseif plane==2
    tmp=zeros(91,109,3);
    if interval==1
        for k=1:72
            x=mod(k-1,9); y=floor((k-1)/9);
            subplot('position',[x/spsize(1) y/spsize(2) 1/spsize(3) 1/spsize(4)]),
            tmp2=squeeze(ddd(10+k,:,end:-1:1,:));
            for m=1:3
                tmp(:,:,m)=squeeze(tmp2(:,:,m))';
            end
            image(tmp)
            if txt
                % text(10,10,num2str(10+k),'color','w')
                text(10,10,num2str(mm_label(10+k)),'color','w')
            end
            axis off
        end
    elseif interval==2
        for k=1:36
            ind=2*k+9;
            x=mod(k-1,6);
            y=floor((k-1)/6);
            subplot('position',[x/spsize(1) y/spsize(2) 1/spsize(3) 1/spsize(4)]),
            tmp2=squeeze(ddd(ind,:,end:-1:1,:));
            for m=1:3
                tmp(:,:,m)=squeeze(tmp2(:,:,m))';
            end
            image(tmp)
            if txt
                % text(10,10,num2str(ind),'color','w')
                text(10,10,num2str(mm_label(ind)),'color','w')
            end
            axis off
        end
    end
end


% ---- preserve slice proportions -----------------------------------------
% Set the figure aspect ratio from the mosaic layout and slice dimensions so
% axial and sagittal slices are displayed without distortion. Keep this
% adjustment outside the plane-specific branches so it applies to both.

slice_aspect = size(ddd,2) / size(ddd,1);  % 109/91, both planes
fig_aspect   = (spsize(3)/spsize(4)) * slice_aspect;

pos = get(gcf,'Position');       pos(3) = fig_aspect*pos(4);  set(gcf,'Position',pos);
pos = get(gcf,'PaperPosition');  pos(3) = fig_aspect*pos(4);  set(gcf,'PaperPosition',pos);
    
if cbar
   h = colorbar('position', [.88 .1 .02 .8]);
   l = get(h, 'ylim');
   set(h, 'ytick', [l(1) l(2)]);
   set(h, 'yticklabel', {fmri_ticklabel(climits(1)), ...
                         fmri_ticklabel(climits(2))}, 'fontsize', 14);
end