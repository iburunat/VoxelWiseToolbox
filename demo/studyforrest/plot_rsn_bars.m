function plot_rsn_bars(r_group, atlas_path)
% PLOT_RSN_BARS  Bar chart of resting-state network correspondence.
%
% Produces the figure panel for Section 6.3: how strongly the group correlation
% map resembles each of the ten canonical resting-state networks of Smith et al.
% (2009). The auditory network should rank first for an acoustic regressor,
% which makes this a positive control that does not depend on any threshold.
%
% Usage:
%   plot_rsn_bars(r_group)
%   plot_rsn_bars(r_group, '/path/to/restingstatenets.mat')
%
% Inputs:
%   R_GROUP    - Group correlation map, 228453 x 1, as produced by
%                demo_studyforrest.
%   ATLAS_PATH - Optional path to restingstatenets.mat. Defaults to the copy
%                bundled in atlases/.
%
% WHAT IS PLOTTED
%   The bars show the correlation between each network template and the
%   positive part of the group map (negative values set to zero), matching
%   rsn_compare_demo. Zero and non-finite voxels are excluded, so the values
%   match its output exactly.
%
% See also: rsn_compare_demo, fmri_corrmat, demo_studyforrest

FS = 8;            % point size on the printed page: this panel is rendered
                   % at its final 11.6 cm width, so the number is literal

if nargin < 2 || isempty(atlas_path)
    atlas_path = fullfile(fileparts(which('fmritoolbox_setup')), ...
                      'atlases', 'restingstatenets.mat');
end
S = load(atlas_path);
if ~isfield(S, 'nets') || ~isfield(S, 'netname')
    error('plot_rsn_bars:badAtlas', ...
        ['%s must contain the variables ''nets'' and ''netname''.\n' ...
         'This is the file rsn_compare_demo loads.'], atlas_path);
end
nets    = S.nets;
netname = S.netname;

if size(nets, 1) ~= numel(r_group)
    error('plot_rsn_bars:sizeMismatch', ...
        ['Network templates have %d voxels but R_GROUP has %d.\n' ...
         'Both must be on the toolbox 228453-voxel grid.'], ...
        size(nets, 1), numel(r_group));
end

%% --- the same computation rsn_compare_demo performs ------------------------
valid = isfinite(r_group) & r_group ~= 0;
r_pos = r_group;  r_pos(r_pos < 0) = 0;

nNet = size(nets, 2);
r    = zeros(nNet, 1);
for k = 1:nNet
    net  = nets(:, k);
    c    = corrcoef(r_pos(valid), net(valid));
    r(k) = c(1,2);
end

%% --- tidy the names --------------------------------------------------------
lab = cell(nNet, 1);
for k = 1:nNet
    s = char(netname{k});
    s = regexprep(s, '\.nii(\.gz)?$', '');
    s = regexprep(s, '^r', '');
    s = strrep(s, '_', ' ');
    lab{k} = s;
end
% Visual network numbering follows Smith et al. (2009): vis_one is MEDIAL,
% vis_two is OCCIPITAL POLE, vis_three is LATERAL. The bundled templates are the
% same maps as the published set, in a different file order, so the numbering
% must be read from the names.
pretty = containers.Map( ...
  {'auditory','vis one','vis two','vis three','DMN','sensorimotor', ...
   'exec contr','frontoparietal one','frontoparietal two','cerebellum'}, ...
  {'Auditory','Visual (medial)','Visual (occipital pole)','Visual (lateral)', ...
   'Default mode','Sensorimotor','Executive control', ...
   'Frontoparietal (L)','Frontoparietal (R)','Cerebellum'});
for k = 1:nNet
    if isKey(pretty, lab{k}), lab{k} = pretty(lab{k}); end
end

% Rank by |r|, rounded to the two decimals
[~, ord] = sortrows([-round(abs(r), 2), -r]);
r_sorted   = r(ord);
lab_sorted = lab(ord);


%% --- plot ------------------------------------------------------------------
figure('Name', 'Resting-state network correspondence', ...
       'Color', 'w', 'Position', [100 100 620 400]);

b = barh(flipud(r_sorted), 0.7);
b.FaceColor = 'flat';
% Highlight the top-ranked network. It is the positive control, and colour
% carries that without needing a sentence in the caption.
cols = repmat([0.55 0.60 0.66], nNet, 1);
cols(end, :) = [0.78 0.24 0.20];
b.CData = cols;
b.EdgeColor = 'none';

set(gca, 'YTick', 1:nNet, 'YTickLabel', flipud(lab_sorted), ...
         'YLim', [0.4, nNet + 0.6], 'FontSize', FS, 'Box', 'off', ...
         'TickDir', 'out', 'YColor', [0.3 0.3 0.3]);
xlabel('Spatial correlation with the group map', 'FontSize', FS);

% set(gca, 'YTick', 1:nNet, 'YTickLabel', flipud(lab_sorted), ...
%          'FontSize', 10, 'Box', 'off', 'TickDir', 'out', 'YColor', [0.3 0.3 0.3]);
% xlabel('Spatial correlation with the group map', 'FontSize', 10);

xline(0, 'Color', [0.6 0.6 0.6]);
%xlim([min(0, min(r)) - 0.03, max(r) + 0.06]);
xlim([-0.24 0.40]);
set(gca, 'XTick', -0.2:0.1:0.4);
% Value labels, placed outside each bar so they never overlap it.
for k = 1:nNet
    v = r_sorted(nNet - k + 1);
    if v >= 0
        text(v + 0.008, k, sprintf('%.2f', v), 'FontSize', FS - 1, ...
             'VerticalAlignment', 'middle', 'Color', [0.25 0.25 0.25]);
    else
        text(v - 0.008, k, sprintf('%.2f', v), 'FontSize', FS - 1, 'HorizontalAlignment', 'right', ...
             'VerticalAlignment', 'middle', 'Color', [0.25 0.25 0.25]);
    end
end
set(gca, 'Layer', 'top');

fprintf('\nResting-state network correspondence (positive half-map):\n');
for k = 1:nNet
    fprintf('  %-26s %+.3f\n', lab_sorted{k}, r_sorted(k));
end
fprintf(['\nCheck these against the "Networks INCREASING" block printed by\n' ...
         'rsn_compare_demo - they are the same quantity and should match.\n']);
end