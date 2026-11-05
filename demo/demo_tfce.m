% DEMO_TFCE  Threshold-free cluster enhancement of a statistical map
%
% Demonstrates fmri_tfce on a simulated z-map whose clusters have IDENTICAL
% height but very different spatial extent. TFCE rewards extent, so the large
% cluster scores higher than the small one even though no voxel in either is
% more significant than the other. The demo shows this spatially (the maps) and
% quantitatively (the scatter plots).
%
% A negative cluster is included so the two-tailed workflow is shown rather
% than described: fmri_tfce takes a one-sided input, so a signed map must be
% run once per tail and recombined.
%
% READING THE MAPS. TFCE does not move cluster boundaries and does not smooth -
% it reweights each voxel by the extent of the cluster it belongs to,
% integrated over thresholds. Each blob therefore occupies the SAME shape in
% the z-map and in both TFCE maps; what changes is the scale. In steps 2-5
% every voxel in a blob has the same height, so every voxel in it scores almost
% the same and each blob looks flat. The informative comparison there is
% BETWEEN blobs. Step 6 repeats the exercise with graded blobs, where the TFCE
% map does look different from the z-map.
%
% Steps:
%   1. Planted cluster layout                              (1 figure)
%   2. Simulated z-map                                     (1 figure)
%   3. TFCE, positive tail                                 (1 figure)
%   4. TFCE, both tails recombined into a signed map       (1 figure)
%   5. Raw z vs TFCE score, per cluster                    (1 figure)
%      followed by the printed summary and the theoretical check
%   6. Graded clusters, the realistic case                 (3 figures)
%
% Functions demonstrated:
%   fmri_tfce, fmri_loadatlas, fmri_ind2sub, fmri_voxdist, fmri_showslices
%
% Note on inference: TFCE scores are NOT p-values and are not interpretable on
% their own scale. Converting them to corrected p-values requires a permutation
% null - see fmri_csdist and fmri_csthreshold. This demo stops at the
% enhancement step.
%
% References:
%   Smith & Nichols (2009). NeuroImage, 44(1), 83-98.
%
% See also: fmri_tfce, fmri_csdist, fmri_csthreshold

fmritoolbox_setup;

rng(42, 'twister');   % reproducible: the printed summary is stable across runs

%% --- Step 1: pick the three clusters, by measured size --------------------
% Three atlas regions stand in for clusters: a large one, one about a quarter
% its size, and a third of middling size for the negative blob.
%
% They are chosen by MEASURING the atlas rather than by hard-coding region
% numbers, because atlas numbering does not follow region size - assuming
% "region 1 is the large one" can silently invert the demo's message. Only
% regions that actually have voxels inside the brain mask are eligible: some
% atlases label regions that fall entirely outside it, and picking one of those
% would give a blob with no voxels at all. The atlas is loaded once and indexed,
% which is far cheaper than calling fmri_regionmask per region.
atlas_no = 1;                                    % 1 = AAL
[roi_map, roi_labels] = fmri_loadatlas(atlas_no);

% Only regions with voxels inside the mask are eligible: some atlases label
% regions that fall entirely outside it, and picking one would give an empty
% blob. All three selections draw from `present`, never from 1:n_reg.
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

% fmri_loadatlas returns the labels as a cell array, hence the braces.
name_large = roi_labels{idx_large};
name_small = roi_labels{idx_small};
name_neg   = roi_labels{idx_neg};

fprintf('\n--- Planted clusters (regions chosen by measured size) ---\n');
fprintf('Large positive : %-40s %6d voxels\n', name_large, nnz(mask_large));
fprintf('Small positive : %-40s %6d voxels\n', name_small, nnz(mask_small));
fprintf('Negative       : %-40s %6d voxels\n', name_neg,   nnz(mask_neg));

% Guard the demo's premise, so the figures cannot disagree with the narrative.
assert(nnz(mask_large) > 2*nnz(mask_small), ...
    'demo_tfce: atlas %d gives no substantial size contrast here.', atlas_no);

% Show where the signal will be planted, before any statistics exist, so you
% know what the later maps should contain. The values drawn here are just
% CATEGORY CODES - labels for "large", "small", "negative" - not statistics,
% which is why this figure's colourbar reads -2 to 2 and the later ones do not.
layout = zeros(size(roi_map));
layout(mask_large) =  2;
layout(mask_small) =  1;
layout(mask_neg)   = -2;

figure('Name', 'Step 1: planted cluster layout');
fmri_showslices(layout, 1, 2, [-2 2], [], [], 1, [], 0.5);
title('Planted clusters (category codes, not z): large +, small +, negative -');

%% --- Step 2: simulate a z-map --------------------------------------------
% Both positive clusters get the SAME mean height. Any difference in their
% TFCE scores is therefore attributable to extent alone, not to height.
z_height = 3.5;
z_noise  = 0.5;

zmap = zeros(size(roi_map));
zmap(mask_large) =  z_height + z_noise*randn(nnz(mask_large), 1);
zmap(mask_small) =  z_height + z_noise*randn(nnz(mask_small), 1);
zmap(mask_neg)   = -z_height + z_noise*randn(nnz(mask_neg),   1);

% CLIMITS(1) must sit strictly BELOW THRESHOLD. fmri_showslices clamps data
% into CLIMITS before building the display mask, so if the two are equal every
% sub-threshold voxel is clamped up to the threshold, passes the test, and the
% whole brain is painted. Symmetric limits satisfy this and put grey at zero.
z_lim = max(abs(zmap));
z_thr = 2;

figure('Name', 'Step 2: simulated z-map');
fmri_showslices(zmap, 1, 2, [-z_lim z_lim], [], [], 1, [], z_thr);
title(sprintf('Simulated z-map (|z| >= %g shown; positive clusters same height)', z_thr));

