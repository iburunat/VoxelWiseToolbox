% DEMO_VISUALIZATION  Every display function in the toolbox, on one dataset.
%
% Runs through the visualisation module: slice mosaics, selected slices, the
% three-plane view, cortical surfaces and cut-aways, 3D isosurfaces, layered
% slab renderings ("brain cake"), and the colormap constructors that all of
% them share.
%
% The data are simulated with fmri_simdata rather than drawn as analytic
% spheres. Spheres render as perfect balls, which look nothing like an fMRI
% result and make every 3D figure in this demo misleading about what the
% functions produce in practice. The simulator's sources are irregular and
% brain-shaped, so the renderings show what a real map looks like.
%
% Nothing here needs scanner data, and no files are written.
%
% See also: fmri_showslices, fmri_showselectslices, fmri_showplanes,
%           fmri_showcortex, fmri_show3d, fmri_braincake, fmri_juicyslices,
%           fmri_divmap, fmri_makecmap, fmri_bin, fmri_makevizpar

clear; close all
fprintf('=== VoxelWise Toolbox: visualisation demo ===\n\n');

%%% USE OTHER COLORMAPS!!! LIKE VIRIDIS
%%%%%ALSO PLOT SIMPLER MAPS LIKE fmri_voxdist

%% 1. Data: a signed statistical map, and an integer label map
% -------------------------------------------------------------------------
rng(2, 'twister');
TR = 2;  T = 120;
% SIGMA_RATIO (argument 5) sets each blob's width as a fraction of its radius,
% so raising it widens every blob without changing where they sit. 
[~, S_3D, W] = fmri_simdata(8, 1, T, TR, .9, [], 0.2, 3, 0);

% S_3D is 91 x 109 x 91 x N_SOURCES - a stack of VOLUMES, not a vectorised
% matrix. Indexing it as S_3D(:,k) silently returns the k-th column of the
% first slice: 91 values, which then fail deep inside fmri_vect2vol rather
% than at the point of the mistake.
S = zeros(228453, size(S_3D, 4));
for k = 1:size(S_3D, 4)
    S(:, k) = fmri_vol2vect(S_3D(:, :, :, k));
end

t_crit = 3.5;                       % display threshold used throughout
t_lim  = 4 * t_crit;

% Build the map from the LARGEST blobs rather than from fixed indices, since
% which sources are large depends on the seed. Amplitudes are set as multiples
% of the threshold, so a fixed fraction of each Gaussian survives it whatever
% radii were drawn: at 3*t_crit everything within about 1.5 sigma clears.
[~, big] = sort(sum(S > 0.1, 1), 'descend');
amp   = 3 * t_crit;
t_map =  amp*S(:,big(1)) + 0.9*amp*S(:,big(2)) ...
        - amp*S(:,big(3)) - 0.8*amp*S(:,big(4)) ...
        + 0.15*t_crit*randn(228453, 1);

% An integer label map for the _int viewers: AAL, a handful of regions.
[ROI_nos, ~] = fmri_loadatlas(1);
labels = zeros(size(ROI_nos));
pick   = [1 2 7 8 57 58 81 82];     % frontal, temporal, hippocampus, STG
for k = 1:numel(pick), labels(ROI_nos == pick(k)) = k; end

fprintf('Map: %d suprathreshold voxels (%d positive, %d negative)\n\n', ...
        nnz(abs(t_map) >= t_crit), nnz(t_map >= t_crit), nnz(t_map <= -t_crit));

%% 2. Colormaps
% -------------------------------------------------------------------------
% fmri_divmap builds the toolbox's diverging map; every viewer defaults to it.
% fmri_makecmap builds one from arbitrary anchor colours and positions, which
% is how a non-linear ramp is made - moving an anchor changes how quickly the
% colours change on either side of it.
cmap_div = fmri_divmap(256);                          % blue - white - red
cmap_hot = fmri_makecmap([0 0 0; 0.7 0 0; 1 0.9 0.2], [1 40 100], 256);
cmap_viridis= fmri_makecmap([0.267004, 0.004874, 0.329415; 0.263663, 0.237631, 0.518762;...
    0.135066, 0.544853, 0.554029; 0.119699, 0.618490, 0.536347; 0.191090,...
    0.708366, 0.482284; 0.993248, 0.906157, 0.143936], [1 47 124 144 184 256], 256);
