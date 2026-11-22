%% DEMO_VISUALIZATION  Every display function in the toolbox, on one dataset.
%
% Demonstrates all display functions using one simulated signed map and one
% atlas label map. Only fmri_brainvideo is left commented out, because it
% writes a file. No other files are written. Run it a section at a time
% with Ctrl+Enter rather than all at once: the full script opens more than
% fifty figures.
%
% The data are simulated with fmri_simdata and therefore have irregular
% spatial profiles, giving the displays a more realistic test than simple
% geometric shapes.
%
% Steps:
%   1. Build a signed map and an integer label map
%   2. Colormaps
%   3. Slice mosaics
%   4. Slices chosen by content
%   5. Three-plane view through the peak voxel
%   6. Cortical surfaces and cropped renderings
%   7. 3D isosurfaces
%   8. Value bands as nested surfaces
%   9. Brain cake: the volume as a stack of slabs
%  10. Atlas and Brodmann renderings
%  11. Plotting clusters/regions from fmri_regiontable
%  12. A smooth map: distance from a seed
%  13. Legends and colour scales, for assembling figures by hand
%  14. A rotating video (not run by default)
%  15. fmri_makevizpar: one struct, reused across viewers
%
% Functions demonstrated:
%   1. fmri_simdata, fmri_vol2vect, fmri_loadatlas, fmri_cleanclusters
%   2. fmri_divmap, fmri_makecmap, fmri_distinctcolors
%   3. fmri_showslices, fmri_showslices_int
%   4. fmri_juicyslices, fmri_showselectslices, fmri_showselectslices_int
%   5. fmri_showplanes, fmri_ind2sub, fmri_regionnumber, fmri_sub2mni
%   6. fmri_showcortex
%   7. fmri_show3d, fmri_show3dhalfbrains
%   8. fmri_bin
%   9. fmri_braincake
%  10. fmri_atlas, fmri_show3datlas, fmri_show3dba
%  11. fmri_regiontable
%  12. fmri_voxdist, fmri_sub2ind, fmri_mni2sub
%  13. fmri_createlegend, fmri_colorbar
%  14. fmri_brainvideo
%  15. fmri_makevizpar

clear; close all;
if exist('fmritoolbox_setup', 'file')
    fmritoolbox_setup;
else
    error('Please run fmritoolbox_setup.m from the toolbox root first.');
end

fprintf('=== VoxelWise Toolbox visualisation demo ===\n\n');

%% 1. Build a signed map and an integer label map
% -------------------------------------------------------------------------
% The viewers take two kinds of input, so this section builds one of each.
%
%   T_MAP         signed continuous values, for the colour-mapped viewers
%   REGION_MAP    eight AAL regions labelled 1-8, for the _int viewers
%   MASK_POS/NEG  the two signs of T_MAP as binary maps, for the 3D viewers
rng(30, 'twister');

TR = 2;                                  % seconds
T  = 10;                                 % only the source maps are kept, so T can be small

% Simulate eight spatially irregular sources, more realistic than geometric
% shapes for testing a display.
[~, S_3D] = fmri_simdata(8, 1, T, TR, .9, [], 0.2, 3, 0);
S = fmri_vol2vect(S_3D);                 % 228453 x 8

t_crit = 3.5;                            % display threshold, used throughout
t_lim  = 4 * t_crit;                     % colour limit, used throughout

% Combine the four most widespread sources into a signed map and add weak
% noise. Scaling the weights by T_CRIT keeps the display stable across runs.
% This stands in for a statistical map; demo_glm computes a real one.
[~, big] = sort(sum(S > 0.1, 1), 'descend');
weights  = 3 * t_crit * [1 0.9 -1 -0.8];
t_map    = S(:, big(1:4)) * weights' + 0.15 * t_crit * randn(228453, 1);

% Drop clusters under 50 voxels, so the 3D panels show clusters rather than
% confetti. Only the rejected suprathreshold voxels are zeroed: the values
% below threshold stay, which is what keeps the isosurfaces in the right place.
keep = fmri_cleanclusters(abs(t_map) >= t_crit, 50, 2);
t_map(abs(t_map) >= t_crit & ~keep) = 0;

mask_pos = t_map >=  t_crit;
mask_neg = t_map <= -t_crit;

