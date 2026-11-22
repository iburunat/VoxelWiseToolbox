function batch_generate(toolboxRoot, sourceRoot)
% BATCH_GENERATE  Regenerate the whole Sphinx function reference from source.
%
% Usage:
%   batch_generate                        % infer both paths from this file
%   batch_generate(toolboxRoot)           % <root>/source is the docs tree
%   batch_generate(toolboxRoot, sourceRoot)
%
% Inputs:
%   TOOLBOXROOT - Toolbox root (the folder holding core/, demo/, Contents.m).
%                 Defaults to the parent of the folder this file lives in.
%   SOURCEROOT  - Sphinx source tree. Defaults to <toolboxRoot>/source.
%
% What it does:
%   1. Writes one .rst per public function into <sourceRoot>/modules/
%   2. Writes one .rst per demo script into   <sourceRoot>/demos/
%   3. Builds modules/index.rst GROUPED BY THE EIGHT MODULES IN Contents.m,
%      and demos/index.rst, so no page is left out of a toctree.
%
% Why it reads Contents.m:
%   Contents.m defines the public functions and their module grouping.
%   Using it to build the documentation keeps the Sphinx reference aligned
%   with the toolbox automatically.
%
% After running, rebuild the site or push; Read the Docs builds from
% .readthedocs.yaml at the repository root.
%
% See also: generate_rst, make_contents

if nargin < 1 || isempty(toolboxRoot)
    toolboxRoot = fileparts(fileparts(mfilename('fullpath')));
end
if nargin < 2 || isempty(sourceRoot)
    sourceRoot = fullfile(toolboxRoot, 'source');
end

coreDir     = fullfile(toolboxRoot, 'core');
contentsFile= fullfile(toolboxRoot, 'Contents.m');
modulesDir  = fullfile(sourceRoot, 'modules');
demosDir    = fullfile(sourceRoot, 'demos');

assert(isfolder(coreDir),      'core/ not found at %s', coreDir);
assert(isfile(contentsFile),   'Contents.m not found at %s', contentsFile);
if ~isfolder(modulesDir), mkdir(modulesDir); end
if ~isfolder(demosDir),   mkdir(demosDir);   end

% Remove previously generated pages so renamed or deleted functions do not
% leave orphaned RST files. Only the generated modules and demos folders are
% cleared.
for dd = {modulesDir, demosDir}
    old = dir(fullfile(dd{1}, '*.rst'));
    for k = 1:numel(old)
        delete(fullfile(dd{1}, old(k).name));
    end
end

%% 1. Parse Contents.m into modules -> function names
[modNames, modFuncs] = parse_contents(contentsFile);
listed = [modFuncs{:}];
fprintf('Contents.m: %d modules, %d functions\n', numel(modNames), numel(listed));

%% 2. Cross-check against what is actually in core/
files   = dir(fullfile(coreDir, 'fmri_*.m'));
onDisk  = erase({files.name}, '.m');
missing = setdiff(listed, onDisk);     % listed but no file
extra   = setdiff(onDisk, listed);     % file but not listed
if ~isempty(missing)
    warning('batch_generate:missingFile', ...
        'Listed in Contents.m but absent from core/: %s', strjoin(missing, ', '));
end
if ~isempty(extra)
    warning('batch_generate:notListed', ...
        'Present in core/ but not in Contents.m: %s', strjoin(extra, ', '));
end

%% 3. Build the cross-reference maps
demoDir   = fullfile(toolboxRoot, 'demo');
demoNames = {};
demoPaths = {};
if isfolder(demoDir)
    d = dir(fullfile(demoDir, '**', 'demo_*.m'));
    if ~isempty(d)
        demoPaths = fullfile({d.folder}, {d.name});
        demoNames = erase({d.name}, '.m');
        [uniqNames, iu] = unique(demoNames, 'stable');
        if numel(uniqNames) < numel(demoNames)
            dup = demoNames(setdiff(1:numel(demoNames), iu));
            warning('batch_generate:duplicateDemo', ...
                ['These demo file names occur more than once under demo/; ' ...
                 'only one page is written for each: %s'], ...
                strjoin(unique(dup), ', '));
            demoNames = uniqNames;
            demoPaths = demoPaths(iu);
        end
    end
end

modTargets  = containers.Map('KeyType','char','ValueType','char');
demoTargets = containers.Map('KeyType','char','ValueType','char');
for k = 1:numel(onDisk)
    modTargets(onDisk{k})  = onDisk{k};
    demoTargets(onDisk{k}) = ['../modules/' onDisk{k}];
end
for k = 1:numel(demoNames)
    modTargets(demoNames{k})  = ['../demos/' demoNames{k}];
    demoTargets(demoNames{k}) = demoNames{k};
end

% Scan known toolbox folders for all MATLAB files, including undocumented
% helpers, scripts and tests. Valid but undocumented See also references are
% shown as plain text; only names not found anywhere trigger a warning.
%
% Limit the scan to toolbox folders so external files or stale archived copies
% do not hide invalid references.
scanDirs = {'', 'core', fullfile('core','private'), 'demo', 'tools', 'tests', 'test'};
allM = [];
for d = 1:numel(scanDirs)
    dd = fullfile(toolboxRoot, scanDirs{d});
    if isfolder(dd), allM = [allM; dir(fullfile(dd, '*.m'))]; end %#ok<AGROW>
