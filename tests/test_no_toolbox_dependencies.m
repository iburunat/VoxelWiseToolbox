function tests = test_no_toolbox_dependencies
% TEST_NO_TOOLBOX_DEPENDENCIES  Every function must run on base MATLAB alone.
%
% The toolbox claims to require MATLAB and nothing else - no MathWorks toolbox
% (paper Section 4 and Table 4, and the title). This checks the claim
% mechanically with matlab.codetools.requiredFilesAndProducts rather than
% asserting it: eight functions were still calling into Statistics months after
% the removal pass was believed complete.
%
% RUNTIME. Dependency analysis is slow, roughly a second per file, so the whole
% toolbox takes a few minutes. This is a pre-release check, not one to run on
% every edit.
%
% Usage:
%   results = runtests('test_no_toolbox_dependencies')
%
% See also: fmritoolbox_setup

tests = functiontests(localfunctions);
end


function setupOnce(tc)
% The toolbox root is wherever fmritoolbox_setup sits (paper Section 7.1).
% Files are gathered RECURSIVELY so that core/, demo/ and core/private/ are all
% covered whatever the install layout. The previous version of this script
% globbed a single folder taken from which('fmri_showslices'), which resolves
% to core/ - so its demo*.m pattern matched nothing and no demo was ever
% checked, despite the header saying otherwise.
setup_path = which('fmritoolbox_setup');
if isempty(setup_path)
    assumeFail(tc, ...
        'fmritoolbox_setup is not on the path; run it before this test.');
end
root = fileparts(setup_path);

% EVERY shipped .m file, not just fmri_*.m and demo_*.m. Those two patterns
% miss fmritoolbox_setup.m (no underscore after "fmri"), which every demo calls
% on its first line, and they miss tools/, core/private/ helpers not named
% fmri_* such as tiedrank_local, and demo-support files like rsn_compare_demo.
% The claim is about the toolbox, so the sweep has to cover the toolbox.
files = dir(fullfile(root, '**', '*.m'));

% Two exclusions. external/ holds the redistributed NIfTI toolbox, which is not
% ours to vouch for. The test folder is excluded because a test may legitimately
% call a MathWorks function in order to check that the toolbox's own
% replacement agrees with it - that is a cross-check, not a dependency.
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
% skipped rather than allowed to abort the loop.
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
% A dependency sweep that silently examines nothing would pass. This pins the
% sweep to a plausible file count so an empty or truncated search is a failure
% rather than a green tick - which is the failure mode the previous version
% had for the demos.
n = numel(tc.TestData.files);
verifyGreaterThan(tc, n, 90, sprintf( ...
    ['Only %d .m files found under %s. The toolbox has 83 public functions, ', ...
     'seven private helpers and eleven demos, so the search is not reaching ', ...
     'them. Raise this floor once the file count is stable.'], ...
    n, tc.TestData.root));
end

function testEveryToolboxCallResolves(tc)
% A misspelled fmri_* name parses fine and fails only at run time. The
% real-data demo takes 85 minutes to reach its last section, so a typo there is
% expensive to find by running the thing.
%
% Resolution is checked against the FILE LIST, not which(). which() cannot see
% core/private - that is the point of a private folder, and fmritoolbox_setup
% deliberately keeps it off the path - so a which()-based check reports every
% private helper (fmri_asvoxtime, fmri_restoreformat, fmri_bwlabel3d,
% fmri_actmask, fmri_ticklabel) as undefined, and reports each file's own
% declaration line as a call to an undefined function.
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