% Create an integer map from four bilateral AAL regions.
% amygdala, caudate nucleus, hippocampus and postcentral gyrus, left and right.
[atlas, names]  = fmri_loadatlas(1);
regions         = [1 2 7 8 57 58 81 82];
region_names    = names(regions);
[~, region_map] = ismember(atlas, regions);

%% 2. Colormaps
% -------------------------------------------------------------------------
% A colormap is an N x 3 table of RGB rows spanning CLIMITS: the first row
% is the lower limit, the last the upper, whatever values those are.
% fmri_divmap builds the toolbox default for signed data; fmri_makecmap
% builds one from anchor colours, the positions deciding where each colour
% falls on the scale.

[cmap_div, colors_pn] = fmri_divmap(256);

cmap_hotcold = fmri_makecmap([0.05 0.20 0.55
                              0.25 0.55 0.85
                              1    1    1
                              0.80 0.25 0.25
                              0.99 1.00 0.65], [], 256);

cmap_hot     = fmri_makecmap([0.80 0.80 0.80
                              0.70 0.00 0.00
                              1.00 0.90 0.20], [1 40 100], 256);

cmap_seq     = fmri_makecmap([ 97   0 140
                               46  31 122
                               26 133 140
                               64 191  97
                              255 230  20]/255, [1 90 159 192 256], 256);

colors_rg    = fmri_distinctcolors(numel(regions));

maps   = {cmap_div, cmap_hotcold, cmap_hot, cmap_seq, colors_rg, colors_pn};

titles = {'cmap_div - signed, default', ...
          'cmap_hotcold - customized default', ...
          'cmap_hot - one-sided', ...
          'cmap_seq - one-sided, perceptual', ...
          'colors_rg - one colour per label', ...
          'colors_pn - the two ends of cmap_div'};

n = numel(maps);
figure('Color','w','Name','2. Colormaps','Position',[100 100 980 70*n]);
for k = 1:n
    ax = axes('Position', [0.34  1-(k-0.08)/n  0.63  0.84/n]);
    imagesc(ax, 1:size(maps{k},1));  colormap(ax, maps{k});  axis(ax,'off');
    text(ax, -0.02, 0.5, titles{k}, 'Units','normalized', 'Interpreter','none', ...
         'HorizontalAlignment','right', 'VerticalAlignment','middle', 'FontSize', 14);
end
%% 3. Slice mosaics
% -------------------------------------------------------------------------
% CLIMITS sets the colour scale. THRESHOLD (t_crit below) selects which
% voxels are drawn at all: leave it out and every voxel is painted,
% including the near-zero ones, so the anatomy disappears under mid-range
% colour.

figure('Name','3a. Axial mosaic, every second slice');
fmri_showslices(t_map, 1, 2, [-t_lim t_lim], 1, 1, 1, cmap_div, t_crit);

% INTERVAL = 1 shows every slice instead, in a denser mosaic.
figure('Name','3b. Axial mosaic, every slice');
fmri_showslices(t_map, 1, 1, [-t_lim t_lim], 1, 1, 1, cmap_div, t_crit);

figure('Name','3c. Sagittal mosaic');
fmri_showslices(t_map, 2, 2, [-t_lim t_lim], 0, [], 1, cmap_div, t_crit);

% One-sided limits with a one-sided colormap show the positive tail alone.
figure('Name','3d. Axial mosaic, positive only');
fmri_showslices(t_map, 1, 2, [0 t_lim], 0, [], 1, cmap_hot, t_crit);

% The integer viewer takes one colour per label and draws a legend from LABELS.
figure('Name','3e. Integer mosaic, AAL regions, with a legend');
fmri_showslices_int(region_map, 1, 2, colors_rg, 1, 1, region_names);

%% 4. Slices chosen by content
% -------------------------------------------------------------------------
% fmri_juicyslices selects the slices containing the most suprathreshold
% signal. The final two arguments set the threshold (t_crit) and minimum
% separation (3), preventing neighbouring slices from being chosen from the
% same cluster.

sl_ax = fmri_juicyslices(t_map, 'axial', 6, t_crit, 3);
fprintf('Slices carrying most signal: z = %s\n', mat2str(sl_ax));

figure('Name','4a. Selected axial slices');
fmri_showselectslices(t_map, sl_ax, [-t_lim t_lim], 1, 1, 1, cmap_div, t_crit);

% The integer counterpart. OVERLAYALPHA blends the labels into the anatomy so
% the underlying structure stays visible.
figure('Name','4b. Selected slices, integer map');
fmri_showselectslices_int(region_map, sl_ax, colors_rg, 1, 0.85);

