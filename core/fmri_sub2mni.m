function mni = fmri_sub2mni(sub)
% FMRI_SUB2MNI  Converts voxel subscripts to MNI coordinates (mm).
%
% Converts one or more voxel indices (in the 91x109x91 MATLAB 1-based
% subscript space) to MNI152 coordinates in millimetres, using the standard
% 2mm isotropic MNI152 template origin.
%
% Usage:
%   mni = fmri_sub2mni(sub)
%
% Inputs:
%   SUB  - Voxel subscripts, (N x 3) matrix: [x1 y1 z1; x2 y2 z2; ...].
%          Subscripts are 1-based (MATLAB convention), x in [1 91],
%          y in [1 109], z in [1 91].
%
% Outputs:
%   MNI  - MNI coordinates in mm, (N x 3) matrix: [x1 y1 z1; ...].
%          MNI [0 0 0] corresponds to subscript [46 64 37].
%
% Examples:
%   mni = fmri_sub2mni([46 64 37]);       % returns [0 0 0]
%   mni = fmri_sub2mni([46 64 37; 1 1 1])
%
% Notes:
%   Origin is [46 64 37] (1-indexed), corresponding to the MNI152 2mm
%   anterior commissure. Voxel size is 2mm isotropic.
%   Inverse function: fmri_mni2sub.
%
% See also: fmri_mni2sub, fmri_mni2tal, fmri_ind2sub, fmri_regionnumber

if isempty(sub)
    mni = zeros(0, 3);
    return
end

if size(sub, 2) ~= 3
    error('fmri_sub2mni:badSize', ...
          ['SUB must be an N x 3 matrix of [x y z] subscripts; got %d columns.\n' ...
           'A single coordinate is [x y z], not a column.'], size(sub,2));
end

if any(sub(:,1) < 1 | sub(:,1) > 91) || ...
   any(sub(:,2) < 1 | sub(:,2) > 109) || ...
   any(sub(:,3) < 1 | sub(:,3) > 91)
    warning('fmri_sub2mni:outOfBounds', ...
            ['Some subscripts fall outside the 91x109x91 volume. ' ...
             'The conversion is still applied, but the result is ' ...
             'extrapolated beyond the template.']);
end

voxel_size = 2;
orig       = [46 64 37];
mni        = (sub - orig) * voxel_size;   % implicit expansion, R2016b+