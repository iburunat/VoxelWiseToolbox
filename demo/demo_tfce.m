%% DEMO_TFCE  Threshold-free cluster enhancement of a statistical map.
%
% Demonstrates how TFCE combines signal height with spatial extent. Two
% positive clusters are generated with the same mean z-value but different
% sizes, allowing the effect of cluster extent to be seen directly.
%
% A negative cluster illustrates the two-tailed workflow: apply fmri_tfce
% separately to the positive and negative tails, then recombine the results
% into a signed TFCE map.
%
% The final example uses graded clusters whose signal decreases toward the
% edges. This shows how TFCE varies both between clusters and within them.
%
% Steps:
%   1. Define clusters with different spatial extents
%   2. Generate a signed z-map
%   3. Apply TFCE to the positive tail
%   4. Recombine positive and negative TFCE maps
%   5. Compare raw z-values with TFCE scores
%   6. Repeat with graded, more realistic clusters
%
% TFCE scores are enhancement statistics, not p-values. Statistical inference
% requires a permutation null based on the maximum TFCE statistic; this demo
% covers only the enhancement step.
%
% Functions demonstrated:
%   fmri_tfce, fmri_loadatlas, fmri_ind2sub, fmri_voxdist, fmri_showslices
%
% References:
%   Smith & Nichols (2009). NeuroImage, 44(1), 83-98.
%
% See also: fmri_tfce, fmri_scramblephases

clear; close all;
if exist('fmritoolbox_setup', 'file')
    fmritoolbox_setup;
else
    error('Please run fmritoolbox_setup.m from the toolbox root first.');
end
fprintf('=== VoxelWise Toolbox TFCE demo ===\n\n');

rng(42, 'twister');   % reproducible: the printed summary is stable across runs

%% --- Step 1: pick the three clusters, by measured size --------------------
% Choose three AAL regions by measured voxel count: large and small positive
% clusters and a medium-sized negative cluster. This keeps the intended size
% contrast independent of atlas numbering.
atlas_no = 1;                                    % 1 = AAL
[roi_map, roi_labels] = fmri_loadatlas(atlas_no);

% Restrict selection to regions containing voxels inside the brain mask.
reg_sizes = accumarray(roi_map(roi_map > 0), 1);
present   = find(reg_sizes > 0);                 % regions inside the mask

% Large cluster: the biggest region present.
[~, pick]  = max(reg_sizes(present));
idx_large  = present(pick);

% Small cluster: present region closest to a quarter of that size.
others       = setdiff(present, idx_large);
target_small = reg_sizes(idx_large) / 4;
[~, pick]    = min(abs(reg_sizes(others) - target_small));
idx_small    = others(pick);

% Negative cluster: a third distinct region, of middling size.
others2   = setdiff(others, idx_small);
[~, pick] = min(abs(reg_sizes(others2) - median(reg_sizes(others2))));
idx_neg   = others2(pick);

mask_large = roi_map == idx_large;
mask_small = roi_map == idx_small;
mask_neg   = roi_map == idx_neg;

% Retrieve the corresponding region names.
name_large = roi_labels{idx_large};
name_small = roi_labels{idx_small};
name_neg   = roi_labels{idx_neg};

fprintf('\n--- Planted clusters (regions chosen by measured size) ---\n');
fprintf('Large positive : %-40s %6d voxels\n', name_large, nnz(mask_large));
fprintf('Small positive : %-40s %6d voxels\n', name_small, nnz(mask_small));
fprintf('Negative       : %-40s %6d voxels\n', name_neg,   nnz(mask_neg));

% Confirm that the selected regions provide a clear size contrast.
assert(nnz(mask_large) > 2*nnz(mask_small), ...
    'demo_tfce: atlas %d gives no substantial size contrast here.', atlas_no);

% Display the planted locations before generating the z-map. The values are
% category codes for the three clusters, not statistical values.
layout = zeros(size(roi_map));
layout(mask_large) =  2;
layout(mask_small) =  1;
layout(mask_neg)   = -2;