% LABELS adds a legend beside the slices, and widens the figure to fit it.
figure('Name','4c. The same, with a legend');
fmri_showselectslices_int(region_map, sl_ax, colors_rg, 1, 0.85, region_names);

%% 5. Three-plane view through the peak voxel
% -------------------------------------------------------------------------
% Sagittal, coronal and axial slices intersecting at one voxel, with a
% crosshair marking it. COORD is a voxel subscript, so an MNI coordinate would
% go through fmri_mni2sub first.

[~, peak] = max(abs(t_map));                 % strongest voxel, either sign
peak_sub  = fmri_ind2sub(peak);              % vector index -> [x y z]

figure('Name','5. Three-plane view through the peak voxel');
fmri_showplanes(t_map, peak_sub, [-t_lim t_lim], 1, cmap_div, 1, 'k', [0 1 0], t_crit);

peak_name = fmri_regionnumber(peak_sub, 1);  % AAL label at that voxel
fprintf('Peak voxel at MNI %s: %s\n\n', ...
        mat2str(fmri_sub2mni(peak_sub)), char(string(peak_name)));

%% 6. Cortical surfaces and cropped renderings
% -------------------------------------------------------------------------
% fmri_showcortex projects the map onto the cortical surface. It has no
% THRESHOLD argument: every voxel is coloured and CLIMITS sets the color
% scale. Values outside the limits are capped at the end colours.
climits = [-5 5];

figure('Name','6a. Cortical surface');
fmri_showcortex(t_map, 30, 28, [], climits, [], 0, cmap_div);

% CROP cuts anatomy away from the rendering. The data values are never
% altered. MASKALPHA keeps a ghost of the whole brain for context.
figure('Name','6b. Coronal crop, no shell');
fmri_showcortex(t_map, 30, 28, [45 30; -45 30], climits, ...
                [1 91 1 55 1 91], 0, cmap_div);
figure('Name','6c. The same, with a transparent shell');
fmri_showcortex(t_map, 30, 28, [45 30; -45 30], climits, ...
                [1 91 1 55 1 91], 0.05, cmap_div);

figure('Name','6d. Left hemisphere');
fmri_showcortex(t_map, -10, 0, [45 30; -45 30], climits, ...
                [1 45 1 109 1 91], 0, cmap_div);

% CROP also takes a mask, so the crop need not be a box.
[x, y, z] = ndgrid(1:91, 1:109, 1:91);

m = ((x-32)/25).^2 + ((y-32)/30).^2 + ((z-68)/20).^2 > 1;
figure('Name','6e. Ellipsoidal window into posterior-superior structures');
fmri_showcortex(t_map, -170, 20, [45 20; -45 20], climits, m, 0.06, cmap_div);

m = ones(91,109,91);  m(46:91, 30:109, 46:91) = 0;
figure('Name','6f. Quadrant crop rendering');
fmri_showcortex(t_map, 41, 29, [45 10; -45 -10], climits, m, 0, cmap_div, 'metal');

%% 7. 3D isosurfaces
% -------------------------------------------------------------------------
% fmri_show3d draws one surface per data COLUMN, each in a single colour.

% region_map is one column, so all regions come out as one coloured surface.
figure('Name','7a. One column: all regions in one colour');
fmri_show3d(region_map, 140, 15, [], [], [1 0 0], 0.08);

% Lateral and medial views of both hemispheres, assembled into one figure.
fmri_show3dhalfbrains(region_map)
set(gcf, 'Name','7b. Four hemisphere views');  

% One column per region colours them separately. LABELS adds the legend.
region_maps = region_map == 1:numel(regions);   % 228453 x 8
figure('Name','7c. One column per region, with a legend');
fmri_show3d(region_maps, 140, 15, [], [], colors_rg, 0.08, [], [], region_names);

% GREYPAR fades far surfaces toward white for depth, so they read paler than
% the legend. Lower it to match, 0 turns it off.
figure('Name','7d. The same, GREYPAR = 0.1');
fmri_show3d(region_maps, 140, 15, [], [], colors_rg, 0.08, [], 0.1, region_names);

% Binary masks (both signs): two columns, so each gets its own colour.
figure('Name','7e. Both signs, from binary masks');
fmri_show3d([mask_pos mask_neg], 0, 90, [], [], colors_pn, 0.08, [], [], ...
            {'Positive','Negative'});

