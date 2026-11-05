function s = count_lines(folder, pattern, recurse, exclude)
% COUNT_LINES  Counts lines of code per .m file in a folder.
%
% Counts non-blank, non-comment lines. This is the metric quoted in the
% VoxelWise Toolbox paper, defined here so that the figures can be
% reproduced and compared against any other codebase.
%
% Usage:
%   s = count_lines(folder)
%   s = count_lines(folder, pattern, recurse)
%
% Inputs:
%   FOLDER  - Directory to scan.
%   PATTERN - File mask. Default: '*.m'.
%   RECURSE - Include subfolders (0/1). Default: 0.
%
% Outputs:
%   S - Struct with .nfiles, .total, .median, .mean, .max, .maxfile and the
%       per-file counts in .n.
%
% Examples:
%   vw  = count_lines(fullfile(fileparts(which('fmritoolbox_setup')), 'core'), 'fmri_*.m');
%   spm = count_lines(fileparts(which('spm')), '*.m', 1);

if nargin < 2 || isempty(pattern), pattern = '*.m'; end
if nargin < 3 || isempty(recurse), recurse = 0;     end
if nargin < 4, exclude = {}; end

if recurse
    d = dir(fullfile(folder, '**', pattern));
else
    d = dir(fullfile(folder, pattern));
end
d = d(~[d.isdir]);
if ~isempty(exclude)
    drop = false(size(d));
    for e = string(exclude)
        drop = drop | contains({d.folder}', filesep + e);
    end
    d = d(~drop);
end

n = zeros(numel(d), 1);
for k = 1:numel(d)
    L    = strtrim(splitlines(string(fileread(fullfile(d(k).folder, d(k).name)))));
    L    = L(L ~= "" & ~startsWith(L, "%"));
    n(k) = numel(L);
end

[mx, i] = max(n);
s = struct('nfiles', numel(d), 'total', sum(n), 'median', median(n), ...
           'mean', mean(n), 'max', mx, 'maxfile', d(i).name, 'n', n);

fprintf('%5d files | %8d lines | median %4d | mean %6.1f | max %5d (%s)\n', ...
        s.nfiles, s.total, s.median, s.mean, s.max, s.maxfile);
end