figure('Name', 'Step 1: planted cluster layout');
fmri_showslices(layout, 1, 2, [-2 2], [], [], 1, [], 0.5);
title('Planted clusters (category codes, not z): large +, small +, negative -');

%% --- Step 2: simulate a z-map --------------------------------------------
% Give both positive clusters the same expected z-value. Their voxelwise
% values differ only because of the added noise.
z_height = 3.5;
z_noise  = 0.5;

zmap = zeros(size(roi_map));
zmap(mask_large) =  z_height + z_noise*randn(nnz(mask_large), 1);
zmap(mask_small) =  z_height + z_noise*randn(nnz(mask_small), 1);
zmap(mask_neg)   = -z_height + z_noise*randn(nnz(mask_neg),   1);

% Use symmetric colour limits and display voxels with |z| >= 2.
z_lim = max(abs(zmap));
z_thr = 2;

figure('Name', 'Step 2: simulated z-map');
fmri_showslices(zmap, 1, 2, [-z_lim z_lim], [], [], 1, [], z_thr);
title(sprintf('Simulated z-map (|z| >= %g; same expected height)', z_thr));

%% --- Step 3: TFCE, positive tail -----------------------------------------
% fmri_tfce accepts non-negative input, so analyse each tail separately.
% E controls the contribution of cluster extent; H and the number of threshold
% bins retain their defaults of 2 and 50.
E = 0.5;
fprintf('\nComputing TFCE (positive tail)...\n');
tfce_pos = fmri_tfce(max(zmap, 0), E);

% Hide weak scores for readability; this display threshold has no inferential
% meaning. Use a sequential colormap for the positive map.
tfce_max = max(tfce_pos);
tfce_thr = 0.01 * tfce_max;

figure('Name', 'Step 3: TFCE, positive tail');
fmri_showslices(tfce_pos, 1, 2, [0 tfce_max], [], [], 1, 'hot', tfce_thr);
title('TFCE score, positive tail (large cluster boosted over small)');

%% --- Step 4: TFCE, both tails --------------------------------------------
fprintf('Computing TFCE (negative tail)...\n');
tfce_neg = fmri_tfce(max(-zmap, 0), E);

% Subtract the negative-tail scores from the positive-tail scores to obtain a
% signed TFCE map. Display it with symmetric limits and a diverging colormap.
tfce_signed = tfce_pos - tfce_neg;
t_lim = max(abs(tfce_signed));

figure('Name', 'Step 4: TFCE, both tails recombined');
fmri_showslices(tfce_signed, 1, 2, [-t_lim t_lim], [], [], 1, [], 0.01*t_lim);
title('Signed TFCE (positive tail minus negative tail)');

%% --- Step 5: the same raw z, a different score ---------------------------
% The clusters have similar raw z-values, but the larger cluster receives
% higher TFCE scores because of its greater extent.
figure('Name', 'Step 5: raw z vs TFCE score');
hold on;
scatter(zmap(mask_large), tfce_pos(mask_large), 8, 'filled', ...
    'MarkerFaceAlpha', 0.3, ...
    'DisplayName', sprintf('%s (%d vox)', name_large, nnz(mask_large)));
scatter(zmap(mask_small), tfce_pos(mask_small), 8, 'filled', ...
    'MarkerFaceAlpha', 0.6, ...
    'DisplayName', sprintf('%s (%d vox)', name_small, nnz(mask_small)));
hold off;
xlabel('Raw z-value');
ylabel('TFCE score');
title('Same raw z, different TFCE score');
legend('Location', 'northwest');
grid on;
% Reuse this x range in Step 6 for direct comparison.
scatter_xlim = [0 max(zmap(:))*1.05];
xlim(scatter_xlim);

%% --- Summary statistics --------------------------------------------------
mean_z_large    = mean(zmap(mask_large));
mean_z_small    = mean(zmap(mask_small));
mean_tfce_large = mean(tfce_pos(mask_large));
mean_tfce_small = mean(tfce_pos(mask_small));

