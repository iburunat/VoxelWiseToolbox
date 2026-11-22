function v = fmri_vol2vect(vol, mask)
% FMRI_VOL2VECT  Vectorizes a 91x109x91 brain volume to a 228453-element vector.
%
% Extracts the brain voxels from a 3D or 4D volume array, returning a compact
% matrix in which each row is a brain voxel. Non-brain voxels (outside the
% standard MNI152 2mm brain mask) are discarded. This is the canonical data
% format used throughout the toolbox.
%
% Usage:
%   v = fmri_vol2vect(vol)
%   v = fmri_vol2vect(vol, mask)
%
% Inputs:
%   VOL   - Volume array of size (91 x 109 x 91) or (91 x 109 x 91 x T).
%           Must match the standard MNI152 2mm grid exactly.
%   MASK  - Binary brain mask (91 x 109 x 91). Optional. If omitted, the
%           standard toolbox brain mask (standard_brain_NZ.mat) is used.
%
% Outputs:
%   V     - Vectorized data: (228453 x 1) for a single volume,
%           or (228453 x T) for a time series.
%
% Examples:
%   v   = fmri_vol2vect(volume);             % standard mask
%   v   = fmri_vol2vect(timeseries_4d);      % 228453 x T
%   v   = fmri_vol2vect(volume, my_mask);    % custom mask
%
% Notes:
%   The standard brain mask defines 228453 in-brain voxels from the
%   91x109x91 MNI152 2mm template (total voxels: 902,629). 
%
% See also: fmri_vect2vol, fmri_maskdata, fmri_readnii

% Validate all three spatial dimensions together. Using ISEQUAL avoids the
% element-wise behaviour of ~= and ensures that any size mismatch is detected.
if ~isequal([size(vol,1) size(vol,2) size(vol,3)], [91 109 91])
    error('fmri_vol2vect:badSize', ...
          'Input size must be 91x109x91xN. Got: %dx%dx%d.', ...
          size(vol,1), size(vol,2), size(vol,3));
end

if nargin == 1
    load standard_brain_NZ % supplies A, the 91x109x91 binary brain mask
    mask = A(:);
else
    if numel(mask) ~= 91*109*91
        error('fmri_vol2vect:badMask', ...
              'MASK must have 91*109*91 = 902629 elements, got %d.', numel(mask));
    end
    mask = mask(:);
end
ind = find(mask > 0);

s1 = size(vol,1); s2 = size(vol,2);
s3 = size(vol,3); s4 = size(vol,4);

vd = reshape(vol, s1*s2*s3, s4);
v  = vd(ind, :);
end