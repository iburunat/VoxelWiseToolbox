function make_figure4(runs, outdir)
% make_figure4  Generates the component images for the Section 5.2 figure.
%
% Renders the validation of the two-level pipeline against the analytic ground
% truth returned by fmri_simdata: what was planted, what the pipeline
% recovered, and where the two disagree. One row of three panels per
% simulation run, so that two seeds can be shown together.
%
% Usage, with the struct validate_glm_recovery returns:
%   runs = validate_glm_recovery;      % both seeds
%   make_figure4(runs, '~/fig4')
%
% Inputs:
%   RUNS   - Struct array, one element per simulation run (1 or 2; a third
%            would not fit the page). validate_glm_recovery builds it. Fields:
%              .truth    228453 x 1  the map the scoring runs against,
%                                    signed. This is R_DESIGNED, the designed
%                                    network's contribution alone. Passing
%                                    sim.truth instead would score the figure
%                                    against a different quantity than the
%                                    test does.
%              .r_task   228453 x 1  expected correlation with the task time
%                                    course from ANY source, chance leakage
%                                    included. Used only to report how many
%                                    false positives leakage accounts for.
%              .detected 228453 x 1  logical, voxels surviving cluster
%                                    cleaning (clean_map > 0)
%              .t_map    228453 x 1  group t statistic
%              .r_detect 1 x 1       derived detectability cut-off,
%                                    tanh(t_crit*median(sd_z)/sqrt(N))
%              .df       1 x 1       group degrees of freedom (N - 1)
%              .seed     1 x 1       the rng seed, for the caption only
%   OUTDIR - Output folder (default: pwd).
%
% Outputs:
%   None. Writes three PNGs per run, to be assembled into a grid:
%
%   fig4_r<k>_A_truth.png      ground truth, slice mosaic
%   fig4_r<k>_B_recovered.png  recovered group map, same slices
%   fig4_r<k>_C_disagree.png   errors only, same slices as A and B
%
%   and prints the scoring numbers for the caption.
%
% Panel C shows recovery errors directly: blue marks missed detectable voxels,
% and red marks unexpected detections. These errors usually form thin rims near
% source boundaries, which are clearer in slices than in 3D isosurfaces.
%
% Both mosaics use the same slices, selected from the ground-truth map to avoid
% favouring areas of successful recovery. Panels are rendered separately because
% the toolbox viewers cannot reliably share subplot axes.
%
% See also: validate_glm_recovery, demo_glm, fmri_simdata, fmri_juicyslices,
%           fmri_showselectslices, fmri_divmap

NVOX = 228453;

if nargin < 1 || isempty(runs)
    error('make_figure4:tooFewInputs', ...
          'RUNS is required; validate_glm_recovery returns it.');
end
if nargin < 2 || isempty(outdir), outdir = pwd; end
if ~isfolder(outdir), mkdir(outdir); end

if numel(runs) > 2
    error('make_figure4:tooManyRuns', ...
          'At most two runs fit the page; got %d.', numel(runs));
end

need = {'truth', 'r_task', 'detected', 't_map', 'r_detect', 'df', 'seed'};
for k = 1:numel(runs)
    miss = need(~isfield(runs(k), need));
    if ~isempty(miss)
        error('make_figure4:missingField', ...
              'runs(%d) is missing: %s.', k, strjoin(miss, ', '));
    end
end

[cmap ends]= fmri_divmap(256);