%% 8. Value bands as nested surfaces
% -------------------------------------------------------------------------
% fmri_bin divides a continuous map into NBINS value ranges, returning one
% binary map per range and a matching colormap. When rendered as surfaces,
% the bands appear nested, with higher values inside lower ones. SURFALPHA
% controls how much of the inner bands remain visible.

[binned, bincmap] = fmri_bin(t_map, t_crit, t_lim, 5);
fprintf('fmri_bin: %d bands, %s voxels per band\n\n', size(binned,2), ...
        mat2str(sum(binned > 0, 1)));

figure('Name','8a. Nearly opaque: only the outer band is readable');
fmri_show3d(binned, 40, 15, [], 0.9, bincmap, 0.08);

% SURFALPHA takes one value per column, so the bands can fade inward.
figure('Name','8b. Graded opacity: outer bands transparent, core solid');
fmri_show3d(binned, 40, 15, [], linspace(0.25, 1, 5), bincmap, 0.08);

%% 9. Brain cake: the volume as a stack of slabs
% -------------------------------------------------------------------------
% fmri_braincake cuts the brain into slabs and separates them in 3D, so a whole
% volume can be read in one image. PLANE picks the cut, STACKDIR whether the
% slabs are rendered in a row or piled up, and the viewing angle decides how
% obliquely the slab faces are seen.

% Slices carrying the most signal in each plane.
sl = fmri_juicyslices(t_map, 'all', 6, t_crit, 4);
fprintf('  axial %s | coronal %s | sagittal %s\n\n', ...
        mat2str(sl.axial), mat2str(sl.coronal), mat2str(sl.sagittal));

% A. Axial slabs in a row, seen from the side. The most legible layout, and the
%    closest thing to a slice mosaic in three dimensions.

fmri_braincake(t_map, -90, 20, 1, sl.axial, 4, 2, 0.08, ...
               [-6 6], [45 66; -45 65], 10, cmap_hotcold, 'metal');
set(gcf, 'Name','9a. Axial slabs in a row, metal');

% SURFMATERIAL sets the surface reflectance: 'shiny' gives brighter
% highlights than 'metal'.
fmri_braincake(t_map, -90, 20, 1, sl.axial, 4, 2, 0.08, ...
               [-6 6], [45 66; -45 65], 10, cmap_hotcold, 'shiny');
set(gcf, 'Name','9b1. The same, shiny');

fmri_colorbar(cmap_hotcold, [-6 6], 'Threshold', t_crit, 'Label', 't');
set(gcf, 'Name','9b2. Colour scale, cmap_hotcold');

% B. Coronal slabs from the front, with the shell still visible for context.
fmri_braincake(t_map, 90, 0, 3, sl.coronal, 4, 2, 0.08, ...
               [-6 6], [45 10; -45 10], 10, cmap_hotcold);
set(gcf, 'Name','9c. Coronal slabs, with shell');

% C. Sagittal slabs from the front, with the shell still visible for context.
fmri_braincake(t_map, 0, 0, 2, sl.sagittal, 4, 2, 0.08, ...
               [-6 6], [45 10; -45 10], 10, cmap_hotcold);
set(gcf, 'Name','9d. Sagittal slabs, with shell');

% D. Layered cake, axial slabs stacked vertically
%    STACKDIR = 1 and a positive elevation 
%    maskalpha (shell) is transparent (slabs are freely stackable)
fmri_braincake(t_map, 90, 25, 1, sl.axial, 4, 1, 0, ...
               [-6 6], [45 50; -45 50], 5, cmap_hotcold);
set(gcf, 'Name','9e. Layered cake, axial slabs stacked'); 

% set THICKNESS to make the slabs tile the gaps
slices  = [15 30 47 59 65 71 80];
thickness = [10 diff(slices)];

% with brain shell (maskalpha = 0.05)
fmri_braincake(t_map, -90, 19, 1, slices, thickness, 2, 0.05, [-5 5], [45 30; -45 30], 10, cmap_hotcold);
set(gcf, 'Name','9f. Slabs tiling the gaps, with shell');

