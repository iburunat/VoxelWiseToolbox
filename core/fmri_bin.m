function [bindata, bincmap] = fmri_bin(data, minval, maxval, nbins, cmap)
% FMRI_BIN  Bins continuous brain data into a set of discrete colour bands.
%
% Assigns each voxel to one of NBINS discrete bins spanning [MINVAL, MAXVAL].
% Returns a binary (228453 x NBINS) matrix where column k is 1 for voxels
% whose value falls within bin k, and a corresponding RGB colour lookup table
% suitable for multi-colour 3D rendering. Used internally by fmri_tfce and
% fmri_show3d for multi-level rendering and cluster-size integration.
% 
% Usage:
%   [bindata, bincmap] = fmri_bin(data, minval, maxval)
%   [bindata, bincmap] = fmri_bin(data, minval, maxval, nbins, cmap)
%
% Inputs:
%   DATA    - Statistical map, vectorized (228453 x 1).
%   MINVAL  - Lower bound: values below are excluded.
%   MAXVAL  - Upper bound: values above are clipped to the top bin.
%   NBINS   - Number of discrete bins. Default: 10.
%   CMAP    - (NBINS x 3) RGB colormap. Default: jet, scaled from midrange.
%
% Outputs:
%   BINDATA - Binary matrix (228453 x NBINS). Column k is 1 for voxels whose
%             value falls in bin k. The bins are disjoint, so a voxel appears
%             in exactly one column.
%   BINCMAP - RGB colour matrix (NBINS x 3), one row per bin.
%
% Examples:
%   [bd, bc] = fmri_bin(zmap, 2, 5);
%   [bd, bc] = fmri_bin(zmap, 2, 5, 20);
%   fmri_show3d(bd, [], [], [], [], bc)
%
% See also: fmri_show3d, fmri_tfce, fmri_showslices

if nargin<5  || isempty(cmap), cmap=interp1(1:64,jet(64),linspace(32,64,64)); end
if nargin<4  || isempty(nbins), nbins=10; end
if nargin<3  || isempty(maxval), maxval=max(data); end
if nargin<2  || isempty(minval), minval=min(data); end

% Size derived from the input data.
tmp=zeros(numel(data),nbins);
thres=linspace(minval,maxval,nbins+1);

for k=1:length(thres)
    tmp(:,k)=data>=thres(k);
end

bindata=-diff(tmp,[],2);
bindata(:,end)=bindata(:,end) | tmp(:,end);
bincmap=interp1(1:size(cmap,1),cmap,linspace(1,size(cmap,1),size(bindata,2)));