for k = 1:numel(runs)
    r = runs(k);

    truth    = r.truth(:);
    r_task   = r.r_task(:);
    detected = logical(r.detected(:));
    t_map    = r.t_map(:);

    if numel(truth) ~= NVOX || numel(r_task) ~= NVOX || ...
       numel(detected) ~= NVOX || numel(t_map) ~= NVOX
        error('make_figure4:badSize', ...
              ['runs(%d): TRUTH, R_TASK, DETECTED and T_MAP must each ', ...
               'hold %d elements.'], k, NVOX);
    end

    % Scoring, reproducing validate_glm_recovery's definitions exactly so that the
    % numbers printed here match the ones reported in Section 5.2. A hit is
    % SIGN-AWARE: a surviving voxel counts only if the t statistic has the
    % same sign as the ground truth there.
    truth_pos = truth >  r.r_detect;
    truth_neg = truth < -r.r_detect;
    truth_any = truth_pos | truth_neg;

    tp_mask = detected & ((truth_pos & t_map > 0) | ...
                          (truth_neg & t_map < 0));
    fp_mask = detected & ~truth_any;
    fn_mask = ~detected & truth_any;

    % How many false positives does chance source correlation account for? A
    % voxel whose expected correlation with the TASK time course clears the
    % threshold is one a correct analysis should find, whichever source
    % produces it. Normally zero after orthogonalisation; reported anyway.
    fp_leak  = nnz(fp_mask & (abs(r_task) >  r.r_detect));
    fp_unexp = nnz(fp_mask & (abs(r_task) <= r.r_detect));

    % Detected with the WRONG sign: neither a hit nor a false positive under
    % the definitions above, so it would vanish silently. Reported rather than
    % folded into another category.
    sign_wrong = nnz(detected & truth_any & ~tp_mask);

    tp = nnz(tp_mask);  fp = nnz(fp_mask);  fn = nnz(fn_mask);
    precision = tp / max(tp + fp, 1);
    recall    = tp / max(tp + fn, 1);

    % Slices from the TRUTH map. minsep = 3 rather than the default 4: the
    % planted sources are compact, and wider spacing reaches slices holding
    % almost no signal.
    sl = fmri_juicyslices(truth, 'axial', 6, r.r_detect, 3);

    tag = sprintf('fig4_r%d', k);

    %% --- A: ground truth ------------------------------------------------
    % Scaled to the truth map's own range, not to [-1 1]: the expected
    % correlation is bounded below 1 by the noise floor, so a full-range
    % scale would compress every blob into the middle of the colormap.
    t_lim_truth = max(abs(truth));
    figure('Name', [tag ' A truth'], 'Color', 'w');
    fmri_showselectslices(truth, sl, [-t_lim_truth t_lim_truth], ...
                          1, 1, 1, cmap, r.r_detect);
    hcb = findobj(gcf, 'Type', 'ColorBar');
    cb  = get(hcb, 'Position');
    annotation('textbox', [cb(1) + 1.6*cb(3), cb(2) + cb(4)/2 - 0.08, 0.10, 0.16], ...
               'String', 'r', 'EdgeColor', 'none', ...
               'FontName', get(hcb, 'FontName'), 'FontSize', 16, ...
               'VerticalAlignment', 'middle');
    local_save(gcf, outdir, [tag '_A_truth']);


    %% --- B: recovered --------------------------------------------------
    % The group t map, shown only where it survived cluster cleaning. NaN
    % outside, so THRESHOLD = 0 invokes the isfinite rule; zeroing instead
    % would place the excluded territory at the CENTRE of the diverging
    % colormap and paint it white rather than leaving it as plain anatomy.
    t_shown = t_map;
    t_shown(~detected) = NaN;
    t_crit = fmri_p2t(0.001, r.df);
    t_lim  = 2 * t_crit;

    figure('Name', [tag ' B recovered'], 'Color', 'w');
    fmri_showselectslices(t_shown, sl, [-t_lim t_lim], 1, 1, 1, cmap, 0);
    hcb = findobj(gcf, 'Type', 'ColorBar');
    cb  = get(hcb, 'Position');
    annotation('textbox', [cb(1) + 1.6*cb(3), cb(2) + cb(4)/2 - 0.08, 0.10, 0.16], ...
               'String', 't', 'EdgeColor', 'none', ...
               'FontName', get(hcb, 'FontName'), 'FontSize', 16, ...
               'VerticalAlignment', 'middle');
    local_save(gcf, outdir, [tag '_B_recovered']);



    %% --- C: where the two disagree ---------------------------------------
    % Errors only, on the same slices as A and B. Agreement is left as plain
    % anatomy rather than drawn, so the rim is not competing with the bulk it
    % surrounds; the reader has already seen the bulk twice.
    %
    % NaN everywhere else, so THRESHOLD = 0 invokes the isfinite rule and
    % only the two error sets are painted. Values are +/-1 against CLIMITS
    % [-1 1], which puts them at the colormap's extremes: blue for missed,
    % red for falsely detected, matching the polarity convention of A and B.
    err = nan(NVOX, 1);
    err(fn_mask) = -1;
    err(fp_mask) =  1;

    % ERR holds only -1 and +1, so a continuous bar is the wrong object. A
    % 256-row map in two solid halves keeps the mosaic's two colours exact, and
    % CBAR stays ON because CBAR = 0 drops the 1.15 width factor and panel C
    % would no longer align with A and B. The bar is then hidden and replaced by
    % two square swatches placed from its own Position, so they stay inside the
    % reserved strip whatever the number of slices.
    cmap_bin = [repmat(ends(1,:), 128, 1); repmat(ends(2,:), 128, 1)];

    figure('Name', [tag ' C disagreement'], 'Color', 'w');
    fmri_showselectslices(err, sl, [-1 1], 1, 1, 1, cmap_bin, 0);

    hcb = findobj(gcf, 'Type', 'ColorBar');
    cb  = get(hcb, 'Position');          % normalised
    set(hcb, 'Visible', 'off');

    fp    = get(gcf, 'Position');        % pixels, the default figure units
    side  = cb(3);                       % swatch width, a fraction of the figure
    sidey = side * fp(3) / fp(4);        % the same length vertically: square
    gap   = 0.8 * sidey;
    yc    = cb(2) + cb(4)/2;             % keep the pair where the bar was

    lab = {'found', 'missed'};
    col = [ends(2,:); ends(1,:)];        % +1 on top, -1 below
    for q = 1:2
        y = yc + (1.5 - q)*(sidey + gap) - sidey/2;
        annotation('rectangle', [cb(1) y side sidey], ...
                   'FaceColor', col(q,:), 'EdgeColor', 'none');
        annotation('textbox', [cb(1) + 1.6*side, y - 0.25*sidey, 0.10, 1.5*sidey], ...
                   'String', lab{q}, 'EdgeColor', 'none', ...
                   'FontName', get(hcb, 'FontName'), 'FontSize', 16, ...
                   'VerticalAlignment', 'middle');
    end

    
