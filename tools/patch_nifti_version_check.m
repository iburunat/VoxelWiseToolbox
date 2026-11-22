function patch_nifti_version_check(nifti_dir)
% PATCH_NIFTI_VERSION_CHECK  Fixes the MATLAB-version check bug in NIFTI_20130306.
%
% The bundled NIFTI toolbox decides how to read/write header CHAR fields with:
%
%     v6 = version;
%     if str2num(v6(1)) < 6      % <-- only the FIRST character of the version
%        directchar = '*char';
%     else
%        directchar = 'uchar=>char';
%     end
%
% The original check reads only the first digit of the MATLAB version. For
% releases numbered 23.x or later, this incorrectly interprets the version as
% earlier than 6 and selects the legacy '*char' format. This can corrupt NIfTI
% header fields such as 'descrip' and 'magic', potentially causing the file to
% be misidentified or read incorrectly.
%
% This script rewrites every occurrence to parse the full major version:
%
%     v6 = version;
%     parts = strsplit(v6, '.');
%     if str2double(parts{1}) < 6
%        ...
%
% Usage:
%   patch_nifti_version_check('external/NIFTI_20130306')
%
% It edits files in place, saving a .bak copy of each first. Safe to re-run:
% already-patched files are skipped.
%
% Credit: the diagnosis and fix are due to Alan Miranda (MATLAB File Exchange
% comment on "Tools for NIfTI and ANALYZE image", 2024).

if nargin < 1 || isempty(nifti_dir)
    error('Provide the path to the NIFTI toolbox folder, e.g. external/NIFTI_20130306');
end
if ~exist(nifti_dir, 'dir')
    error('Directory not found: %s', nifti_dir);
end

files = dir(fullfile(nifti_dir, '*.m'));
n_patched = 0;
n_occ = 0;

for k = 1:numel(files)
    fpath = fullfile(files(k).folder, files(k).name);
    txt = fileread(fpath);

    % Match the buggy check in its common whitespace variants:
    %   str2num(v6(1))<6   or   str2num(v6(1)) < 6
    pat = 'str2num\(\s*v6\(1\)\s*\)\s*<\s*6';
    if isempty(regexp(txt, pat, 'once'))
        continue
    end

    % Replace the line   v6 = version;   with the version + split, then swap
    % the comparison. We do it in two steps so both halves stay consistent.
    new = txt;

    % 1) ensure a split line follows 'v6 = version;' (only if not already there)
    if isempty(strfind(new, 'strsplit(v6'))
        new = regexprep(new, ...
            '(v6\s*=\s*version\s*;)', ...
            '$1\n    v6parts = strsplit(v6, ''.'');');
    end

    % 2) replace the comparison
    new = regexprep(new, pat, 'str2double(v6parts{1}) < 6');

    if ~strcmp(new, txt)
        copyfile(fpath, [fpath '.bak']);
        fid = fopen(fpath, 'w');
        fwrite(fid, new);
        fclose(fid);
        occ = numel(regexp(txt, pat));
        n_patched = n_patched + 1;
        n_occ = n_occ + occ;
        fprintf('Patched %-28s (%d occurrence%s)\n', ...
                files(k).name, occ, plural(occ));
    end
end

fprintf('\nDone. Patched %d file(s), %d occurrence(s) total.\n', n_patched, n_occ);
if n_patched == 0
    fprintf('No unpatched occurrences found (already fixed, or different NIFTI version).\n');
else
    fprintf('Original files saved with a .bak extension.\n');
    fprintf('Verify, then delete the .bak files when satisfied.\n');
end
end

function s = plural(n)
if n == 1, s = ''; else, s = 's'; end
end