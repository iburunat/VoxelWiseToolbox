function D = fmri_voxdist(ind1, ind2)
% FMRI_VOXDIST  Euclidean distance (mm) between brain voxels.
%
% Computes the pairwise Euclidean distance in millimetres between two sets
% of voxels specified as linear brain indices (228453-space). Returns a
% distance matrix D where D(i,j) is the distance between voxel ind1(i) and
% ind2(j) in mm (at 2mm isotropic voxel size).
%
% Usage:
%   D = fmri_voxdist(ind1, ind2)
%   D = fmri_voxdist(ind1)        % pairwise distances within ind1
%
% Inputs:
%   IND1  - Linear brain indices, vector of length N. Values in [1, 228453].
%   IND2  - Linear brain indices, vector of length M. Default: IND2 = IND1.
%
% Outputs:
%   D     - Distance matrix (N x M) in millimetres. D(i,j) = distance
%           between voxel ind1(i) and ind2(j).
%           If ind2 = ind1, D is symmetric with zeros on the diagonal.
%
% Examples:
%   % Distance between two peak voxels
%   d = fmri_voxdist(peak1, peak2);
%
%   % Pairwise distances within a cluster
%   cluster_ind = find(cluster_map > 0);
%   D = fmri_voxdist(cluster_ind);
%   max_diam = max(D(:));
%
%   % Distance from seed voxel to all brain voxels
%   seed = fmri_sub2ind(fmri_mni2sub([0 -51 27]));
%   D    = fmri_voxdist(seed, 1:228453);
%   fmri_showslices(D', 1, 3, [0 100])
%
% Notes:
%   Voxel size is 2mm isotropic. Distance is in millimetres.
%   For large index sets this function can be memory-intensive;
%   consider working in chunks for whole-brain distance matrices.
%
% See also: fmri_spheremask, fmri_mni2sub, fmri_ind2sub

if nargin < 2
    ind2 = ind1;
end

N = numel(ind1);
M = numel(ind2);

% The output is an N x M double matrix and can require substantial memory
% for large inputs. For example, 20,000 x 20,000 distances require about
% 3.2 GB, while a whole-brain matrix would require about 418 GB. Warn before
% allocating very large outputs so users can reduce or divide the calculation.
bytes = N * M * 8;
if bytes > 2e9
    warning('fmri_voxdist:largeOutput', ...
            ['This will produce a %d x %d distance matrix (%.1f GB).\n' ...
             'Consider working in chunks, or passing a seed voxel as IND1 ' ...
             'to get distances from a single point.'], N, M, bytes/1e9);
end

% Convert voxel subscripts directly to millimetres. fmri_ind2sub has already
% validated the input indices.
sub1 = fmri_ind2sub(ind1(:));   % N x 3
sub2 = fmri_ind2sub(ind2(:));   % M x 3
mm1  = sub1 * 2;
mm2  = sub2 * 2;

% Compute pairwise Euclidean distances. The coordinate-system origin is not
% needed because its offset cancels when coordinates are subtracted. Implicit
% expansion requires MATLAB R2016b or later.
D = sqrt( (mm1(:,1) - mm2(:,1)').^2 + ...
          (mm1(:,2) - mm2(:,2)').^2 + ...
          (mm1(:,3) - mm2(:,3)').^2 );   % N x M