% without brain shell (maskalpha = 0)
fmri_braincake(t_map, -90, 10, 1, slices, thickness, 1, 0, [-5 5], [45 30; -45 30], 5, cmap_hotcold);
set(gcf, 'Name','9g. The same, no shell');
%% 10. Atlas and Brodmann renderings
% -------------------------------------------------------------------------
% fmri_atlas prints the atlases and their numbers. fmri_show3datlas renders the
% regions of one atlas, each in its own colour, with a legend.

fmri_atlas

figure, fmri_show3datlas(9, [1 5 9]);
set(gcf, 'Name', ['10a. ' get(gcf,'Name') ' - three regions, default view']);

figure, fmri_show3datlas(9, 1:9, [], 140, 15); 
set(gcf, 'Name', ['10b. ' get(gcf,'Name') ' - all nine regions, oblique view']);

figure, fmri_show3datlas(7, [], 1, -90, 90, [], 0.1);
set(gcf, 'Name', ['10c. ' get(gcf,'Name') ' - every region, from above']);

figure, fmri_show3datlas(3, [1:5 15:20], [], 40, 20);
set(gcf, 'Name', ['10d. ' get(gcf,'Name') ' - a split selection']);

figure, fmri_show3datlas(2, 1:10, [], 20, 14, 0.03);
set(gcf, 'Name', ['10e. ' get(gcf,'Name') ' - fainter brain shell']);

figure, fmri_show3datlas(1, 1:8, [], -90, 90, [], 0.1);
set(gcf, 'Name', ['10f. ' get(gcf,'Name') ' - GREYPAR lowered to match the key']);

figure, fmri_show3datlas(6, 1:10, 1, 40, 20, [], 0.1);
set(gcf, 'Name', ['10g. ' get(gcf,'Name') ' - ten regions, oblique view']);

% fmri_show3dba splits a map into Brodmann areas and colours each 
% separately
figure('Name','10h. Brodmann areas in a thresholded map');
fmri_show3dba(t_map > t_crit*2.7, 180, 0, [], [], [], [], [], 0);

% The Angular gyrus (L) spans BA 7, 19, 39 40
figure('Name','10i. Brodmann areas within one gyrus');
fmri_show3dba(atlas == 3, -90, 90,[],[],[],[],[],0);  

%% 11. Plotting clusters/regions from fmri_regiontable
% -------------------------------------------------------------------------
% fmri_regiontable returns one binary map per cluster in CLUS, and for each
% cluster one binary map per atlas region it covers in ROI, with the region
% names in LIST. The columns can be passed directly to any viewer.

cs = 20;                                   % smallest cluster reported
[clust, ~, ROI, list, ~, clus] = fmri_regiontable(t_map <= -t_crit, t_map, cs, 5, 1);
fprintf('Region table: %d clusters of %d voxels or more\n', numel(clust), cs);

% One colour per cluster, labelled with its size.
colors_cl = fmri_distinctcolors(size(clus, 2));
labels_cl = arrayfun(@(k) sprintf('Cluster %d (%d voxels)', k, nnz(clus(:,k))), ...
                     1:size(clus,2), 'UniformOutput', false);

figure('Name','11a. One colour per cluster');
fmri_show3d(clus, 28, 20, [], [], colors_cl, 0.08, [], [], labels_cl);

% The same, for the atlas regions inside one cluster.
c          = 1;
colors_rg2 = fmri_distinctcolors(size(ROI{c}, 2));

figure('Name','11b. Regions within cluster 1');
fmri_show3d(ROI{c}, -52, 11, [], [], colors_rg2, 0.08, [], [], list{c});

% Slices chosen from the cluster itself, so they cut where it actually is.
sl2 = fmri_juicyslices(sum(ROI{c}, 2), 'axial', 3, [], 1);

figure('Name','11c. The same regions on slices');
fmri_showselectslices_int(ROI{c}, sl2, colors_rg2, 1, [], list{c});

%% 12. A smooth map: distance from a seed
% -------------------------------------------------------------------------
% Computing distances from a seed voxel to every other voxel creates a
% smooth and strictly positive map, so a sequential colormap is
% appropriate. THRESHOLD = 0 shows all finite voxels, including
% the seed at distance zero.

seed_mni = [-42 -68 52];                           % left angular gyrus
seed     = fmri_sub2ind(fmri_mni2sub(seed_mni));   % mm -> voxel subscript -> vector index
D        = fmri_voxdist(seed, 1:228453)';          % distance to every voxel, in mm

figure('Name','12a. Distance from the left angular gyrus (mm)');
fmri_showslices(D, 1, 2, [0 max(D)], 1, 1, 1, cmap_seq, 0);