end
knownNames = unique(regexprep({allM.name}, '\.m$', ''));

% Warn about fmri_* files outside core/ because they may be stale copies left
% after a rename and could hide invalid references. Exclude core/private/,
% where undocumented internal helpers are expected.
skipDirs = {'core', fullfile('core','private')};
stray = {};
for d = 1:numel(scanDirs)
    if any(strcmp(scanDirs{d}, skipDirs)), continue, end
    dd = fullfile(toolboxRoot, scanDirs{d});
    if ~isfolder(dd), continue, end
    f = dir(fullfile(dd, 'fmri_*.m'));
    for k = 1:numel(f)
        nm = regexprep(f(k).name, '\.m$', '');
        if ~any(strcmp(nm, onDisk))
            stray{end+1} = sprintf('%s (in %s)', nm, ...
                           ternary(isempty(scanDirs{d}), 'toolbox root', scanDirs{d})); %#ok<AGROW>
        end
    end
end
if ~isempty(stray)
    warning('batch_generate:strayFunction', ...
        ['These fmri_* files are outside core/ and are not in Contents.m:\n  %s\n' ...
         'A leftover copy from a rename will silently suppress the ' ...
         '"exists nowhere" check for that name.'], strjoin(stray, '\n  '));
end

%% 4. One page per function, then one per demo
% Demos are scripts; generate_rst handles the missing 'function' line.
for k = 1:numel(onDisk)
    generate_rst(fullfile(coreDir, [onDisk{k} '.m']), modulesDir, modTargets, knownNames);
end
fprintf('wrote %d function pages to %s\n', numel(onDisk), modulesDir);

for k = 1:numel(demoNames)
    generate_rst(demoPaths{k}, demosDir, demoTargets, knownNames);
end
if ~isempty(demoNames)
    fprintf('wrote %d demo pages to %s\n', numel(demoNames), demosDir);
end

%% 5. modules/index.rst, grouped exactly as Contents.m groups them
fid = fopen(fullfile(modulesDir, 'index.rst'), 'w');
title = 'Function Library';
fprintf(fid, '%s\n%s\n\n', title, repmat('=', 1, numel(title)));
fprintf(fid, ['Every function takes and returns data on the MNI152 2 mm grid\n' ...
              '(91x109x91, 228453 in-brain voxels), so any function composes with\n' ...
              'any other. Grouping follows ``Contents.m``.\n\n']);
for m = 1:numel(modNames)
    fns = intersect(modFuncs{m}, onDisk, 'stable');   % only pages that exist
    if isempty(fns), continue, end
    fprintf(fid, '%s\n%s\n\n', modNames{m}, repmat('-', 1, numel(modNames{m})));
    fprintf(fid, '.. toctree::\n   :maxdepth: 1\n\n');
    fprintf(fid, '   %s\n', fns{:});
    fprintf(fid, '\n');
end
fclose(fid);

%% 6. demos/index.rst
if ~isempty(demoNames)
    fid = fopen(fullfile(demosDir, 'index.rst'), 'w');
    title = 'Tutorials';
    fprintf(fid, '%s\n%s\n\n', title, repmat('=', 1, numel(title)));
    fprintf(fid, ['Worked examples that ship with the toolbox. Each runs end to end;\n' ...
                  'those based on simulated data need no scanner data at all.\n\n']);
    fprintf(fid, '.. toctree::\n   :maxdepth: 1\n\n');
    fprintf(fid, '   %s\n', demoNames{:});
    fclose(fid);
end

fprintf('done. Now run:  sphinx-build -nW -b html %s %s\n', ...
        sourceRoot, fullfile(toolboxRoot, '_build', 'html'));
end

%% -------------------------------------------------------------------------
function [modNames, modFuncs] = parse_contents(contentsFile)
% Contents.m marks each module as a name between two '% ----' rules, then
% lists '%   fmri_name   - description'. Entries that are not fmri_* (the
% 'Getting started' block lists demo paths) are ignored.
txt = textscan(fopen(contentsFile,'r'), '%s', 'Delimiter','\n', 'Whitespace','');
fclose('all');
L = txt{1};

modNames = {}; modFuncs = {};
for i = 2:numel(L)-1
    prev = strtrim(regexprep(L{i-1}, '^\s*%\s?', ''));
    cur  = strtrim(regexprep(L{i},   '^\s*%\s?', ''));
    next = strtrim(regexprep(L{i+1}, '^\s*%\s?', ''));
    isRule = @(s) ~isempty(regexp(s, '^-{5,}$', 'once'));
    if isRule(prev) && isRule(next) && ~isempty(cur) && ~isRule(cur)
        modNames{end+1} = cur; %#ok<AGROW>
        modFuncs{end+1} = {};  %#ok<AGROW>
    elseif ~isempty(modNames)
        tok = regexp(cur, '^(fmri_\w+)\s+-\s', 'tokens', 'once');
        if ~isempty(tok)
            modFuncs{end}{end+1} = tok{1};
        end
    end
end
% Drop any module that ended up with no fmri_* entries (e.g. Getting started)
keep = ~cellfun(@isempty, modFuncs);
modNames = modNames(keep);
modFuncs = modFuncs(keep);
end

%% -------------------------------------------------------------------------
function out = ternary(cond, a, b)
if cond, out = a; else, out = b; end
end