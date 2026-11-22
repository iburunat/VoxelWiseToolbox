function make_figure5(t_map, mask_unc, mask_corr, r_group, t_crit_disp, df, outdir)
% make_figure5  Generates the component images for the Section 6 figure.
%
% Usage, with demo_studyforrest's variables in scope:
%   make_figure5(t_map, mask_unc, mask_corr, r_group, t_crit_disp, df_group)
%   make_figure5(t_map, mask_unc, mask_corr, r_group, t_crit_disp, df_group, '~/fig5')
%
% Inputs:
%   t_map       228453 x 1  group t statistic
%   mask_unc    228453 x 1  logical, suprathreshold before cluster correction
%   mask_corr   228453 x 1  logical, surviving cluster-extent correction
%   r_group     228453 x 1  group correlation map; plot_rsn_bars computes the
%                           network correspondence from it
%   t_crit_disp 1 x 1       critical t at the cluster-forming threshold
%   df          1 x 1       group degrees of freedom (N - 1); printed in the
%                           caption summary only
%   outdir      char        output folder (default: pwd)
%
% Writes three PNGs, to be assembled into a two-panel figure:
%
%   fig5_A_glass.png    A: cluster-corrected result, glass brain
%   fig5_A_slices.png   A: cluster-corrected result, selected axial slices
%   fig5_B_networks.png B: resting-state network correspondence
%
% Only the corrected map is shown; MASK_UNC is used for summary statistics.
%
% See also: fmri_juicyslices, fmri_divmap, fmri_showselectslices, fmri_show3d,
%           plot_rsn_bars, demo_studyforrest

if nargin < 6
    error('make_figure5:tooFewInputs', ...
          ['T_MAP, MASK_UNC, MASK_CORR, R_GROUP, T_CRIT_DISP and DF are all ', ...
           'required. Call it with demo_studyforrest''s variables in ', ...
           'scope, or after loading that run''s saved output.']);
end
if nargin < 7 || isempty(outdir), outdir = pwd; end
if ~isfolder(outdir), mkdir(outdir); end

NVOX = 228453;
if numel(t_map)     ~= NVOX || numel(mask_unc) ~= NVOX || ...
   numel(mask_corr) ~= NVOX || numel(r_group)  ~= NVOX
    error('make_figure5:badSize', ...
        ['All four inputs must be %d x 1 (the in-brain voxel vector).\n' ...
         'Got T_MAP %d, MASK_UNC %d, MASK_CORR %d, R_GROUP %d.\n' ...
         'R_GROUP is the full voxel map from demo_studyforrest, not a ' ...
         'per-network summary.'], ...
        NVOX, numel(t_map), numel(mask_unc), numel(mask_corr), numel(r_group));
end

mask_unc  = logical(mask_unc(:));
mask_corr = logical(mask_corr(:));
t_map     = t_map(:);

t_lim = round(2 * t_crit_disp, 2);   

cmap = fmri_divmap(256);
glass_colors =  [1 0 0; 0 0 1];

% Choose slices from the corrected map so each panel contains surviving signal.
% Use MINSEP = 3 because the effect occupies a narrow axial range.
t_corr = t_map;
t_corr(~mask_corr) = NaN;
sl = fmri_juicyslices(t_corr, 'axial', 6, t_crit_disp, 3);
fprintf('Slices selected from the corrected map: %s\n', mat2str(sl));

%% --- A: clusters surviving correction --------------------------------------
figure('Name', 'fig5 A glass', 'Color', 'w', 'Position', [60 60 520 460]);
fmri_show3d([double(mask_corr & t_map > 0), double(mask_corr & t_map < 0)], ...
            26, 7, 0.5, 0.85, glass_colors, 0.06);
local_save(gcf, outdir, 'fig5_A_glass');              % auto: no text in it

figure('Name', 'fig5 A slices', 'Color', 'w');
fmri_showselectslices(t_corr, sl, [-t_lim t_lim], 1, 1, 1, cmap, 0);
local_save(gcf, outdir, 'fig5_A_slices');             % auto: the viewer sizes it


%% --- B: resting-state network correspondence -------------------------------
plot_rsn_bars(r_group);
local_save(gcf, outdir, 'fig5_B_networks', 11.6, 7.48);
%% --- numbers for the caption -----------------------------------------------
fprintf('\n--- for the caption ---\n');
fprintf('  voxel threshold        : |t| >= %.2f (p < 0.001, df = %d)\n', ...
        t_crit_disp, df);
fprintf('  colour limits          : [%.2f %.2f]\n', -t_lim, t_lim);
fprintf('  suprathreshold         : %d voxels (%d pos, %d neg)\n', ...
        nnz(mask_unc), nnz(mask_unc & t_map > 0), nnz(mask_unc & t_map < 0));
fprintf('  surviving correction   : %d voxels (%d pos, %d neg)\n', ...
        nnz(mask_corr), nnz(mask_corr & t_map > 0), nnz(mask_corr & t_map < 0));
fprintf('  removed by correction  : %d voxels (%.0f%%)\n', ...
        nnz(mask_unc & ~mask_corr), ...
        100 * nnz(mask_unc & ~mask_corr) / max(nnz(mask_unc), 1));
fprintf('  slices shown           : z = %s\n', ...
        strjoin(arrayfun(@(v) sprintf('%d', v), sl, 'UniformOutput', false), ', '));
fprintf('\nWrote three PNGs to %s\n', outdir);
end

% =========================================================================

function local_save(h, outdir, name, wcm, hcm, dpi)
if nargin < 6 || isempty(dpi), dpi = 600; end
set(h, 'InvertHardcopy', 'off');
if nargin >= 5 && ~isempty(wcm) && ~isempty(hcm)
    set(h, 'PaperUnits', 'centimeters', 'PaperPosition', [0 0 wcm hcm]);
else
    set(h, 'PaperPositionMode', 'auto');
end
print(h, fullfile(outdir, [name '.png']), '-dpng', sprintf('-r%d', dpi));
fprintf('  wrote %s.png\n', name);
end

