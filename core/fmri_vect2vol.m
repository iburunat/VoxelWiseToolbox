function vol = fmri_vect2vol(v, mask)
% FMRI_VECT2VOL  Devectorizes a 228453-element brain vector to a 91x109x91 volume.
%
% Reconstructs a full 3D (or 4D) volume array from vectorized brain data by
% placing each value back into its corresponding voxel position. The inverse
% of fmri_vol2vect.
%
% Usage:
%   vol = fmri_vect2vol(v)
%   vol = fmri_vect2vol(v, mask)
%
% Inputs:
%   V     - Vectorized brain data: (228453 x 1) for a single map, or
%           (228453 x T) for a time series. A transposed (1 x 228453) input
%           is automatically corrected.
%   MASK  - Binary brain mask (91 x 109 x 91). Optional. If omitted, the
%           standard toolbox brain mask (standard_brain_NZ.mat) is used.
%
% Outputs:
%   VOL   - Volume array: (91 x 109 x 91) for single map,
%           or (91 x 109 x 91 x T) for time series. Voxels outside the
%           brain mask are set to zero.
%
% Examples:
%   vol  = fmri_vect2vol(v);              % standard mask
%   vol4 = fmri_vect2vol(timeseries);     % 91x109x91xT
%   vol  = fmri_vect2vol(v, my_mask);     % custom mask
%
% See also: fmri_vol2vect, fmri_showslices, fmri_show3d

% Transpose a T x 228453 input to the canonical voxels-by-time orientation.
% Issue a warning because a transposed input may indicate an unintended data
% layout.
if size(v, 2) == 228453 && size(v, 1) ~= 228453
    if size(v, 1) > 1
        warning('fmri_vect2vol:transposed', ...
                ['Input is %d x 228453; the canonical orientation is ' ...
                 '228453 x %d (voxels by time). Transposing.'], ...
                size(v,1), size(v,1));
    end
    v = v';
end

if nargin == 1 && size(v, 1) ~= 228453
    error('fmri_vect2vol:badSize', ...
          ['Input must have 228453 rows (brain voxels); got %d.\n' ...
           'For custom masks, pass the corresponding mask as the second input.'], ...
          size(v,1));
end

if nargin == 1
    load standard_brain_NZ % supplies A, the 91x109x91 binary brain mask
    mask = A(:);
else
    if numel(mask) ~= 91*109*91
        error('fmri_vect2vol:badMask', ...
              'MASK must have 91*109*91 = 902629 elements, got %d.', numel(mask));
    end
    mask = mask(:);
end
ind = find(mask > 0);

if numel(ind) ~= size(v,1)
    error('fmri_vect2vol:maskMismatch', ...
          ['MASK selects %d voxels but the data has %d rows.\n' ...
           'The mask must be the one used to vectorize this data.'], ...
          numel(ind), size(v,1));
end

nic = size(v, 2);
vv  = zeros(size(mask,1), nic);
vv(ind, :) = v;
vol = reshape(vv, 91, 109, 91, nic);
end