cmap_viridis = fmri_makecmap([.3 0 .3; .1 .5 .6; .1 .6 .5; .2 .7 .5; 1 .9 .1], [1 124 144 184 256], 256);
figure, imagesc(1:256), colormap(cmap_viridis), axis off
figure('Name','1. Colormaps','Color','w');
subplot(2,1,1), imagesc(1:256); colormap(gca, cmap_div); axis off
title('fmri\_divmap(256) — the shared default', 'FontSize', 11);
subplot(2,1,2), imagesc(1:256); colormap(gca, cmap_hot); axis off
title('fmri\_makecmap — anchors at [1 40 100], so black gives way to red early', ...
      'FontSize', 11);

%% 3. Slice mosaics
% -------------------------------------------------------------------------
figure('Name','2. Axial mosaic (continuous)');
fmri_showslices(t_map, 1, 2, [-t_lim t_lim], 1, 1, 1, cmap_div, t_crit);

% data=double(t_map>1);
% fmri_showslices(data, 1, [],[-.99 .99], 1, [],1,[],.001);
% figure,fmri_showslices_int(data, 1, [],[], 1);
% figure,fmri_showselectslices(data, [20:10:50], [-.99 .99 ],[], 1,[],[],.8);


figure('Name','3. Sagittal mosaic');
fmri_showslices(t_map, 2, 2, [-t_lim t_lim], 0, [], 1, cmap_div, t_crit);

figure('Name','4. Integer mosaic (AAL regions)');
fmri_showslices_int(labels, 1, 2, fmri_distinctcolors(numel(pick)), 1, 0.85);

%% 4. Slices chosen by content, not by spacing
% -------------------------------------------------------------------------
% A regular mosaic devotes equal space to every slice, so a focal result gets a
% few pixels in two tiles and empty anatomy fills the rest. fmri_juicyslices
% ranks slices by how much suprathreshold signal they carry; showing six of
% those, larger, is usually the difference between a figure that shows an
% effect and one that merely contains it.
sl = fmri_juicyslices(t_map, 'axial', 6, t_crit, 3);
fprintf('Slices carrying most signal: z = %s\n', mat2str(sl));

figure('Name','5. Selected axial slices');
fmri_showselectslices(t_map, sl, [-t_lim t_lim], 1, 1, 1, cmap_div, t_crit);

figure('Name','6. Selected slices, integer map');
fmri_showselectslices_int(labels, sl, fmri_distinctcolors(numel(pick)), 1, 0.85);

% All three planes at once, for choosing a figure orientation.
sl3 = fmri_juicyslices(t_map, 'all', 5, t_crit, 4);
fprintf('  axial %s | coronal %s | sagittal %s\n\n', ...
        mat2str(sl3.axial), mat2str(sl3.coronal), mat2str(sl3.sagittal));

%% 5. Three-plane view through the peak voxel
% -------------------------------------------------------------------------
[~, peak] = max(abs(t_map));
figure('Name','7. Three-plane view');
fmri_showplanes(t_map, fmri_ind2sub(peak), [-t_lim t_lim], 1, cmap_div, 1, 'k', ...
                [0 1 0], t_crit);
% fmri_regionnumber returns the region NAME as its first output and the region
% NUMBER as its second; only the number is what fmri_nregion takes, so the two
% are not composable in the obvious direction.
peak_sub  = fmri_ind2sub(peak);
peak_name = fmri_regionnumber(peak_sub, 1);
fprintf('Peak voxel at MNI %s: %s\n\n', mat2str(fmri_sub2mni(peak_sub)), ...
        char(string(peak_name)));

%% 6. Cortical surface
% -------------------------------------------------------------------------
% fmri_showcortex interpolates the map onto the surface of the anatomy, so it
% shows continuous values rather than a thresholded blob. There is deliberately
% no THRESHOLD argument: CLIMITS controls the colour mapping, and CROP is what
% removes anatomy.
figure('Name','8. Cortical surface');
fmri_showcortex(t_map, 180, 10, [], [-t_lim t_lim], [], 0, ...
                cmap_div, 'metal');
