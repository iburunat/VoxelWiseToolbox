function s = fmri_spheremask(center, radius)
% FMRI_SPHEREMASK  Spherical ROI mask centred on a given voxel.
%
% Creates a vectorized binary brain mask (228453 x 1) where all voxels
% within a sphere of the specified radius around the centre voxel are set
% to 1. Useful for creating seed regions for connectivity analyses.
%
% Usage:
%   s = fmri_spheremask(center, radius)
%
% Inputs:
%   CENTER  - Centre of the sphere as voxel subscripts [x y z] (1 x 3),
%             or as a linear brain index (scalar). For MNI coordinates,
%             first convert: center = fmri_mni2sub([x y z]).
%   RADIUS  - Sphere radius in voxels (1 voxel = 2mm). Default: 2 (= 4mm).
%
% Outputs:
%   S  - Binary brain mask (228453 x 1). 1 = inside sphere.
%
% Examples:
%   % 10mm sphere at MNI [20 -58 18]
%   mask = fmri_spheremask(fmri_mni2sub([20 -58 18]), 5);
%
%   % Seed time series for FC
%   seed_ts = mean(data(logical(mask), :), 1);
%   r = fmri_corregressor(seed_ts', data);
%
% See also: fmri_regionmask, fmri_mni2sub, fmri_corregressor

if nargin == 1, r=2;
else
    r=radius;
end

if size(center,2)<3, 
    coords=fmri_ind2sub(center);
else
    coords=center;
end

%------conceptually simple way (admits non-integer radii)
cx = coords(1); cy = coords(2); cz = coords(3);
if cx < 1 || cx > 91 || cy < 1 || cy > 109 || cz < 1 || cz > 91
    warning('fmri_spheremask:centreOutOfGrid', ...
            ['Centre [%g %g %g] is outside the 91x109x91 grid; the sphere ' ...
             'will be empty or clipped.'], cx, cy, cz);
end
[x1,y1,z1] = ndgrid(1:91, 1:109, 1:91);
svol = sqrt((x1-cx).^2 + (y1-cy).^2 + (z1-cz).^2) <= r;
s=fmri_vol2vect(svol);

end