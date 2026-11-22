function fmri_checknifti()
% FMRI_CHECKNIFTI  Warns if the bundled NIFTI toolbox is missing or unpatched.
%
% This does NOT modify any files. It is a read-only sanity check, intended to be
% called once from fmritoolbox_setup.m. Its only job is to catch the situation
% where someone has replaced the bundled, patched external/NIFTI_20130306 with a
% fresh unpatched download, which would silently corrupt header reads on
% MATLAB R2023b and later (see patch_nifti_version_check for the details).
%
% The actual fix is applied once, before release, and committed to the
% repository; external/NIFTI_20130306/PATCH_NOTES.md records what was changed.
% This function never patches anything at runtime; it only warns.
%
% Usage:
%   fmri_checknifti
%
% Examples:
%   fmri_checknifti     % run the check; silent when the bundled copy is fine
%
%   % It is called for you by the setup script, so in normal use this is
%   % the only place it needs to appear:
%   fmritoolbox_setup
%
% See also: patch_nifti_version_check, fmritoolbox_setup

% ---- is the NIFTI toolbox on the path at all? -------------------------
if isempty(which('load_untouch_nii'))
    warning('fmri:niftiMissing', ...
        ['The bundled NIFTI toolbox is not on the MATLAB path. NIfTI input/\n' ...
         'output functions (e.g. fmri_tomni152, fmri_readnii) will not work.\n' ...
         'Run fmritoolbox_setup from the toolbox root to add it.']);
    return
end

% ---- is the version-check fix present? --------------------------------

hdr_fn = which('load_untouch_nii_hdr');
if isempty(hdr_fn), return; end
nifti_dir = fileparts(hdr_fn);

txt = fileread(hdr_fn);
buggy = ~isempty(regexp(txt, 'str2num\(\s*v6\(1\)\s*\)\s*<\s*6', 'once'));

if buggy
    % This problem only affects certain MATLAB versions.
    % The original NIFTI code checks only the first character of the MATLAB
    % version number. This means newer year-based releases (R2023b and later)
    % are incorrectly identified, and older releases (up to R2023a) work
    % correctly.
    ver_str  = version;
    affected = str2double(ver_str(1)) < 6;
    if affected
        warning('fmri:niftiUnpatched', ...
            ['The bundled NIFTI toolbox contains the MATLAB-version-check bug and\n' ...
             'you are on MATLAB %s, which is AFFECTED: header text fields may read\n' ...
             'incorrectly. Apply the fix once:\n' ...
             '    patch_nifti_version_check(''%s'')\n' ...
             'See external/NIFTI_20130306/PATCH_NOTES.md.'], ver_str, nifti_dir);
    else
        warning('fmri:niftiUnpatched', ...
            ['The bundled NIFTI toolbox contains the MATLAB-version-check bug.\n' ...
             'Your MATLAB (%s) is not affected, but a newer release would be.\n' ...
             'Apply the fix once:\n' ...
             '    patch_nifti_version_check(''%s'')\n' ...
             'See external/NIFTI_20130306/PATCH_NOTES.md.'], ver_str, nifti_dir);
    end
end
end