%% 7. Cut-aways: CROP removes anatomy, MASKALPHA keeps a ghost of the whole
% -------------------------------------------------------------------------
% CROP takes either a bounding box or a mask, and cuts the ANATOMY rather than
% the data: the surface is removed, exposing what lies behind it, while the
% values themselves are untouched. MASKALPHA then draws a faint shell of the
% whole brain around the cut, which is what makes the figure legible - a cut
% without it is a floating slab with no context.
%
% Each render needs its OWN figure. fmri_showcortex, fmri_show3d and
% fmri_showplanes all call clf before drawing, so a subplot loop leaves only
% the last panel. For a montaged series of cuts, use fmri_braincake (below),
% which renders each slab separately and joins the images afterwards.

ycuts = [75 35];
for k = 1:numel(ycuts)
    figure('Name', sprintf('9a.%d Coronal cut, anterior to y-index %d', k, ycuts(k)));
    fmri_showcortex(t_map, 26, 0, [45 30; -45 30], [-t_lim t_lim], ...
                    [1 91 1 ycuts(k) 1 91], 0.08, cmap_div, 'metal');
end

figure('Name','9b. Quadrant removed, to look inside');
m = ones(91,109,91);  m(1:45, 55:109, 46:91) = 0;
fmri_showcortex(t_map, 150, 26, [45 30; -45 30], [-t_lim t_lim], ...   %%% would be nice if blobs inside
                m, 0.08, cmap_div, 'metal');

% A single hemisphere, by passing a mask instead of a bounding box.
figure('Name','10. Left hemisphere only');
lh = zeros(91,109,91);  lh(1:45,:,:) = 1;
fmri_showcortex(t_map, 33, 16, [45 30; -45 30], [-t_lim t_lim], ...
                lh, 0.05, cmap_div);

%% 8. 3D isosurfaces
% -------------------------------------------------------------------------
% fmri_show3d renders each data COLUMN as a separately coloured surface, so
% positive and negative effects are passed as two columns rather than one
% signed map.
pos = double(t_map .* (t_map >= t_crit));
neg = double(-t_map .* (t_map <= -t_crit));

figure('Name','11. Isosurfaces, both signs');
fmri_show3d([pos neg], 0, 90, 0.35, 0.9, [0.85 0.1 0.1; 0.1 0.55 0.85], 0.08);

figure('Name','12. Four hemisphere views');
fmri_show3dhalfbrains([pos neg], 0.35,  0.9, [0.85 0.1 0.1; 0.1 0.55 0.85], 0.08);

%% 9. fmri_bin: one continuous map as nested isosurfaces
% -------------------------------------------------------------------------
% A single isosurface shows one level and discards the rest of the range.
% fmri_bin splits the map into bands and returns them as separate columns with
% a matching colour table, so fmri_show3d can draw them as nested shells - the
% 3D equivalent of a contour plot, with the strongest values innermost.
[binned, bincmap] = fmri_bin(pos, t_crit, t_lim, 5);
fprintf('fmri_bin: %d bands, %s voxels per band\n\n', size(binned,2), ...
        mat2str(sum(binned > 0, 1)));

figure('Name','13. Nested isosurfaces (fmri_bin)');
fmri_show3d(binned, -90, 0, 0.5,[], bincmap, 0.08);

%% 10. Brain cake: layered slabs
% -------------------------------------------------------------------------
% Each slab is a cropped cortical render, montaged into one strip.
% again supplies the ghost shell, which is what makes the series readable as a
% brain rather than as a row of discs.
fmri_braincake(t_map, 25, 25, 3, round(linspace(90, 30, 6)), 4, 2, 0, ...
               [-t_lim t_lim], [45 30; -45 30], 20, cmap_div);

set(gcf, 'Name', '14. Brain cake, coronal series (signed map, diverging map)', ...
         'NumberTitle', 'off');

fmri_braincake(t_map, -90, 20, 1, round(linspace(70, 24, 10)), 4, 2, 0.08, ...
               [-t_lim t_lim], [45 30; -45 30], 10, cmap_div, 'metal');
set(gcf, 'Name', '15. Brain cake, axial series (signed map, diverging color map)', ...
         'NumberTitle', 'off');