% Relabel the bar's two ticks as categories. After the call: the viewer sets
% its own ticks from CLIMITS.
%hcb = findobj(gcf, 'Type', 'ColorBar');
% yl  = get(hcb, 'YLim');
% set(hcb, 'YTick', yl(1) + diff(yl)*[0.25 0.75], ...
%          'YTickLabel', {'missed', 'found'}, 'FontSize', 16);
    local_save(gcf, outdir, [tag '_C_disagree']);
    %% --- numbers for the caption -----------------------------------------
    fprintf('\n--- run %d (seed %d), for the caption ---\n', k, r.seed);
    fprintf('  detectability cut-off  : |r| >= %.4f (df = %d)\n', ...
            r.r_detect, r.df);
    fprintf('  ground truth extent    : %d voxels (%d pos, %d neg)\n', ...
            nnz(truth_any), nnz(truth_pos), nnz(truth_neg));
    fprintf('  detected               : %d voxels\n', nnz(detected));
    fprintf('  true positives         : %d\n', tp);
    fprintf('  false positives        : %d (%d from leakage, %d not)\n', ...
            fp, fp_leak, fp_unexp);
    fprintf('  false negatives        : %d\n', fn);
    if sign_wrong > 0
        fprintf('  detected, wrong sign   : %d (not counted either way)\n', ...
                sign_wrong);
    end
    fprintf('  precision %.2f   recall %.2f\n', precision, recall);
    fprintf('  slices shown           : z = %s\n', ...
            strjoin(arrayfun(@(v) sprintf('%d', v), sl, ...
                             'UniformOutput', false), ', '));
end

fprintf('\nWrote %d PNGs to %s\n', 3*numel(runs), outdir);
end

% =========================================================================

function local_save(h, outdir, name, wcm, hcm, dpi)
% Save a panel at DPI. Given WCM and HCM, the figure is printed at exactly
% that size in centimetres, so its point sizes are literal on the page.
% Omit them for anything whose drawing function sets its own figure size —
% fmri_showselectslices and fmri_show3d both do — and the on-screen size is
% used instead.
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