% DEMO_VOXDIST  Euclidean distance between brain voxels
%
% Demonstrates fmri_voxdist by computing:
%   1. Distance between two MNI coordinates
%   2. Distance from a seed voxel to all brain voxels (distance map)
%   3. Pairwise distances within an atlas ROI
%
% Functions demonstrated:
%   fmri_voxdist, fmri_mni2sub, fmri_sub2ind, fmri_regionmask, fmri_showslices
%
% See also: fmri_voxdist, fmri_spheremask, fmri_regionmask, fmri_mni2sub

fmritoolbox_setup;

% Voxel count is taken from the template rather than hardcoded, so the demo
% survives any change of reference space.
load standard_brain % supplies br, the 91x109x91 binary brain mask
n_voxels = nnz(br);

%% --- 1. Distance between two MNI coordinates -----------------------------
mni1 = [0  -51  27];    % posterior cingulate cortex (PCC)
mni2 = [46  20   8];    % right inferior frontal gyrus

sub1 = fmri_mni2sub(mni1);
sub2 = fmri_mni2sub(mni2);

ind1 = fmri_sub2ind(sub1);
ind2 = fmri_sub2ind(sub2);

d = fmri_voxdist(ind1, ind2);
fprintf('Distance between PCC and rIFG: %.1f mm\n', d);

%% --- 2. Distance map from seed to all brain voxels -----------------------
fprintf('Computing distance map from PCC seed...\n');
D = fmri_voxdist(ind1, 1:n_voxels);   % 1 x n_voxels

% THRESHOLD = 0 draws every FINITE voxel, including the seed itself at distance
% 0. A positive threshold would hide the seed and its immediate neighbourhood,
% which is the most informative part of a distance map. This is the case the
% THRESHOLD == 0 rule exists for: zero is a real measurement here, not padding.
figure('Name', 'Distance map from PCC');
fmri_showslices(D', 1, 2, [0 100], [], [], 1, 'hot', 0);
title('Distance from PCC [0 -51 27] (mm)');

%% --- 3. Pairwise distances within left hippocampus -----------------------
% Region name comes from the atlas rather than a hardcoded comment, so the
% label cannot drift out of step with the atlas numbering.
[mask, roi_name] = fmri_regionmask(57, 1);   % AAL
cluster_inds     = find(mask);

fprintf('Computing pairwise distances within %s (%d voxels)...\n', ...
        roi_name{1}, numel(cluster_inds));

D_roi    = fmri_voxdist(cluster_inds);       % NxN pairwise distance matrix
max_diam = max(D_roi(:));
mean_d   = mean(D_roi(D_roi > 0));

fprintf('  %s max diameter: %.1f mm\n', roi_name{1}, max_diam);
fprintf('  Mean inter-voxel distance:  %.1f mm\n', mean_d);

% Sanity check against the distance map: the seed-to-seed distance must be 0
% and the map's maximum must not exceed the brain's own diagonal extent.
fprintf('  Seed-to-seed distance:      %.1f mm (expect 0)\n', fmri_voxdist(ind1, ind1));
fprintf('  Max distance from seed:     %.1f mm\n', max(D));

figure('Name', 'Pairwise distance matrix');
imagesc(D_roi);
colorbar;
title(sprintf('Pairwise distances within %s (max = %.1f mm)', roi_name{1}, max_diam));
xlabel('Voxel index'); ylabel('Voxel index');
axis square;


  