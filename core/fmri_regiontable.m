function [clust, s, ROI, list, roi_idx, clus, T] = fmri_regiontable(data_thres, data, clsize, roisize, atlas)
% FMRI_REGIONTABLE  Cluster and ROI table for a thresholded statistical map.
%
% Identifies clusters in a thresholded brain map and lists the atlas regions
% within each cluster. For every region, it reports the number of voxels,
% peak statistic and peak MNI coordinates. Results are returned as structures,
% tab-separated text, voxel maps and a MATLAB table.
% 
% Usage:
%   [clust, s] = fmri_regiontable(data_thres, data)
%   [clust, s, ROI, list, roi_idx, clus, T] = ...
%       fmri_regiontable(data_thres, data, clsize, roisize, atlas)
%
% Inputs:
%   DATA_THRES - Binary brain map (228453 x 1), logical or double: nonzero =
%                suprathreshold voxel.
%   DATA       - Continuous statistical map (228453 x 1): used for peak values.
%   CLSIZE     - Minimum cluster size in voxels. Default: 0.
%   ROISIZE    - Minimum number of voxels an atlas region must contain to
%                appear in the results. Default: 0. May exceed CLSIZE.
%                Clusters containing no regions that meet this threshold are
%                not reported.
%   ATLAS      - Atlas number. Default: 1 (AAL). Run fmri_atlas() for the list
%                of atlases and their region counts, which is maintained in
%                fmri_loadatlas rather than repeated here.
%
% Outputs:
%   CLUST   - Struct array, one element per reported cluster, in the same
%             order that S and T number them: left hemisphere first, then
%             right, largest first within each. Fields: centroid (MNI mm),
%             n (voxels), and region, itself a struct array with name, n,
%             coord, z and BA for each atlas region in the cluster.
%             [clust.n] therefore gives the extents of Clusters 1..N.
%   S       - The same information as tab-separated text, for pasting into a
%             manuscript.
%   ROI     - Cell array: ROI{c} is a (228453 x K) binary matrix of the K
%             REPORTED atlas regions of cluster c, those meeting ROISIZE.
%   LIST    - Cell array: LIST{c}{k} names the region in ROI{c}(:,k).
%   ROI_IDX - The same regions as voxel INDICES rather than binary maps.
%   CLUS    - (228453 x nClusters) matrix. Column c holds the union of the
%             regions reported for cluster c, so with ROISIZE > 0 it can be
%             smaller than the cluster itself: nnz(clus(:,c)) <= clust(c).n,
%             which remains the whole cluster's voxel count.
%             Fast plotting: fmri_show3d(clus(:,[1 3]))
%   T       - MATLAB table of the rows printed in S, with columns Cluster,
%             Hemisphere, Region, Voxels, X, Y, Z, Peak, BA. Convenient for
%             sorting, filtering and writetable(T, 'results.csv').
%
% Notes:
%
%   SIGNED MAPS
%   Clusters are defined by DATA_THRES, and each peak is located using
%   abs(DATA), with its signed value reported. The output is grouped by 
%   hemisphere, but clusters are not separated by sign. A contiguous 
%   cluster containing both positive and negative values is therefore 
%   reported as a single cluster. To analyse the two directions separately, 
%   call the function with sign-specific masks:
%
%       fmri_regiontable(mask & stat > 0, stat, ...)
%       fmri_regiontable(mask & stat < 0, stat, ...)
%
%   HEMISPHERE ASSIGNMENT
%   Each cluster is assigned to a hemisphere from the x-coordinate of its
%   centroid. Clusters crossing the midline are not split; a centroid at
%   x = 0 is assigned to the right hemisphere.
% 
%   BRODMANN AREA COLUMN
%   For each atlas region within a cluster, BA is the most frequent non-zero
%   Brodmann label among its voxels. Voxels without a Brodmann label are
%   excluded, and BA = 0 means that none of the region's voxels has a label.
%
%   Unless ATLAS = 19, the region labels come from the selected atlas, while
%   BA comes from the toolbox Brodmann atlas. The BA column is therefore an
%   approximate additional label rather than the atlas label defining the
%   region.
%
%   With ATLAS = 19, the same Brodmann atlas defines both the table rows and
%   the BA column. The BA column therefore repeats the area defining each row;
%   unlabelled voxels are reported with BA = 0.
%
% Examples:
%   [c, s] = fmri_regiontable(thresh_map, z_map);
%   [c, s] = fmri_regiontable(thresh_map, z_map, 50, 10, 3);
%
%   % Brodmann parcellation, rather than an AAL table with a BA column
%   [~, ~, ~, ~, ~, ~, T] = fmri_regiontable(thresh_map, t_map, 20, 5, 19);
%
% Atlas numbers (fmri_loadatlas is the source of truth):
%    1  = AAL / MarsBar (Automated Anatomical Labeling, 116 ROIs, default)
%    2  = Harvard-Oxford Subcortical Structural Atlas (21 ROIs)
%    3  = Harvard-Oxford Cortical Structural Atlas (48 ROIs)
%    4  = Cerebellar Atlas (MNI152, FLIRT affine, 28 ROIs)
%    5  = Cerebellar Atlas (MNI152, FNIRT nonlinear, 28 ROIs)
%    6  = JHU ICBM-DTI-81 White-Matter Labels (49 ROIs)
%    7  = JHU White-Matter Tractography Atlas (20 ROIs)
%    8  = Juelich Histological Atlas (121 ROIs)
%    9  = MNI Structural Atlas (9 ROIs)
%   10  = Oxford-Imanova Striatal Structural Atlas (4 ROIs)
%   11  = Oxford-Imanova Striatal Connectivity Atlas, 3 sub-regions
%   12  = Oxford-Imanova Striatal Connectivity Atlas, 7 sub-regions
%   13  = Oxford Thalamic Connectivity Probability Atlas (7 ROIs)
%   14  = Craddock Parcellation 200 ROI
%   15  = Craddock Parcellation 400 ROI
%   16  = Craddock Parcellation 600 ROI
%   17  = Craddock Parcellation 800 ROI
%   18  = Craddock Parcellation 950 ROI
%   19  = Brodmann Areas (47 regions)
%
% See also: fmri_cleanclusters, fmri_regionnumber, fmri_csthreshold


