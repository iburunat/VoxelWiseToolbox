function [L, num] = fmri_bwlabel3d(BW, CONN)
% FMRI_BWLABEL3D  Labels connected clusters in a 3D binary volume.
%
% Pure MATLAB 3D connected-component labelling. This is a drop-in replacement
% for SPM's spm_bwlabel (used previously) and removes the toolbox's earlier SPM
% dependency. Unlike spm_bwlabel, it accepts logical as well as numeric input 
% and requires no compiled MEX file.
%
% The algorithm identifies neighbouring foreground voxels and groups connected
% voxels by iteratively propagating cluster labels. Array-based operations
% allow the full volume to be processed efficiently.
%
% Usage:
%   [L, num] = fmri_bwlabel3d(BW)
%   [L, num] = fmri_bwlabel3d(BW, CONN)
%
% Inputs:
%   BW    - Binary volume (91 x 109 x 91, or any 3D size). Non-zero voxels are
%           treated as foreground. Logical or numeric input accepted.
%   CONN  - Connectivity criterion:
%             6  = face connectivity (most conservative)
%            18  = face + edge connectivity (default)
%            26  = face + edge + corner connectivity (most liberal)
%           Default: 18.
%
% Outputs:
%   L     - Integer-labelled volume (double), same size as BW. Each connected
%           cluster receives a unique label 1..NUM; background is 0. Labels are
%           assigned in ascending order of each cluster's first voxel in
%           column-major scan order, matching the convention of spm_bwlabel.
%   NUM   - Number of clusters found.
%
% Examples:
%   [L, n] = fmri_bwlabel3d(zvol > 3);        % default 18-connectivity
%   [L, n] = fmri_bwlabel3d(zvol > 3, 6);     % strict face-only
%   sizes  = accumarray(L(L > 0), 1);         % cluster sizes, label order
%
% See also: fmri_findclusters, fmri_cleanclusters, fmri_regiontable, fmri_tfce

% ---- input validation ------------------------------------------------
if nargin < 2 || isempty(CONN), CONN = 18; end
if ~ismember(CONN, [6 18 26])
    error('fmri_bwlabel3d:badConn', 'CONN must be 6, 18 or 26.');
end
if ndims(BW) > 3
    error('fmri_bwlabel3d:badInput', ...
          'BW must be a 3D volume (got %d dimensions).', ndims(BW));
end

BW = (BW ~= 0);
sz = size(BW);
if numel(sz) < 3, sz(3) = 1; end   % tolerate a single 2D slice

% ---- number the foreground voxels 1..n -------------------------------
fg  = find(BW);
n   = numel(fg);
L   = zeros(sz);
num = 0;
if n == 0, return; end

idxvol     = zeros(sz);
idxvol(fg) = 1:n;            % each foreground voxel carries its node number

% ---- neighbour offsets: forward half only ----------------------------
% Because the adjacency graph is undirected, each neighbour pair needs to be
% stored only once. Keep one of each pair of opposite offsets to avoid
% duplicate edges.
[dx, dy, dz] = ndgrid(-1:1, -1:1, -1:1);
off  = [dx(:) dy(:) dz(:)];
manh = sum(abs(off), 2);
switch CONN
    case 6,  off = off(manh == 1, :);
    case 18, off = off(manh >= 1 & manh <= 2, :);
    case 26, off = off(manh >= 1, :);
end
fwd = (off(:,1) > 0) | ...
      (off(:,1) == 0 & off(:,2) > 0) | ...
      (off(:,1) == 0 & off(:,2) == 0 & off(:,3) > 0);
off = off(fwd, :);

% ---- build the edge list by shifting a zero-padded index volume ------
P = zeros(sz + 2);
P(2:sz(1)+1, 2:sz(2)+1, 2:sz(3)+1) = idxvol;

nOff = size(off, 1);
Ea   = cell(nOff, 1);
Eb   = cell(nOff, 1);
for k = 1:nOff
    B = P(2+off(k,1) : 1+off(k,1)+sz(1), ...
          2+off(k,2) : 1+off(k,2)+sz(2), ...
          2+off(k,3) : 1+off(k,3)+sz(3));   % neighbour's node number
    both  = (idxvol > 0) & (B > 0);          % both voxels are foreground
    Ea{k} = idxvol(both);
    Eb{k} = B(both);
end
ea = vertcat(Ea{:});
eb = vertcat(Eb{:});

% ---- connected components by iterative label propagation -------------
% Each voxel stores the smallest label currently known for its component.
% Repeatedly propagate the smaller label across neighbouring voxels and
% compress the label paths until no values change.
lab  = (1:n)';
BIG  = n + 1;    
                                 
if ~isempty(ea)
    while true
        prev = lab;

        % hook: propagate the smaller label across every edge
        m   = min(lab(ea), lab(eb));
        lab = min(lab, accumarray(ea, m, [n 1], @min, BIG));
        lab = min(lab, accumarray(eb, m, [n 1], @min, BIG));

        % compress: pointer-jump until each node points at its root
        while true
            nxt = lab(lab);
            if isequal(nxt, lab), break; end
            lab = nxt;
        end

        if isequal(lab, prev), break; end
    end
end

% ---- relabel roots to 1..num in scan order ---------------------------
% Sort the component roots and relabel them consecutively in the order of
% their first voxel, matching column-major scan order.
[uroots, ~, newlab] = unique(lab);   %#ok<ASGLU>
num   = numel(uroots);
L(fg) = newlab;
end