%% --- Step 3: TFCE, positive tail -----------------------------------------
% fmri_tfce expects a one-sided, non-negative input, so each tail is run
% separately on a rectified copy of the map. E is the extent exponent; it is
% passed explicitly so that the theoretical check at the end uses the same
% value the computation did. The height exponent and the number of threshold
% bins keep their defaults (2 and 50).
E = 0.5;
fprintf('\nComputing TFCE (positive tail)...\n');
tfce_pos = fmri_tfce(max(zmap, 0), E);

% TFCE has no conventional display threshold, because its units are not
% interpretable; a small fraction of the map maximum is used purely to hide the
% exact-zero background. The map is strictly positive, so a sequential colormap
% suits it better than the default diverging one.
tfce_max = max(tfce_pos);
tfce_thr = 0.01 * tfce_max;

figure('Name', 'Step 3: TFCE, positive tail');
fmri_showslices(tfce_pos, 1, 2, [0 tfce_max], [], [], 1, 'hot', tfce_thr);
title('TFCE score, positive tail (large cluster boosted over small)');

%% --- Step 4: TFCE, both tails --------------------------------------------
fprintf('Computing TFCE (negative tail)...\n');
tfce_neg = fmri_tfce(max(-zmap, 0), E);

% Recombine into a signed map. This is what you would carry into permutation
% testing for a two-tailed contrast, and being signed it suits the default
% diverging colormap.
tfce_signed = tfce_pos - tfce_neg;
t_lim = max(abs(tfce_signed));

figure('Name', 'Step 4: TFCE, both tails recombined');
fmri_showslices(tfce_signed, 1, 2, [-t_lim t_lim], [], [], 1, [], 0.01*t_lim);
title('Signed TFCE (positive tail minus negative tail)');

%% --- Step 5: the same raw z, a different score ---------------------------
% Each dot is one voxel. Its horizontal position is the evidence AT that voxel
% (its raw z); its vertical position is the score TFCE gives it. The two clouds
% overlap almost completely from side to side - the voxels in both regions are
% equally significant on their own - but the large region's cloud sits higher.
% So two voxels carrying identical evidence receive different scores, decided
% by how much surrounding tissue is also active. That is the conceptual point,
% and it cannot be seen in the brain maps.
%
% The flat horizontal bands are expected, not an artefact. fmri_tfce adds up its
% integral over a fixed number of thresholds (50 by default), so any two voxels
% whose z falls between the same pair of thresholds survive exactly the same set
% of them and end up with the same score. More thresholds would give smoother
% bands, at proportionally more computation.
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
title('Same raw z, different TFCE score');   % kept short: long titles clip
legend('Location', 'northwest');
grid on;
% Shared x range with the step 6 scatter so the two are directly comparable.
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

% What the ratio SHOULD be, worked out in advance. When a cluster has uniform
% height z0 and extent A, every voxel in it belongs to that same cluster at
% every threshold below z0, so the integral evaluates in closed form:
%
%     TFCE = A^E * z0^(H+1) / (H+1)
%
% The height term is identical for the two clusters here, so it cancels in the
% ratio and only extent survives: TFCE_ratio = (A_large/A_small)^E. Printing the
% prediction next to the measurement is how you confirm what E is doing.
predicted = (nnz(mask_large) / nnz(mask_small))^E;
fprintf('Predicted from theory         : %6.2f   <- size_ratio^E, E = %.1f\n', ...
    predicted, E);

fprintf(['\nTFCE boosts the larger cluster despite near-identical raw ' ...
    'z-values.\nNote the enhancement is SUB-LINEAR in extent: E = 0.5 means ' ...
    'a 4x larger\ncluster earns roughly a 2x higher score, not 4x.\n' ...
    'To turn these scores into corrected p-values, build a permutation null\n' ...
    '(see fmri_csdist / fmri_csthreshold).\n']);

%% --- Step 6: graded clusters, the realistic case --------------------------
% Real activations peak somewhere and fade toward the edges. With a graded
% blob, a voxel near the middle survives to high thresholds while an edge voxel
% drops out early, so the two accumulate very different integrals - and the
% TFCE map shows a centre-to-edge gradient that the uniform case cannot produce.
fprintf('\nStep 6: graded clusters...\n');

% Graded profile: for each blob, take the voxel nearest its own centroid, then
% fall off with distance from there - 1 at that voxel, 0 at the furthest rim.
% Crude on purpose, since the step needs a visible gradient rather than an
% exact geometric one, and built from fmri_ind2sub and fmri_voxdist so the demo
% needs no helper function of its own.
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

% Separate figures, not subplots: several toolbox viewers call clf on the
% current figure, so nesting them in subplot panels wipes earlier panels.
figure('Name', 'Step 6a: graded z-map');
fmri_showslices(zg, 1, 2, [0 zg_lim], [], [], 1, 'hot', z_thr);
title('Graded z-map: peaks inside the blobs, fades at the edges');

figure('Name', 'Step 6b: TFCE of the graded map');
fmri_showslices(tfce_g, 1, 2, [0 tg_max], [], [], 1, 'hot', 0.01*tg_max);
title('TFCE of the graded map: centre-to-edge gradient, not a flat blob');

% The scatter now spreads vertically WITHIN each cluster, because voxels at
% different depths inside the same blob survive to different thresholds.
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

fprintf(['\nCompare the two scatters: the uniform case (step 5) gives tight ' ...
    'bands,\nthe graded case (step 6) gives a spread, because voxels at ' ...
    'different depths\ninside one blob accumulate different integrals.\n']);
