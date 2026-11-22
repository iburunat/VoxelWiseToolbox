function fmri_export(voldata, filename, voxelsize, origin)
% FMRI_EXPORT  Saves 3D or 4D volume data as a NIfTI file (.nii).
%
% Saves a MATLAB volume array as a NIfTI file, with optional control over
% the output filename, voxel size, and origin. Accepts both 4D volume data
% and vectorized (228453 x T) data.
%
% Usage:
%   fmri_export(voldata)
%   fmri_export(voldata, filename)
%   fmri_export(voldata, filename, voxelsize)
%   fmri_export(voldata, filename, voxelsize, origin)
%
% Inputs:
%   VOLDATA    - 3D (91x109x91) or 4D (91x109x91xT) volume, or vectorized
%                (228453 x T) data. Vectorized input is converted automatically.
%   FILENAME   - Output filename string. The .nii extension is added if absent.
%                Default: 'output'
%   VOXELSIZE  - Voxel dimensions in mm, [dx dy dz]. Default: [2 2 2]
%   ORIGIN     - Voxel index of MNI coordinate [0 0 0], [ox oy oz], 1-based
%                (MATLAB convention) - make_nii writes it to the Analyze
%                "originator" field, which is 1-based, so a 0-based value
%                shifts the whole image by one voxel.
%                Default: [46 64 37]  (standard 2mm MNI152 origin)
%
% Examples:
%   fmri_export(statmap, 'tmap')
%   fmri_export(statmap, 'tmap_1mm', [1 1 1])
%   fmri_export(voldata, 'bold', [2 2 2], [46 64 37])
%
% See also: fmri_readnii, fmri_vect2vol

% --- defaults ---------------------------------------------------------
if nargin < 4 || isempty(origin),    origin    = [46 64 37]; end   % 1-based MNI origin
if nargin < 3 || isempty(voxelsize), voxelsize = [2 2 2];    end
if nargin < 2 || isempty(filename),  filename  = 'output';   end

% --- input handling ---------------------------------------------------
if ndims(voldata) < 3
    voldata = fmri_vect2vol(voldata);
end

% Ensure .nii extension
[~, ~, ext] = fileparts(filename);
if isempty(ext)
    filename = [filename '.nii'];
end

% --- save -------------------------------------------------------------
nii = make_nii(double(voldata), voxelsize, origin);
save_nii(nii, filename);