function reg = fmri_vox2reg(vox, atlas)
% FMRI_VOX2REG  Averages voxel data within atlas ROIs to produce ROI-level data.
%
% Computes the mean across all voxels within each atlas ROI, producing a
% compact ROI-level representation. Useful for dimensionality reduction
% before connectivity or group-level analyses. Inverse of fmri_reg2vox.
%
% Usage:
%   reg = fmri_vox2reg(vox, atlas)
%
% Inputs:
%   VOX    - Voxel-level data: (228453 x T) time series or (228453 x 1) map.
%   ATLAS  - Atlas number (see atlas list below). Default: 1 (AAL).
%
% Outputs:
%   REG  - ROI-level data (R x T) or (R x 1), where R is the number of
%          ROIs in the selected atlas.
%
% Examples:
%   roi_ts = fmri_vox2reg(data, 3);         % Harvard-Oxford Cortical time series
%   roi_fc = fmri_corrmat(roi_ts');                  % ROI x ROI FC matrix
%
% Atlas numbers:
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
% See also: fmri_reg2vox, fmri_regionmask, fmri_loadatlas

if nargin < 2 || isempty(atlas), atlas = 1; end
[ROI_nos, ROI_labels] = fmri_loadatlas(atlas);

% fmri_loadatlas always returns vectorized ROI numbers, whatever format the
% atlas .mat file happens to use, so no conversion is needed here.
roi = ROI_nos;

roi = roi(:);

if size(vox,1) ~= numel(roi)
    error('fmri_vox2reg:sizeMismatch', ...
          ['VOX has %d rows but the atlas covers %d voxels.\n' ...
           'VOX must be vectorized brain data (228453 x N).'], ...
          size(vox,1), numel(roi));
end

% One row per atlas LABEL, not per label that happens to contain voxels: 
% e.g., a region entirely outside the brain mask would shorten REG and
% break the row-to-label correspondence that callers rely on.
nreg = numel(ROI_labels);
reg  = zeros(nreg, size(vox,2));

% Compute ROI sums and voxel counts efficiently with ACCUMARRAY, avoiding a
% separate whole-brain search for each atlas region.
inside = roi > 0;                       % 0 marks unlabelled voxels
counts = accumarray(roi(inside), 1, [nreg 1]);

roi_in = roi(inside);
for col = 1:size(vox,2)
    v  = vox(inside, col);
    ok = ~isnan(v);                     % NaN voxels are excluded rather than
    sums = accumarray(roi_in(ok), v(ok), [nreg 1]);   % poisoning the whole
    n    = accumarray(roi_in(ok), 1,     [nreg 1]);   % region mean
    reg(:, col) = sums ./ n;            % 0/0 -> NaN for empty regions
end

% Regions containing no valid voxels are returned as NaN. Warn because these
% values may be difficult to notice in large ROI-level datasets.
empty_regions = find(counts == 0);
if ~isempty(empty_regions)
    warning('fmri_vox2reg:emptyRegions', ...
            ['%d of %d atlas regions contain no voxels in the brain mask ' ...
             'and are returned as NaN.\n' ...
             'First few: %s'], numel(empty_regions), nreg, ...
            mat2str(reshape(empty_regions(1:min(10,end)),1,[])));
end