function sub = fmri_mni2sub(mni)
% FMRI_MNI2SUB  Converts MNI coordinates (mm) to voxel subscripts.
%
% Converts one or more MNI152 coordinates (in mm) to voxel subscripts in the
% 91x109x91 MATLAB 1-based subscript space, using the standard 2mm MNI152
% template. Rounds to the nearest voxel centre.
%
% Usage:
%   sub = fmri_mni2sub(mni)
%
% Inputs:
%   MNI  - MNI coordinates in mm, (N x 3) matrix: [x1 y1 z1; x2 y2 z2; ...].
%
% Outputs:
%   SUB  - Voxel subscripts (rounded), (N x 3) matrix: [x y z].
%          1-based MATLAB indices, x in [1 91], y in [1 109], z in [1 91].
%
% Examples:
%   sub = fmri_mni2sub([0 0 0]);             % returns [46 64 37]
%   sub = fmri_mni2sub([-42 -18 60]);        % motor cortex
%   mask = fmri_spheremask(fmri_mni2sub([20 -58 18]), 5);
%
% Notes:
%   MNI [0 0 0] maps to subscript [46 64 37].
%   Coordinates outside the brain volume are not clipped — use with care.
%   Inverse function: fmri_sub2mni.
%
% See also: fmri_sub2mni, fmri_mni2tal, fmri_spheremask, fmri_regionmask

if isempty(mni)
    sub = zeros(0, 3);
    return
end

if size(mni, 2) ~= 3
    error('fmri_mni2sub:badSize', ...
          ['MNI must be an N x 3 matrix of [x y z] coordinates in mm; ' ...
           'got %d columns.\n' ...
           'A single coordinate is [x y z], not a column.'], size(mni,2));
end

voxel_size = 2;
orig       = [46 64 37];
sub        = round(mni / voxel_size + orig);   % implicit expansion, R2016b+

if any(sub(:,1) < 1 | sub(:,1) > 91) || ...
   any(sub(:,2) < 1 | sub(:,2) > 109) || ...
   any(sub(:,3) < 1 | sub(:,3) > 91)
    warning('fmri_mni2sub:outOfBounds', ...
            ['Some coordinates fall outside the MNI152 field of view ' ...
             '(x -90 to 90, y -126 to 90, z -72 to 108 mm).\n' ...
             'The resulting subscripts are outside the 91x109x91 volume.']);
end