%% 11. Atlas renderings
% -------------------------------------------------------------------------
figure('Name','16. Atlas regions in 3D');
fmri_show3datlas(9, [], 0.6, 140, 15);            % MNI structural, 9 regions

% a struct 
p = fmri_makevizpar('az', 140, 'el', 15);
fmri_show3datlas(9, p);

figure('Name','17. Brodmann areas present in the map');
fmri_show3dba(abs(t_map) >= t_crit, 140,15);
figure,fmri_show3dba(abs(t_map) >= t_crit, 140,15);
figure,fmri_show3dba(t_map >= t_crit, -53,5);   %% add labels BA

%% 12. One parameter struct, several viewers
% -------------------------------------------------------------------------
% Every viewer accepts its options either positionally or as a single struct
% from fmri_makevizpar. The struct form guarantees that panels meant to be
% compared share their colour limits, colormap and threshold exactly - which
% is hard to hold by hand across five calls.
p = fmri_makevizpar('climits', [-t_lim t_lim], 'threshold', t_crit, ...
                    'cmap', cmap_div, 'slices', sl, 'plane', 1, ...
                    'interval', 2, 'cbar', 1, 'txt', 1);

figure('Name','18. Mosaic from a parameter struct');
fmri_showslices(t_map, p);

figure('Name','19. Selected slices, same struct');
fmri_showselectslices(t_map, p);

%% 13. Rotating video (not run by default)
% -------------------------------------------------------------------------
% fmri_brainvideo writes a file, so it is left commented out. Trajectories:
% cinematic, constant, reverse, fixed, figure8, spiral, reveal, surgical,
% dualpass.
%
%   fmri_brainvideo(pos, 'rotation.mp4', 'trajectory', 'cinematic', ...
%                   'nframes', 120, 'fps', 25);

fprintf(['Done. 19 figures.\n\n' ...
         'Two habits worth carrying over:\n' ...
         '  - Threshold the figure at the value the analysis used, so the\n' ...
         '    picture and the statistics agree.\n' ...
         '  - Scale colour limits to a small multiple of that threshold, not\n' ...
         '    to max(abs(map)): at low degrees of freedom the maximum is an\n' ...
         '    outlier and every significant voxel is compressed to mid-scale.\n']);


%% 14. Plotting a region table: clusters, with a legend for export
% -------------------------------------------------------------------------
% fmri_regiontable returns more than a table. CLUS is one binary column per
% cluster and ROI{c} is one column per atlas region within cluster c, so both
% can be handed straight to fmri_show3d, which renders each column in its own
% colour.
%
% fmri_show3d draws no legend - deliberately, since a legend that lives inside
% the 3D axes moves when the view rotates. fmri_createlegend builds one as a
% separate IMAGE instead, which is what you want for a figure panel: place it
% beside the rendering in the layout, at whatever size the journal needs.
[clust, s, ROI, list, roi_idx, clus, T] = fmri_regiontable(t_map >= t_crit, ...
                                                           t_map, 20, 5, 1);
fprintf('Region table: %d clusters above %d voxels\n', numel(clust), 20);

% All clusters at once, one colour each.
colors_cl = fmri_distinctcolors(size(clus, 2));
labels_cl = arrayfun(@(k) sprintf('Cluster %d  (%d voxels)', k, nnz(clus(:,k))), ...
                     1:size(clus,2), 'UniformOutput', false);

labels_cl = cellstr(strcat('Cluster ', string(1:size(clus,2))));
figure('Name','14a. Clusters, legend inside the figure');
% LABELS is the 10th argument, so CROP and GREYPAR need [] placeholders.
fmri_show3d(clus, -90, 17, 0.5, 0.9, colors_cl, 0.08, [], [], labels_cl);

legend_cl = fmri_createlegend(labels_cl(:), colors_cl, 'Title', 'Clusters', ...
                              'FontSize', 12, 'FigureSize', [10 100]);
% imwrite(legend_cl, 'clusters_legend.png');   % uncomment to export

% One cluster broken into its atlas regions, same idea at a finer grain. %% <------------PICK A LESS CROWDED REGION ----
c = 1;
colors_rg = fmri_distinctcolors(size(ROI{c}, 2));

