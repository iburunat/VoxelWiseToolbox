%% FMRITOOLBOX_SETUP  Add VoxelWise Toolbox and dependencies to the MATLAB path.
%
% Run this script once per MATLAB session before using the toolbox.
% Alternatively, add the call to your startup.m file for automatic loading.
%
% Usage:
%   Run this script from the VoxelWise Toolbox root directory, or provide the
%   full path:
%       run('/path/to/VoxelWiseToolbox/fmritoolbox_setup.m')
%
% Requirements:
%   - MATLAB R2019a or later. R2019a is the release in which xcorr, used by
%     fmri_effdf, moved into base MATLAB from the Signal Processing Toolbox.
%     No MathWorks toolbox is required for any function.
%   - No external dependencies. The toolbox is self-contained: cluster
%     labelling (used by fmri_cleanclusters, fmri_findclusters, fmri_tfce,
%     fmri_csdist, fmri_regiontable, fmri_acfestimate, fmri_csthreshold) is
%     provided by fmri_bwlabel, a pure-MATLAB implementation. SPM is not
%     required and is not used by any function in this toolbox.
%
% See also: fmri_readnii, fmri_showslices, fmri_corregressor

% ── Toolbox root ──────────────────────────────────────────────────────────
toolbox_root = fileparts(mfilename('fullpath'));
if isempty(toolbox_root)
    toolbox_root = pwd;
end
addpath(toolbox_root);

% ── core (all public fmri_*.m functions) ─────────────────────────────────
core_path = fullfile(toolbox_root, 'core');
if exist(core_path, 'dir')
    addpath(core_path);
else
    error('fmritoolbox_setup:noCore', ...
        ['core/ not found at:\n  %s\n' ...
         'Every toolbox function lives there, so nothing will work.\n' ...
         'Check that fmritoolbox_setup.m is being run from the toolbox root.'], ...
        core_path);
end

% Add tools/
tools_path = fullfile(toolbox_root, 'tools');
if exist(tools_path, 'dir')
    addpath(tools_path);
else
    warning('fmritoolbox_setup:noTools', ...
        'tools/ not found at:\n  %s', tools_path);
end


% ── NIFTI I/O dependency (bundled) ────────────────────────────────────────
nifti_path = fullfile(toolbox_root, 'external', 'NIFTI_20130306');
if exist(nifti_path, 'dir')
    addpath(nifti_path);
else
    warning('fmritoolbox_setup:noNIfTI', ...
        ['NIFTI_20130306 not found at:\n  %s\n' ...
         'NIfTI read/write (fmri_readnii, fmri_export) will not work.\n' ...
         'Download from: https://www.mathworks.com/matlabcentral/fileexchange/8797'], ...
        nifti_path);
end

% ── masks (brain masks, rendering meshes) ──────────────────────────────
masks_path = fullfile(toolbox_root, 'masks');
if exist(masks_path, 'dir')
    addpath(masks_path);
end

% ── Demos ─────────────────────────────────────────────────────────────────
demo_path = fullfile(toolbox_root, 'demo');
if isfolder(demo_path)
    addpath(demo_path);
    sf_path = fullfile(demo_path, 'studyforrest');
    if isfolder(sf_path), addpath(sf_path); end
else
    demo_path = '';
    warning('fmritoolbox_setup:noDemos', ...
        ['demo/ not found at:\n  %s\n' ...
         'The toolbox will work, but the demo scripts will not be on the ' ...
         'path.'], fullfile(toolbox_root, 'demo'));
end

if ~isempty(demo_path)
    sf_path = fullfile(demo_path, 'studyforrest');
    if isfolder(sf_path), addpath(sf_path); end
end
    
% ── Atlases  ──────────────────────────────────────────────────────────────
atlas_path = fullfile(toolbox_root, 'atlases');
if exist(atlas_path, 'dir')
    addpath(atlas_path);
end

% ── private folder sanity check ──────────────────────────────────────────
% If core/private has been added to the path (usually by someone running
% addpath(genpath(...))) MATLAB will warn and the internal helpers become
% globally visible, which defeats the point of hiding them. Detect and undo it.
priv_path = fullfile(toolbox_root, 'core', 'private');
if exist(priv_path, 'dir') && contains(path, priv_path)
    rmpath(priv_path);
    warning('fmritoolbox_setup:privateOnPath', ...
        ['core/private was on the MATLAB path and has been removed.\n' ...
         'Private folders must never be added explicitly - MATLAB makes them\n' ...
         'visible to core/ automatically. This usually happens when someone\n' ...
         'calls addpath(genpath(toolbox_root)); use fmritoolbox_setup instead.']);
end

% ── NIfTI library check ──────────────────────────────────────────────────
% fmri_checknifti verifies that the bundled, patched NIfTI library is present
% and has not been replaced by an unpatched copy. Run it after adding core/ 
% to the path, because that is where the function is located. It returns 
% silently when all checks pass and does not modify any files.
if exist('fmri_checknifti', 'file') == 2
    fmri_checknifti();
end

% ── SPM check (informational only) ─────────────────────────────────────────
% The toolbox has no dependency on SPM (see Requirements above). This check
% only avoids confusion if SPM happens to be on the path already.
if exist('spm_bwlabel', 'file')
    fprintf(['Note: SPM is on your path, but is not used by this toolbox.\n' ...
             '      Cluster labelling uses fmri_bwlabel (pure MATLAB).\n']);
end

% ── Done ──────────────────────────────────────────────────────────────────
fprintf('\nVoxelWise Toolbox loaded from: %s\n', toolbox_root);
fprintf('Run ''help fmri_readnii'' to get started.\n');
fprintf('Open demo/demo_preprocessing.m for a guided walkthrough.\n\n');
clear toolbox_root core_path nifti_path masks_path demo_path atlas_path priv_path tools_path sf_path