nvox = numel(data_thres);

if sum(data_thres)==0, 
    clust=[]; s=[]; ROI{1}=zeros(nvox,1); list{1}=[]; roi_idx=[]; clus=zeros(nvox,1);
    T = table('Size',[0 9], ...
              'VariableTypes',{'double','string','string','double','double', ...
                               'double','double','double','double'}, ...
              'VariableNames',{'Cluster','Hemisphere','Region','Voxels', ...
                               'X','Y','Z','Peak','BA'});
    return
end

if nargin<5 || isempty(atlas), atlas=1; end  % AAL atlas by default
if nargin<4 || isempty(roisize), roisize=0; end  
if nargin<3, clsize=0; end

data_thres_vol=fmri_vect2vol(data_thres);

% Find clusters

[clustvol,~]=fmri_bwlabel(data_thres_vol,18);
clustvect=fmri_vol2vect(clustvol);

% Find regions within each cluster; number of voxels within each region;
% coordinates of the voxel with the highest absolute z value within each region

for c=1:max(clustvect)
    subs=find(clustvect==c);
    inds=fmri_ind2sub(subs); % correct PT
    r=fmri_regionnumber(inds,atlas);
    % fmri_regionnumber unwraps its cell output when given a single coordinate,
    % so a one-voxel cluster would arrive here as a char array and unique()
    % would return its distinct CHARACTERS instead of one region name.
    if ~iscell(r), r = {r}; end
    rr=unique(r);
    
    clust(c).centroid = fmri_sub2mni(mean(inds,1));
    clust(c).n=size(inds,1);
    
    clear coord n z subtmp   % per-cluster; stale entries otherwise persist
    for k=1:length(rr)
        ind=find(strcmp(rr(k),r))';
        n(k)=length(ind);
        [tmp subtmp(k)]=max(abs(data(subs(ind))));
        z(k)=data(subs(ind(subtmp(k))));
        coord(k,:)=inds(ind(subtmp(k)),:);
        
        % --------------------------------
        roi{c}{k}=subs(ind);
        % --------------------------------
    end
    [tmp sortind]=sort(coord(:,1));
    
    % Reorder the region voxel indices to match the sorted region order.
    for ss=1:length(sortind)
        roisort{c}{ss}=roi{c}{sortind(ss)};
    end
    
    % Convert from indeces to MNI coordinates
    mni=fmri_sub2mni(coord);
    
    for k=1:length(sortind)
        clust(c).region(k).name  = rr{sortind(k)};
        clust(c).region(k).n     = n(sortind(k));
        clust(c).region(k).coord = mni(sortind(k),:);
        clust(c).region(k).z     = z(sortind(k));
        % Assign the modal non-zero Brodmann label across the region's voxels instead
        % of using the label at its statistical peak. E.g., a region with most
        % voxels in BA22 should not be labelled BA42 merely because its peak
        % falls in a small BA42 portion. Peak locations may shift between analyses,
        % whereas the modal label is generally less sensitive to such shifts.
        % Voxels without a Brodmann label are excluded.        
        ba_vox = fmri_banumber(fmri_ind2sub(roisort{c}{k}));
        ba_vox = ba_vox(ba_vox > 0);
        if isempty(ba_vox)
            clust(c).region(k).BA = 0;
        else
            clust(c).region(k).BA = mode(double(ba_vox));
        end
    end    