figure('Name','14b. Regions within cluster 1');
fmri_show3d(ROI{c}, -140, 15, 0.5, 0.9, colors_rg, 0.08);

legend_rg = fmri_createlegend(list{c}(:), colors_rg, 'Title', ...
                              sprintf('Cluster %d regions', c), ...
                              'FontSize', 11, 'MaxLabelLength', 30, ...
                              'FigureSize', [520 600]);
% imwrite(legend_rg, 'cluster1_legend.png');

% The same legend serves a slice mosaic, which is the usual paper figure.
figure('Name','14c. Cluster 1 regions as a slice mosaic');
fmri_showslices_int(ROI{c}, 1, 2, colors_rg, 1, 0.85);

%% 15. A simple continuous map: distance from a seed
% -------------------------------------------------------------------------
% fmri_voxdist returns Euclidean distance in MILLIMETRES from one voxel to any
% set of others. It makes an unusually good test map for display code: the
% values are smooth, unsigned, and have an obviously correct appearance, so a
% rendering that looks wrong IS wrong. On a statistical map the same figure
% might just be what the data says.
seed = fmri_sub2ind(fmri_mni2sub([-46 -28 11]));     % left Heschl's gyrus
D    = fmri_voxdist(seed, 1:size(S,1))';             % 228453 x 1, in mm

figure('Name','15. Distance from a seed voxel (mm)');
% THRESHOLD = 0 draws every finite voxel, which is right here: zero is a real
% distance (the seed itself), not a "hide me" code.
fmri_showslices(D, 1, 2, [0 140], 1, 1, 1, cmap_viridis, 0);   %%%------- try other maps, like rainbow
fmri_showslices(D, 1, 2, [0 140], 1, 1, 1, jet, 0);   %%%------- try other maps, like rainbow
fmri_showslices(D, 1, 2, [0 140], 1, 1, 1, hsv, 0);   %%%------- try other maps, like rainbow
fmri_showslices(D, 1, 2, [0 140], 1, 1, 1, parula, 0);   %%%------- try other maps, like rainbow


%% 18. A subcortical atlas inside a three-quarter brain
% -------------------------------------------------------------------------
% The atlas names each structure twice, 'Left Thalamus' and 'Right Thalamus',
% which doubles the legend and gives the two sides different colours. Dropping
% the side word and grouping on what remains gives one colour per structure.
%
% And CROP in fmri_show3d cuts the brain shell and the data together, so a
% plain bounding box would slice the structures along with the cortex. A mask
% separates the two: take a quarter off the shell, then put the structure
% voxels back.

% Load the Harvard-Oxford subcortical atlas.
%   nos   = a number for each voxel, saying which structure it belongs to
%   names = the name of each structure
[nos, names] = fmri_loadatlas(2);          % Harvard-Oxford subcortical

% Skip structures that are big solid blobs (cortex, white matter, ventricles),
% because they would hide everything inside them.
keep = find(~contains(names, {'Cortex','White Matter','Ventric'}));

% The atlas has separate "Left X" and "Right X" labels.
% Remove the "Left "/"Right " prefix so both sides share one name.
short = regexprep(names(keep), '^(Left|Right)\s+', '');

% Get each structure name once (left and right together).
structures = unique(short, 'stable');

% Build one map (column) per structure.
% A voxel is 1 if it belongs to that structure on either side.
maps = zeros(numel(nos), numel(structures));
for k = 1:numel(structures)
    both = keep(strcmp(short, structures{k}));   % left and right together
    maps(:,k) = double(ismember(nos, both));
end
fprintf('%d structures from %d atlas labels: %s\n', ...
        numel(structures), numel(names), strjoin(structures', ', '));

% Make a solid brain shell, then cut one quarter away.
shell = ones(91,109,91);
shell(1:45, 55:109, 46:91) = 0;                   % cut one quarter away
shell(fmri_vect2vol(any(maps,2)) > 0) = 1;        % but never cut a structure

% Draw it.
figure('Name','18. Subcortical structures inside a three-quarter brain');
fmri_show3d(maps, 140, 15, 0.5, 0.95, fmri_distinctcolors(numel(structures)), ...
            0.08, fmri_vol2vect(shell), [], structures);
