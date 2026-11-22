function ind = fmri_sub2ind(sub)
% FMRI_SUB2IND  Converts voxel subscripts to linear brain indices.
%
% Converts one or more voxel subscripts [x y z] in the 91x109x91 volume
% space to linear indices in the 228453-element vectorized brain space.
%
% Usage:
%   ind = fmri_sub2ind(sub)
%
% Inputs:
%   SUB  - Subscript matrix (N x 3): [x1 y1 z1; x2 y2 z2; ...].
%          1-based MATLAB indices in the 91x109x91 volume.
%
% Outputs:
%   IND  - Linear brain indices (N x 1). Values in [1, 228453].
%          Returns NaN for subscripts outside the brain mask.
%
% Examples:
%   ind  = fmri_sub2ind([46 64 37]);        % centre of the brain
%   inds = fmri_sub2ind([46 64 37; 30 50 45]);
%
% See also: fmri_ind2sub, fmri_mni2sub, fmri_spheremask

persistent vol_inds

if isempty(sub)
    ind = zeros(0, 1);
    return
end

if size(sub, 2) ~= 3
    error('fmri_sub2ind:badSize', ...
          ['SUB must be an N x 3 matrix of [x y z] subscripts; got %d columns.\n' ...
           'A single coordinate is [x y z], not a column.'], size(sub,2));
end

sub = round(sub);
if any(sub(:,1) < 1 | sub(:,1) > 91) || ...
   any(sub(:,2) < 1 | sub(:,2) > 109) || ...
   any(sub(:,3) < 1 | sub(:,3) > 91)
    error('fmri_sub2ind:outOfBounds', ...
          ['SUB must lie within the 91x109x91 volume.\n' ...
           'To convert from MNI millimetres use fmri_mni2sub.']);
end

% Cache the vectorized brain-mask indices to avoid reloading and rebuilding
% them on every call.
if isempty(vol_inds)
    S = load('standard_brain_NZ'); % supplies A, the 91x109x91 binary brain mask
    vol_inds = find(S.A(:) > 0);   % vol_inds(k) = volume index of brain voxel k
end

% Convert subscripts to volume indices
vol_idx = sub2ind([91 109 91], sub(:,1), sub(:,2), sub(:,3));

% Map each volume index to its position in the vectorized brain mask.
% ISMEMBER processes all indices in one operation.
[found, ind] = ismember(vol_idx, vol_inds);
ind = double(ind);
ind(~found) = NaN;   % outside brain mask
ind = ind(:);