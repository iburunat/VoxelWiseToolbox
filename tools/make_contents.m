function make_contents(toolbox_root, dryrun)
% MAKE_CONTENTS  Regenerate Contents.m from the functions in core/.
%
% Scans core/*.m, harvests each function's H1 line, groups them by module and
% writes Contents.m at the toolbox root.
%
% Usage:
%   make_contents                      % toolbox root inferred from this file
%   make_contents(root)                % explicit root
%   make_contents(root, true)          % dry run: report only, write nothing
%
% WHY GENERATE RATHER THAN HAND-MAINTAIN
%   A hand-written Contents.m drifts. Before this generator existed, it listed
%   69 functions while 86 were on disk - so 17 were invisible to `help
%   voxelwiseToolbox`, and the count quoted in the manuscript was wrong. Nothing
%   flagged it, because nothing was checking.
%
% WHAT IT ENFORCES
%   The MODULES table below is the single source of truth for grouping, and
%   every function in core/ must appear in it exactly once. If a function is
%   added to core/ without being assigned a module, the generator ERRORS rather
%   than quietly omitting it - which is the failure that produced the 69-vs-86
%   discrepancy. Likewise a module entry naming a file that no longer exists is
%   an error, so deletions cannot leave phantom entries behind.
%
%   core/private/ is not scanned. dir('core/*.m') does not descend, so the
%   internal helpers are excluded automatically rather than by a rule someone
%   has to remember.
%
% H1 REQUIREMENTS
%   MATLAB takes the H1 line from the FIRST comment line after the function
%   declaration. Two failures are checked and reported:
%     - no H1 at all, or code between the declaration and the comment block
%       (fmri_corrvoldata had exactly this: `help` returned nothing)
%     - an H1 that does not begin with the function name, which produces a
%       Contents entry whose text does not match its own heading
%
% See also: fmritoolbox_setup

if nargin < 1 || isempty(toolbox_root)
    toolbox_root = fileparts(fileparts(mfilename('fullpath')));   % tools/ -> root
end
if nargin < 2, dryrun = false; end

core = fullfile(toolbox_root, 'core');
if ~isfolder(core)
    error('make_contents:noCore', ...
        ['core/ not found at:\n  %s\nPass the toolbox root explicitly if this ' ...
         'file is not in tools/.'], core);
end

%% --- module table: the single source of truth for grouping -----------------
% Order here is the order in Contents.m. Functions are listed in reading order
% within a module, not alphabetically, so related ones sit together.
%
% Two module names carry a distinction worth stating, because an earlier pair
% of names obscured it. Correlation IS statistics, so "Analysis" versus
% "Statistics" named nothing. The real split is ESTIMATION versus INFERENCE:
% the estimation module takes data and produces an EFFECT (an r-map, a
% similarity matrix, a beta map), while the inference module takes an effect and
% asks whether it is REAL (p-values, thresholds, multiple-comparison
% correction). fmri_corrvoldata estimates; fmri_r2p infers.
%
% "Temporal preprocessing" is likewise specific on purpose: every function in it
% operates along TIME, and the SPATIAL preprocessing functions - fmri_upsample,
% fmri_downsample - are in the Space module. A
% bare "Preprocessing" heading would send a reader looking for resampling to the
% wrong place.
%
% Eight modules, reduced from an earlier eleven. I/O and the coordinate
% functions are kept SEPARATE: reading files and converting between coordinate
% systems are different tasks, and merging them produced a 20-item list in which
% neither was easy to scan. Statistical conversions do sit beside the
% cluster-level correction they feed, since fmri_p2t is what fmri_csthreshold
% consumes. The old "Masking and thresholding" group did not hold together:
% its four members belonged in four different places - fmri_maskdata applies a
% mask (data handling), fmri_spheremask DEFINES an ROI (atlases), fmri_bin
% prepares data for display (visualisation) and fmri_dicemirror is a similarity
% metric (analysis). Dissolving it put each function where a reader would
% actually look.
MODULES = {
 'I/O and NIfTI handling', {'fmri_readnii','fmri_export','fmri_checknifti', ...
    'fmri_tomni152'}
 'Space, coordinates and reshaping', {'fmri_vol2vect','fmri_vect2vol', ...
    'fmri_mni2sub','fmri_sub2mni','fmri_ind2sub','fmri_sub2ind','fmri_mni2tal', ...
    'fmri_mirror','fmri_voxdist','fmri_upsample', ...
    'fmri_downsample'}
 'Temporal preprocessing', {'fmri_detrend','fmri_bandpassfilter','fmri_correctmovement', ...
    'fmri_tempsmooth','fmri_zscorevoldata','fmri_wiener','fmri_doublegamma'}
 'Atlases and regions of interest', {'fmri_loadatlas','fmri_atlas', ...
    'fmri_regionmask','fmri_spheremask','fmri_maskdata','fmri_regionnumber', ...
    'fmri_regiontable','fmri_nregion','fmri_vox2reg','fmri_reg2vox','fmri_banumber'}
 'Analysis: effect estimation', {'fmri_corregressor','fmri_corrmat', ...
    'fmri_corrvoldata','fmri_xcorr','fmri_partcorr','fmri_ppi','fmri_rsa', ...
    'fmri_isc','fmri_rv2','fmri_dicemirror'}
 'Statistical inference', {'fmri_ttest','fmri_r2p','fmri_p2r', ...
    'fmri_p2t','fmri_fisherz','fmri_fisherz2p','fmri_effdf','fmri_combinep', ...
    'fmri_tfce','fmri_bwlabel','fmri_findclusters','fmri_cleanclusters', ...
    'fmri_acfestimate','fmri_csdist','fmri_csthreshold','fmri_scramblephases'}
 'Simulation and signal quality', {'fmri_simdata','fmri_simget','fmri_snri', ...
    'fmri_snrt','fmri_cnr'}
 'Visualisation', {'fmri_showslices','fmri_showslices_int', ...
    'fmri_showselectslices','fmri_showselectslices_int','fmri_showplanes', ...
    'fmri_showcortex','fmri_show3d','fmri_show3dba','fmri_show3datlas', ...
    'fmri_show3dhalfbrains','fmri_braincake','fmri_brainvideo', ...
    'fmri_makevizpar','fmri_bin','fmri_juicyslices','fmri_divmap', ...
    'fmri_makecmap','fmri_distinctcolors','fmri_createlegend'}
};

%% --- what is actually on disk ---------------------------------------------
d = dir(fullfile(core, '*.m'));            % does NOT descend into private/

% Test and diagnostic files may sit alongside the functions they test: one that
% exercises a private helper HAS to, since private functions are visible only
% from the parent folder. They are not public API, so they are excluded here
% rather than tripping the unassigned-function error below - and, just as
% importantly, they are kept out of the function COUNT written into Contents.m,
% which the manuscript quotes.
d = d(~startsWith({d.name}, {'test_', 'diagnose_'}));

on_disk = sort(erase({d.name}, '.m'));
mapped  = [MODULES{:,2}];

fprintf('Scanning %s\n', core);
fprintf('  %d files in core/, %d assigned to modules\n', numel(on_disk), numel(mapped));

%% --- coverage: the check that stops silent omissions ----------------------
dups = mapped(cellfun(@(f) sum(strcmp(mapped, f)) > 1, mapped));
if ~isempty(dups)
    error('make_contents:duplicateAssignment', ...
        'Assigned to more than one module: %s', strjoin(unique(dups), ', '));
end

missing = setdiff(on_disk, mapped);        % on disk, no module
if ~isempty(missing)
    error('make_contents:unassigned', ...
        ['These functions are in core/ but not assigned to any module:\n  %s\n\n' ...
         'Add them to the MODULES table in this file. The generator refuses to ' ...
         'omit\nthem silently: that is how Contents.m came to list 69 functions ' ...
         'when 86\nwere on disk.'], strjoin(missing, ', '));
end

phantom = setdiff(mapped, on_disk);        % module entry, no file
if ~isempty(phantom)
    error('make_contents:phantomEntry', ...
        ['The MODULES table names functions that do not exist in core/:\n  %s\n\n' ...
         'Remove them from the table, or restore the files. A deleted function ' ...
         'must not\nleave an entry behind.'], strjoin(phantom, ', '));
end

%% --- harvest H1 lines ------------------------------------------------------
h1 = containers.Map();
problems = {};
for k = 1:numel(on_disk)
    name = on_disk{k};
    txt  = strsplit(fileread(fullfile(core, [name '.m'])), newline);

    i = 1;                                  % find the function declaration
    while i <= numel(txt) && isempty(regexp(strtrim(txt{i}), '^function\>', 'once'))
        i = i + 1;
    end
    while i < numel(txt) && endsWith(strtrim(txt{i}), '...')
        i = i + 1;                          % multi-line declaration
    end
    i = i + 1;

    if i > numel(txt) || ~startsWith(strtrim(txt{i}), '%')
        % No comment immediately after the declaration. Either there is no help
        % at all, or code sits in between - in which case MATLAB shows nothing.
        problems{end+1} = sprintf('%s: no H1 (help would be empty)', name); %#ok<AGROW>
        h1(name) = '(no description)';
        continue
    end

    line = strtrim(regexprep(txt{i}, '^\s*%\s*', ''));
    if ~startsWith(upper(line), upper(name))
        problems{end+1} = sprintf('%s: H1 does not start with the function name', name); %#ok<AGROW>
    else
        line = strtrim(line(numel(name)+1:end));    % drop the repeated name
    end
    h1(name) = line;
end

if ~isempty(problems)
    fprintf('\n  H1 problems (%d):\n', numel(problems));
    fprintf('    %s\n', problems{:});
    fprintf(['  These are not fatal - Contents.m is still written - but each one ' ...
             'produces a\n  poor entry, and an empty H1 means `help <fn>` shows ' ...
             'nothing at all.\n']);
end


%% --- compose ---------------------------------------------------------------
RULE = ['% ' repmat('-', 1, 73)];

L = {};
L{end+1} = '% VoxelWise Toolbox — Lightweight MATLAB toolbox for transparent fMRI analysis';
L{end+1} = '%';
L{end+1} = '% Run fmritoolbox_setup.m to add the toolbox to your MATLAB path.';
L{end+1} = '% Type "help <function_name>" for detailed documentation on any function.';
L{end+1} = '%';
L{end+1} = '% Voxelwise analysis of fMRI data on the MNI152 2mm grid (91x109x91,';
L{end+1} = '% 228453 in-brain voxels). Every function takes and returns data in that';
L{end+1} = '% single layout, so any function composes with any other.';
L{end+1} = '%';
L{end+1} = '% Requires MATLAB R2019a or later. No other MathWorks toolbox is needed:';
L{end+1} = '% R2019a is the release in which xcorr, used by fmri_effdf, moved into base';
L{end+1} = '% MATLAB from the Signal Processing Toolbox.';
L{end+1} = '%';
L{end+1} = sprintf('%% %d public functions. Internal helpers live in core/private/ and are', numel(on_disk));
L{end+1} = '% deliberately not listed here.';
L{end+1} = '%';

% ONE column width for the whole file, not one per module. Computed per module,
% each block was internally aligned but misaligned against its neighbours, so
% the description column moved at every heading and the eye had to re-find it.
% The width comes from the longest name anywhere in the table, so adding a
% longer function re-aligns the whole file rather than ragging one block.
W = max(cellfun(@numel, [MODULES{:,2}])) + 2;

for m = 1:size(MODULES, 1)
    L{end+1} = RULE;                                                 %#ok<AGROW>
    L{end+1} = sprintf('%% %s', MODULES{m,1});                       %#ok<AGROW>
    L{end+1} = RULE;                                                 %#ok<AGROW>
    fns = MODULES{m,2};
    for k = 1:numel(fns)
        L{end+1} = sprintf('%%   %-*s - %s', W, fns{k}, h1(fns{k})); %#ok<AGROW>
    end
    L{end+1} = '%';                                                  %#ok<AGROW>
end

L{end+1} = RULE;
L{end+1} = '% Getting started';
L{end+1} = RULE;
% Column width computed from the longest entry rather than hardcoded, so a
% longer demo name cannot leave the list ragged. Kept separate from W above:
% these are paths, not function names, and aligning them to W would open a gap.
demos = {'demo/demo_preprocessing.m',        'preprocessing chain, one participant'
         'demo/demo_glm.m',                  'two-level GLM, simulated cohort'
         'demo/demo_visualization.m',        'every display function'
         'demo/demo_naturalistic.m','full naturalistic-stimulus pipeline'};
dw = max(cellfun(@numel, demos(:,1)));
for k = 1:size(demos,1)
    L{end+1} = sprintf('%%   %-*s - %s', W, demos{k,1}, demos{k,2}); %#ok<AGROW>
end
L{end+1} = '%';
L{end+1} = '% Generated by tools/make_contents.m - do not edit by hand.';
L{end+1} = sprintf('%% Last generated: %s', datestr(now, 'yyyy-mm-dd')); %#ok<DATST>
L{end+1} = '';

out = fullfile(toolbox_root, 'Contents.m');
if dryrun
    fprintf('\n--- DRY RUN, nothing written. Contents.m would be %d lines ---\n', numel(L));
    fprintf('%s\n', L{1:min(24, numel(L))});
    fprintf('  ...\n');
else
    fid = fopen(out, 'w');
    if fid < 0
        error('make_contents:cannotWrite', 'Could not open %s for writing.', out);
    end
    fprintf(fid, '%s\n', L{:});
    fclose(fid);
    fprintf('\nWrote %s\n  %d functions in %d modules, %d lines\n', ...
            out, numel(on_disk), size(MODULES,1), numel(L));
end
end
