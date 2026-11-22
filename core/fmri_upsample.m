function fmri2 = fmri_upsample(fmri, factor_in, method)
% FMRI_UPSAMPLE  Restores spatially downsampled fMRI data to full resolution.
%
% Interpolates a downsampled brain dataset (from fmri_downsample) back to
% the full 228453-voxel vectorized space using the specified interpolation
% method. The downsampling factor is inferred automatically from the number
% of rows.
%
% Usage:
%   fmri2 = fmri_upsample(fmri)
%   fmri2 = fmri_upsample(fmri, factor)
%   fmri2 = fmri_upsample(fmri, factor, method)
%
% Inputs:
%   FMRI    - Downsampled vectorized data (M x T), where M is the number
%             of voxels after downsampling (M < 228453).
%   METHOD  - Interpolation method string: 'linear', 'nearest', 'cubic',
%             'spline'. Default: 'linear'.
%
% Outputs:
%   FMRI2   - Upsampled data (228453 x T) at full brain resolution.
%
% Examples:
%   small = fmri_downsample(data, 2);
%   full  = fmri_upsample(small);
%   full  = fmri_upsample(small, 'spline');
%
% Notes:
%   Supported input sizes (factor: voxel count): 2: 28542, 3: 8468, 4: 3574,
%   5: 1820, 6: 1065, 7: 674, 8: 449, 9: 312, 10: 223.
%
% See also: fmri_downsample

% Infer the downsampling factor from the number of input rows. The expected
% row count is calculated from the brain mask for each supported factor,
% avoiding a hard-coded list of voxel counts.
if nargin >= 2 && ~isempty(factor_in)
    factor = factor_in;
else
    factor = [];
    for f = 2:10
        m = zeros(91,109,91);
        m(1:f:end, 1:f:end, 1:f:end) = 1;
        if nnz(fmri_vol2vect(m)) == size(fmri,1)
            factor = f;
            break
        end
    end
    if isempty(factor)
        error('fmri_upsample:unknownFactor', ...
              ['Cannot work out the downsampling factor from %d rows.\n' ...
               'Pass it explicitly: fmri_upsample(data, factor, method).'], ...
              size(fmri,1));
    end
end

if nargin < 3 || isempty(method), method = 'linear'; end

mask=zeros(91,109,91);
mask(1:factor:end,1:factor:end,1:factor:end)=1;
maskv=fmri_vol2vect(mask);
[x,y,z]=ndgrid(1:91,1:109,1:91);
xv=fmri_vol2vect(x);
yv=fmri_vol2vect(y);
zv=fmri_vol2vect(z);
xvmask=xv(find(maskv));
yvmask=yv(find(maskv));
zvmask=zv(find(maskv));

fmri2=zeros(length(xv),size(fmri,2));
for k=1:size(fmri,2)
    tmp=griddata(xvmask,yvmask,zvmask,fmri(:,k),x,y,z,method);
    fmri2(:,k)=fmri_vol2vect(tmp);
end