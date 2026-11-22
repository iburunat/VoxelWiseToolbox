function [dice, overlap_map] = fmri_dicemirror(mask)
% FMRI_DICEMIRROR  Mirrored Dice coefficient of a binary brain mask.
%
% Measures the bilateral symmetry of a brain mask by computing the Dice
% coefficient between the mask and its left-right mirror image. A value of
% 1 means the mask is perfectly symmetric; 0 means no overlap with its mirror.
%
%   Dice = 2 * |A n mirror(A)| / (|A| + |mirror(A)|)      (n = intersection)
%
% The MNI152 brain mask is not perfectly symmetric, so voxels whose mirrored
% position falls outside it are dropped by fmri_mirror and the two masks can
% differ in size. The full formula above is therefore used; the symmetric
% shortcut |A n mirror(A)| / |A| would underestimate Dice.
% 
% Usage:
%   [dice, overlap_map] = fmri_dicemirror(mask)
%
% Inputs:
%   MASK  - Binary brain mask, vectorized (228453 x 1).
%
% Outputs:
%   DICE         - Mirrored Dice coefficient (scalar, range [0 1]).
%   OVERLAP_MAP  - Binary map (228453 x 1): 1 where mask and mirror overlap.
%
% Examples:
%   % Symmetry of left hippocampus mask
%   mask = fmri_regionmask(57, 1);   % L hippocampus
%   [d, ov] = fmri_dicemirror(mask);
%   fprintf('Mirrored Dice: %.3f\n', d)
%
%   % Symmetry of a bilateral activation cluster
%   [d, ov] = fmri_dicemirror(thresh_map);
%
% See also: fmri_mirror, fmri_regionmask, fmri_spheremask

mask        = logical(mask(:));
mirror_mask = logical(fmri_mirror(double(mask)));

intersection = mask & mirror_mask;
% Full Dice: mirroring can drop voxels whose reflected position falls outside
% the brain mask, so the two masks may differ in size (see fmri_mirror).
dice         = 2 * nnz(intersection) / (nnz(mask) + nnz(mirror_mask));
overlap_map  = double(intersection);