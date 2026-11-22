function newpmap = fmri_cleanclusters(pmap, CL_SIZE_THRES, NN_THRES, CONN)
% FMRI_CLEANCLUSTERS  Removes small and sparse clusters from a thresholded map.
%
% Discards clusters smaller than CL_SIZE_THRES voxels, then optionally removes
% voxels with too few neighbours inside their own cluster, which strips off
% isolated or spiky voxels.
%
% Usage:
%   newpmap = fmri_cleanclusters(pmap, CL_SIZE_THRES, NN_THRES)
%   newpmap = fmri_cleanclusters(pmap, CL_SIZE_THRES, NN_THRES, CONN)
%
% Inputs:
%   PMAP           - Thresholded binary brain map, vectorized (228453 x 1)
%                    or volume (91 x 109 x 91).
%   CL_SIZE_THRES  - Minimum cluster size in voxels. Use fmri_csthreshold for
%                    a statistically motivated value.
%   NN_THRES       - Minimum neighbours a voxel must have to be kept (0-26).
%                    Default: 0 (disabled). Neighbours are counted within the
%                    voxel's own cluster, so touching another cluster does not
%                    count.
%   CONN           - Connectivity for cluster detection: 6 (face), 18 (face +
%                    edge, default) or 26 (face + edge + corner).
%
% Outputs:
%   NEWPMAP  - Cleaned binary map, same format as PMAP.
%
% Order of the two filters:
%   Size is checked first, so neighbour pruning can leave clusters below
%   CL_SIZE_THRES or split them in two. This is kept for compatibility with
%   earlier analyses. To guarantee every surviving cluster meets the size
%   threshold, run the filters separately:
%
%       tmp   = fmri_cleanclusters(pmap, 0, NN_THRES);
%       clean = fmri_cleanclusters(tmp,  CL_SIZE_THRES, 0);
%
% Examples:
%   clean = fmri_cleanclusters(thresh_map, 50, 0);
%   clean = fmri_cleanclusters(thresh_map, cs, 2);
%   clean = fmri_cleanclusters(thresh_map, 50, 0, 6);   % strict face-only
%   clean = fmri_cleanclusters(thresh_map, 50, 0, 26);  % liberal corner
%
% See also: fmri_csthreshold, fmri_csdist, fmri_regiontable, fmri_tfce

if nargin < 4 || isempty(CONN), CONN = 18; end
if ~ismember(CONN, [6 18 26])
    error('fmri_cleanclusters:badConn', 'CONN must be 6, 18, or 26.');
end

if nargin < 3 || isempty(NN_THRES), NN_THRES = 0; end
if ~isscalar(CL_SIZE_THRES) || CL_SIZE_THRES < 0
    error('fmri_cleanclusters:badSize', ...
          'CL_SIZE_THRES must be a non-negative scalar; got %s.', ...
          mat2str(CL_SIZE_THRES));
end
if ~isscalar(NN_THRES) || NN_THRES < 0 || NN_THRES > 26
    error('fmri_cleanclusters:badNN', ...
          'NN_THRES must be a scalar in the range 0-26; got %s.', ...
          mat2str(NN_THRES));
end

% Decide vector or volume by shape, not by ndims: a 228453 x T matrix is 2-D
% but is not a single map, and would be flattened silently.
isvectorinput = ~isequal([size(pmap,1) size(pmap,2) size(pmap,3)], [91 109 91]);
if isvectorinput
    if numel(pmap) ~= 228453
        error('fmri_cleanclusters:badInput', ...
              ['PMAP must be a 228453-element vectorized map or a 91x109x91 ' ...
               'volume; got %d elements.\n' ...
               'This function cleans one map at a time.'], numel(pmap));
    end
    pmap = fmri_vect2vol(pmap(:));
end

[label, num] = fmri_bwlabel(pmap, CONN);
newpmap = zeros(size(pmap));
if num == 0
    if isvectorinput, newpmap = fmri_vol2vect(newpmap); end
    return
end

% Cluster sizes in one pass rather than one full-volume scan per cluster.
lab_v = label(:);
sizes = accumarray(lab_v(lab_v > 0), 1, [num 1]);
big   = find(sizes >= CL_SIZE_THRES);

if NN_THRES == 0
    % No neighbour pruning: keep the surviving clusters whole.
    newpmap(ismember(label, big)) = 1;
else
    % Neighbours are counted one cluster at a time, so clusters touching at an
    % edge or corner do not credit each other, and only inside each cluster's
    % bounding box, which avoids a full-volume pass per cluster.
    kernel = ones(3,3,3);
    [ix, iy, iz] = ind2sub(size(label), find(lab_v > 0));
    lin = find(lab_v > 0);
    labs = lab_v(lin);
    for k = big(:)'
        sel = labs == k;
        x = ix(sel); y = iy(sel); z = iz(sel);
        x0 = max(min(x)-1, 1); x1 = min(max(x)+1, size(label,1));
        y0 = max(min(y)-1, 1); y1 = min(max(y)+1, size(label,2));
        z0 = max(min(z)-1, 1); z1 = min(max(z)+1, size(label,3));

        sub    = label(x0:x1, y0:y1, z0:z1) == k;
        clconv = convn(double(sub), kernel, 'same');   % neighbours + 1

        blk = newpmap(x0:x1, y0:y1, z0:z1);
        blk(sub & clconv > NN_THRES) = 1;
        newpmap(x0:x1, y0:y1, z0:z1) = blk;
    end
end

if isvectorinput
    newpmap = fmri_vol2vect(newpmap);
end