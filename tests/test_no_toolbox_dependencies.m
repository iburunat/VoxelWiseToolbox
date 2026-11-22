function tests = test_no_toolbox_dependencies
% TEST_NO_TOOLBOX_DEPENDENCIES  Every function must run on base MATLAB alone.
%
% Verifies that all toolbox files require only base MATLAB, using
% matlab.codetools.requiredFilesAndProducts. The check also reports syntax
% errors and unresolved fmri_* references.
%
% Dependency analysis can take several minutes.
%
% RUNTIME. Dependency analysis is slow, roughly a second per file, so the whole
% toolbox takes a few minutes.
%
% Usage:
%   results = runtests('test_no_toolbox_dependencies')
%
% See also: fmritoolbox_setup

tests = functiontests(localfunctions);
end


function setupOnce(tc)
% Locate the toolbox root from fmritoolbox_setup and scan all MATLAB files
% recursively so core/, private helpers, demos and tools are included.
setup_path = which('fmritoolbox_setup');
if isempty(setup_path)
    assumeFail(tc, ...
        'fmritoolbox_setup is not on the path; run it before this test.');
end
root = fileparts(setup_path);

% Scan every shipped .m file ensuring that setup scripts, private helpers
% and demo-support files are also checked.
files = dir(fullfile(root, '**', '*.m'));

% Exclude external dependencies and tests. The bundled NIfTI library is
% third-party code, while tests may intentionally call toolbox functions for
% comparison.
if ~isempty(files)
    folders = {files.folder};
    drop    = contains(folders, [filesep 'external']) | ...
              contains(folders, [filesep 'test']);
    files   = files(~drop);
end

if isempty(files)
    assumeFail(tc, 'No .m files found under %s.', root);
end

tc.TestData.files = files;
tc.TestData.root  = root;
end


function testEveryFileParses(tc)
% requiredFilesAndProducts THROWS on a file with a syntax error, which would
% abort the sweep and leave every later file unchecked - a broken file would
% therefore hide the dependency status of the whole toolbox. Parse failures are
% collected and reported as their own failure instead.
tc.TestData.unparsable = scan(tc);
verifyEmpty(tc, tc.TestData.unparsable, sprintf( ...
    ['%d file(s) do not parse, so their dependencies could not be checked:\n  %s'], ...
    numel(tc.TestData.unparsable), ...
    strjoin(tc.TestData.unparsable, sprintf('\n  '))));
end


function testNoFileRequiresAMathWorksToolbox(tc)
% requiredFilesAndProducts reports every product a file needs in order to run.
% For this toolbox that list must contain MATLAB and nothing else.
[~, offenders, n_checked] = scan(tc);

verifyEmpty(tc, offenders, sprintf( ...
    ['%d of %d parsable files require a MathWorks toolbox beyond base ', ...
     'MATLAB:\n  %s\n', ...
     'The toolbox claims base MATLAB only (paper Section 4 and Table 4).'], ...
    numel(offenders), n_checked, strjoin(offenders, sprintf('\n  '))));
end


function [unparsable, offenders, n_checked] = scan(tc)
% One sweep, used by both tests. A file that will not parse is recorded and
% skipped so it doesn't abort the loop.
files      = tc.TestData.files;
unparsable = {};
offenders  = {};
n_checked  = 0;

for k = 1:numel(files)
    f = fullfile(files(k).folder, files(k).name);
    try
        [~, products] = matlab.codetools.requiredFilesAndProducts(f);
    catch ME
        unparsable{end+1, 1} = sprintf('%-34s %s', ...
            files(k).name, strtrim(ME.message)); %#ok<AGROW>
        continue
    end
    n_checked = n_checked + 1;
    extra = setdiff({products.Name}, {'MATLAB'});
    if ~isempty(extra)
        offenders{end+1, 1} = sprintf('%-34s requires %s', ...
            files(k).name, strjoin(extra, ', ')); %#ok<AGROW>
    end
end
end


function testToolboxFilesWereActuallyFound(tc)
% Verify that the scan found a plausible number of files, so an empty or
% incomplete search cannot pass unnoticed.
n = numel(tc.TestData.files);
verifyGreaterThan(tc, n, 90, sprintf( ...
    ['Only %d .m files found under %s. The toolbox has 84 public functions, ', ...
     'seven private helpers and eleven demos, so the search is not reaching ', ...
     'them. Raise this floor once the file count is stable.'], ...
    n, tc.TestData.root));
end

function testEveryToolboxCallResolves(tc)
% Check fmri_* references against the complete file list so misspelled or
% missing function names are caught before runtime. Use the file list, not
% the WHICH because private helpers are absent from the path.
files   = tc.TestData.files;
defined = erase({files.name}, '.m');

bad = {};
for k = 1:numel(files)
    src   = fileread(fullfile(files(k).folder, files(k).name));
    src   = regexprep(src, '^\s*%[^\n]*$', '', 'lineanchors');   % drop comment lines
    names = unique(regexp(src, '\<fmri_\w+', 'match'));
    miss  = names(~ismember(names, defined));
    for j = 1:numel(miss)
        bad{end+1, 1} = sprintf('%-28s -> %s', files(k).name, miss{j}); %#ok<AGROW>
    end
end

verifyEmpty(tc, bad, sprintf('Unresolved fmri_* references:\n  %s', ...
    strjoin(bad, sprintf('\n  '))));
end