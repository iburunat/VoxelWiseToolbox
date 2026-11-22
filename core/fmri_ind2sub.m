function sub = fmri_ind2sub(ind)
% FMRI_IND2SUB  Converts linear brain indices to voxel subscripts.
%
% Converts one or more linear indices in the 228453-element vectorized brain
% space to voxel subscripts [x y z] in the 91x109x91 volume space.
%
% Usage:
%   sub = fmri_ind2sub(ind)
%
% Inputs:
%   IND  - Linear brain indices, vector of length N. Values in [1, 228453].
%
% Outputs:
%   SUB  - Subscript matrix (N x 3): [x1 y1 z1; x2 y2 z2; ...].
%          1-based MATLAB indices in the 91x109x91 volume.
%
% Examples:
%   sub  = fmri_ind2sub(91567);        % MNI origin [0 0 0].
%   subs = fmri_ind2sub([1000; 5000; 100000]);
%   mni  = fmri_sub2mni(fmri_ind2sub(peak_voxel));
%
% Notes:
%   The mask is cached between calls, so the first call in a session is
%   slower than subsequent ones.
%
% See also: fmri_sub2ind, fmri_sub2mni, fmri_regionnumber

persistent vol_inds

if isempty(ind)
    sub = zeros(0, 3);
    return
end

ind = ind(:);
if any(ind < 1) || any(ind > 228453) || any(mod(ind,1) ~= 0)
    error('fmri_ind2sub:badIndex', ...
          ['IND must contain whole numbers in the range 1 to 228453; ' ...
           'got values from %g to %g.\n' ...
           'These are indices into the vectorized brain, not into the ' ...
           '91x109x91 volume.'], min(ind), max(ind));
end

% The mask maps vectorized position -> volume position. It is cached because
% this function is often called inside a loop, and reloading a 902,629-element
% array every time costs far more than the conversion itself.
if isempty(vol_inds)
    S = load('standard_brain_NZ'); % supplies A, the 91x109x91 binary brain mask
    vol_inds = find(S.A(:) > 0);    % same mapping used by fmri_vect2vol
end

vol_idx   = vol_inds(ind);
[x, y, z] = ind2sub([91 109 91], vol_idx);
sub = [x y z];