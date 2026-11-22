function [clusters, n_clusters, sizes] = fmri_findclusters(data, min_size)
% FMRI_FINDCLUSTERS  Finds and labels connected clusters in a binary brain map.
%
% Identifies all connected clusters of suprathreshold voxels in a binary
% brain map, returns a labelled map and a summary of cluster sizes. Clusters
% are defined using 18-connectivity (face and edge connected voxels).
%
% Usage:
%   [clusters, n_clusters, sizes] = fmri_findclusters(data)
%   [clusters, n_clusters, sizes] = fmri_findclusters(data, min_size)
%
% Inputs:
%   DATA      - Binary brain map, vectorized (228453 x 1) or
%               volume (91 x 109 x 91). Non-zero voxels define clusters.
%   MIN_SIZE  - Minimum cluster size in voxels. Clusters smaller than this
%               are removed from the output. Default: 1 (keep all).
%
% Outputs:
%   CLUSTERS   - Integer-labelled map (same format as DATA). Each connected
%                cluster has a unique integer label 1..n_clusters, sorted by
%                descending cluster size. Zero = background.
%   N_CLUSTERS - Number of clusters found (after applying MIN_SIZE).
%   SIZES      - Vector of cluster sizes in voxels (descending order),
%                one entry per cluster.
%
% Examples:
%   [cl, n, sz] = fmri_findclusters(thresh_map);
%   fprintf('%d clusters found; largest = %d voxels\n', n, sz(1))
%
%   % Only keep clusters > 50 voxels
%   [cl, n, sz] = fmri_findclusters(thresh_map, 50);
%   fmri_showslices_int(cl, 1, 3)
%
%   % Get binary map of largest cluster only
%   biggest = double(cl == 1);
%
% See also: fmri_cleanclusters, fmri_regiontable, fmri_csthreshold

if nargin < 2, min_size = 1; end

isvec = (ndims(data) < 3 || numel(data) == 228453);
if isvec
    vol = fmri_vect2vol(data(:));
else
    vol = data;
end

[label, num] = fmri_bwlabel(vol > 0, 18);

% Count cluster sizes in one pass instead of a full-volume scan per cluster.
% MAX(NUM,1) keeps the size argument a positive integer -> an empty map cannot
% error; the trim then gives back the 0 x 1 empty the code below expects.
lab_v     = label(:);
sizes_all = accumarray(lab_v(lab_v > 0), 1, [max(num, 1) 1]);
sizes_all = sizes_all(1:num);

% Filter by min_size and sort descending
keep      = find(sizes_all >= min_size);
[~, ord]  = sort(sizes_all(keep), 'descend');
keep      = keep(ord);
n_clusters = length(keep);
sizes      = sizes_all(keep);

% Relabel: cluster with largest size gets label 1, etc.
label_vol = zeros(size(vol));
for k = 1:n_clusters
    label_vol(label == keep(k)) = k;
end

if isvec
    clusters = fmri_vol2vect(label_vol);
else
    clusters = label_vol;
end