% Any MATLAB colormap can be passed in place of a toolbox one.
figure('Name','12b. The same, with parula');
fmri_showslices(D, 1, 2, [0 max(D)], 1, 1, 1, parula, 0);

% Setting CROP to show only the left hemisphere of the brain
figure('Name','12c. Left hemisphere');
fmri_showcortex(D, 31, 12, [75 -5; -75 -5], [0 max(D)], ...
                [1 46 1 109 1 91], 0.04, cmap_seq, 'shiny');

% setting CROP to show only the lower half of the brain
figure('Name','12d. Lower half');
fmri_showcortex(D, 38, 30, [45 120; -45 120], [0 max(D)], ...
                [1 91 1 109 1 45], 0.04, cmap_seq, 'shiny');

%% 13. Legends and colour scales, for assembling figures by hand
% LEGENDS -----------------------------------------------------------------
% Some viewers can draw legends from LABELS. If the legend becomes crowded,
% use fmri_createlegend to create a separate, exportable legend for the final
% figure layout (e.g., a graphics editor).

legend_rg = fmri_createlegend(list{c}(:), colors_rg2, ...
                              'Title', sprintf('Cluster %d regions', c), ...
                              'FontSize', 24, 'MaxLabelLength', 30);
set(gcf, 'Name','13. Cluster 1 region legend');
% imwrite(legend_rg, 'cluster1_legend.png'); % save the legend

% COLORBARS ---------------------------------------------------------------
% fmri_showcortex, fmri_braincake and fmri_show3d draw no colour bar.
% fmri_colorbar draws one in a window of its own. Pass the same colormap
% and climits the viewer used and the scale matches the figure exactly.

climits = [-6 6];

figure('Name','13a1. Cortical surface with a signed colour bar');
fmri_showcortex(t_map, 31, 42, [45 66; -45 65], climits, [], [], cmap_div);

fmri_colorbar(cmap_div, climits, 'Threshold', t_crit, 'Label', 't-value');
set(gcf, 'Name','13a2. Colour scale, cmap_div');

% cmap_hot runs from baseline to one extreme, so the limits start at zero.
% THRESHOLD adds a tick at t_crit.

climits = [0 6];

figure('Name','13b1. The same, one-sided colour bar');
fmri_showcortex(t_map, 31, 42, [45 66; -45 65], climits, [], [], cmap_hot);

fmri_colorbar(cmap_hot, climits, 'Threshold', t_crit, 'Label', 't');
set(gcf, 'Name','13b2. Colour scale, cmap_hot');

%% 14. A rotating video (not run by default)
% -------------------------------------------------------------------------
% fmri_brainvideo renders a rotation with fmri_show3d and writes an MP4.
% NFRAMES sets the smoothness and FPS the playback speed, so their ratio is
% the duration: 120 frames at 25 fps is just under five seconds for one turn.
% TRAJECTORY picks the camera path; help fmri_brainvideo lists nine. The call
% is commented out because it writes a file.
%
%   fmri_brainvideo(mask_pos, 'rotation.mp4', 'trajectory', 'cinematic', ...
%                   'nframes', 120, 'fps', 25);
%
% The rendered frames are also returned, so a sequence can be re-encoded at a
% different frame rate without rendering it again.


%% 15. fmri_makevizpar: one struct, reused across viewers
% -------------------------------------------------------------------------
% Every viewer also accepts a single options struct. Each viewer uses the
% fields it recognises and ignores the rest. Define options once to keep
% colour limits, colormaps, and thresholds consistent across figures.
p = fmri_makevizpar('climits', [-t_lim t_lim], 'threshold', t_crit, ...
                    'cmap', cmap_div, 'color', colors_rg, ...
                    'labels', region_names, 'overlayalpha', 0.85, ...
                    'plane', 1, 'interval', 2, 'slices', sl.axial, ...
                    'cbar', 1, 'txt', 1);

figure('Name','15a. Mosaic from a parameter struct');
fmri_showslices(t_map, p);

figure('Name','15b. Selected slices, same struct');
fmri_showselectslices(t_map, p);

figure('Name','15c. Integer mosaic, same struct');
fmri_showslices_int(region_map, p);

figure('Name','15d. Selected slices, integer map, same struct');
fmri_showselectslices_int(region_map, p);

fprintf('=== Visualization demo complete ===\n');