fprintf('\n--- TFCE summary ---\n');
fprintf('%-16s %10s %10s %10s\n', '', 'voxels', 'mean z', 'mean TFCE');
fprintf('%-16s %10d %10.2f %10.2f\n', 'Large cluster', ...
    nnz(mask_large), mean_z_large, mean_tfce_large);
fprintf('%-16s %10d %10.2f %10.2f\n', 'Small cluster', ...
    nnz(mask_small), mean_z_small, mean_tfce_small);
fprintf('\nSize ratio (large/small)      : %6.2f\n', ...
    nnz(mask_large) / nnz(mask_small));
fprintf('Raw z ratio (large/small)     : %6.2f   <- near 1: same height\n', ...
    mean_z_large / mean_z_small);
fprintf('TFCE ratio (large/small)      : %6.2f   <- the enhancement\n', ...
    mean_tfce_large / mean_tfce_small);

% For ideal clusters with identical uniform height, the expected score ratio is:
%
%     TFCE_large / TFCE_small = (A_large / A_small)^E
%
% The simulated clusters contain noise, so the measured ratio should be close
% to, but not necessarily identical to, this prediction.
predicted = (nnz(mask_large) / nnz(mask_small))^E;
fprintf('Idealised extent prediction  : %6.2f   <- size_ratio^E, E = %.1f\n', ...
        predicted, E);

fprintf(['\nThe larger cluster is enhanced more despite the same mean z. ' ...
    'TFCE scores\nare not p-values: inference needs a permutation null of ' ...
    'the maximum score.\n']);
%% --- Step 6: graded clusters ----------------------------------------------
% Real signals usually peak near a cluster centre and weaken toward its edges.
% In a graded cluster, central voxels survive more thresholds and therefore
% receive higher TFCE scores than boundary voxels.
fprintf('\nStep 6: graded clusters...\n');

% Create a centre-to-edge profile within each positive region and add noise.
% The voxel nearest the region centroid defines the peak.
zg = zeros(size(roi_map));
for m = {mask_large, mask_small}
    mask     = m{1};
    inds     = find(mask);
    sub      = fmri_ind2sub(inds);
    [~, c]   = min(sum((sub - mean(sub, 1)).^2, 2));
    d        = fmri_voxdist(inds(c), inds);
    zg(mask) = z_height * (1 - d(:)/max(d)) + z_noise*randn(numel(inds), 1);
end

fprintf('Computing TFCE on graded clusters...\n');
tfce_g = fmri_tfce(max(zg, 0), E);

zg_lim   = max(abs(zg));
tg_max   = max(tfce_g);

% Use separate figures because the toolbox slice viewer clears the figure.
figure('Name', 'Step 6a: graded z-map');
fmri_showslices(zg, 1, 2, [0 zg_lim], [], [], 1, 'hot', z_thr);
title('Graded z-map: centre-to-edge signal');

figure('Name', 'Step 6b: TFCE of the graded map');
fmri_showslices(tfce_g, 1, 2, [0 tg_max], [], [], 1, 'hot', 0.01*tg_max);
title('TFCE of the graded map');

% Graded signal produces a wider range of TFCE scores within each cluster.
figure('Name', 'Step 6: graded raw z vs TFCE');
hold on;
scatter(zg(mask_large), tfce_g(mask_large), 8, 'filled', 'MarkerFaceAlpha', 0.3, ...
    'DisplayName', sprintf('%s (%d vox)', name_large, nnz(mask_large)));
scatter(zg(mask_small), tfce_g(mask_small), 8, 'filled', 'MarkerFaceAlpha', 0.6, ...
    'DisplayName', sprintf('%s (%d vox)', name_small, nnz(mask_small)));
hold off;
xlabel('Raw z-value'); ylabel('TFCE score');
title('Graded clusters: spread within each blob');
legend('Location','northwest'); grid on;
xlim(scatter_xlim);   % same x range as step 5, so the two are comparable

fprintf(['\nUniform clusters produce tight TFCE bands, whereas graded clusters ' ...
    'produce\na wider score range because their voxels survive different ' ...
    'numbers of thresholds.\n']);

fprintf('\n=== TFCE demo complete ===\n');