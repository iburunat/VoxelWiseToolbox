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
% WHY GENERATE CONTENTS.M
%   Generating Contents.m prevents the function list from becoming outdated.
%   Every public function in core/ must appear exactly once in MODULES; missing,
%   duplicate or obsolete entries produce an error. Files in core/private/ are
%   excluded automatically.
%
% H1 REQUIREMENTS
%   The first comment after each function declaration must begin with the
%   function name. Missing or malformed H1 lines are reported because they
%   produce incomplete Contents.m entries and poor MATLAB help output.
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
% Module and function order determines their order in Contents.m. Functions
% are grouped by task.
%
% Effect estimation produces measures such as correlations, similarities and
% beta maps; statistical inference evaluates those effects using p-values,
% thresholds and multiple-comparison correction. Temporal preprocessing
% contains time-domain operations, while spatial resampling is grouped under
% Space, coordinates and reshaping.
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
    'fmri_makecmap','fmri_distinctcolors','fmri_createlegend','fmri_colorbar'}
};

%% --- what is actually on disk ---------------------------------------------
d = dir(fullfile(core, '*.m'));            % does NOT descend into private/

% Exclude test and diagnostic files because they are not part of the public
% API and should not be listed or counted in Contents.m.
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

% Use one column width across all modules, based on the longest function name,
% so descriptions remain
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


% Align demo descriptions with the function entries above using the same
% column width.
demos = {'demo/demo_preprocessing.m',  'preprocessing chain, one participant'
         'demo/demo_glm.m',            'two-level GLM, simulated cohort'
         'demo/demo_visualization.m',  'every display function'
         'demo/demo_naturalistic.m',   'full naturalistic-stimulus pipeline'};

gone = demos(~cellfun(@(p) isfile(fullfile(toolbox_root, p)), demos(:,1)), 1);
if ~isempty(gone)
    error('make_contents:missingDemo', ...
        ['The Getting started list names files that do not exist:\n  %s\n\n' ...
         'Update the demos list in this file. Contents.m must not point at a ' ...
         'file\nthat is not there.'], strjoin(gone, ', '));
end

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