end

% ---- one canonical cluster order, established once ------------------------
% Every output below is built from CLUST in this order, so none of them can
% disagree with another.

% Size-descending. sort(-n) rather than sort(n,'descend') so that equal-sized
% clusters keep the order fmri_bwlabel gave them.
[~, order] = sort(-[clust.n]);
clust      = clust(order);
roisort    = roisort(order);

% Left hemisphere first, size order preserved within each. A centroid at
% exactly x = 0 goes to the right.
x       = arrayfun(@(c) c.centroid(1), clust);
order   = [find(x < 0) find(x >= 0)];
clust   = clust(order);
roisort = roisort(order);

% Both thresholds applied once, here, rather than inside the output loops.
keep = false(1, numel(clust));
for c = 1:numel(clust)
    if clust(c).n < clsize, continue; end

    ns      = [clust(c).region.n];
    unlabel = strcmp({clust(c).region.name}, 'Unlabelled');

    % Regions largest first, 'Unlabelled' last: it collects voxels the atlas
    % does not label rather than being a region, and is often the largest
    % entry, so sorting purely by size puts a non-result at the top.
    [~, ro] = sort(-ns);
    ro      = [ro(~unlabel(ro)) ro(unlabel(ro))];

    % Keep only regions meeting ROISIZE. A cluster left with none is not
    % reported, which is what the ROISIZE help promises.
    ro = ro(ns(ro) >= roisize);
    if isempty(ro), continue; end

    clust(c).region = clust(c).region(ro);
    roisort{c}      = roisort{c}(ro);
    keep(c)         = true;
end
clust   = clust(keep);
roisort = roisort(keep);

% Nothing survived: return the same empty shape as the early return above,
% rather than a 0x0 struct.
if isempty(clust), clust = []; end

% CLUST and ROISORT are now left block then right block, largest first within
% each, already filtered. Every output below is built from that one array in
% that one order, so none of them can disagree.
x  = arrayfun(@(c) c.centroid(1), clust);
nL = nnz(x < 0);

roi = roisort;  roi_idx = roisort;
list = cell(1, numel(clust));
s = [];
T = table('Size',[0 9], ...
          'VariableTypes',{'double','string','string','double','double', ...
                           'double','double','double','double'}, ...
          'VariableNames',{'Cluster','Hemisphere','Region','Voxels', ...
                           'X','Y','Z','Peak','BA'});

for k = 1:numel(clust)
    if     k == 1 && nL > 0, hdr = 'Left';
    elseif k == nL + 1,      hdr = 'Right';
    else,                    hdr = '';
    end
    if ~isempty(hdr)
        s = [s sprintf('%s hemisphere -------------------------\n\n', hdr)];
        s = [s sprintf('region\tvoxels\tx\ty\tz\tpeak\tBA\n')];
    end
    if k <= nL, hemi = "Left"; else, hemi = "Right"; end

    s = [s sprintf('Cluster #%d: N = %d\n', k, clust(k).n)];
    list{k} = {clust(k).region.name};
    for m = 1:numel(clust(k).region)
        R = clust(k).region(m);
        s = [s sprintf('%s\t%d\t%d\t%d\t%d\t%f\t%d\n', R.name, R.n, ...
                       R.coord(1), R.coord(2), R.coord(3), R.z, R.BA)];
        T = [T; {k, hemi, string(R.name), R.n, ...
                 R.coord(1), R.coord(2), R.coord(3), R.z, R.BA}]; %#ok<AGROW>
    end
    s = [s sprintf('\n')];
end

if isempty(roi)
    ROI{1} = zeros(nvox,1);  list{1} = [];  roi_idx = [];  clus = zeros(nvox,1);
else
    clus = zeros(nvox, numel(roi));
    for c = 1:numel(roi)
        ROI{c} = zeros(nvox, numel(roi{c}));
        for k = 1:numel(roi{c})
            ROI{c}(roi{c}{k}, k) = 1;
            clus(roi{c}{k}, c)   = 1;
        end
    end
end
end