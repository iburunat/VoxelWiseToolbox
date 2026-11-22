function c = fmri_corrvoldata(d1, d2)
% FMRI_CORRVOLDATA  Voxelwise Pearson correlation between two fMRI datasets.
%
% Computes the temporal correlation between two fMRI time series at each
% voxel independently, producing a voxelwise r-map. Both datasets must
% have the same number of voxels and the same number of time points.
%
% Usage:
%   c = fmri_corrvoldata(d1, d2)
%
% Inputs:
%   D1, D2  - fMRI time series, both vectorized (228453 x T). Each row is
%             a voxel; each column a time point.
%
% Outputs:
%   C       - Voxelwise correlation map (228453 x 1). Values in [-1, 1].
%
% Examples:
%   c = fmri_corrvoldata(run1, run2);
%   fmri_showslices(c, 1, 2, [-1 1])
%
%   % Correlation between rest and task
%   c = fmri_corrvoldata(rest_data, task_data);
%
% See also: fmri_corregressor, fmri_corrmat, fmri_rv2, fmri_xcorr

if ~isequal(size(d1), size(d2))
    error('fmri_corrvoldata:sizeMismatch', ...
          'D1 and D2 must be the same size; got %s and %s.', ...
          mat2str(size(d1)), mat2str(size(d2)));
end

tmp1=bsxfun(@minus,d1,mean(d1,2)); % center data
tmp2=bsxfun(@times,tmp1,1./sqrt(sum(tmp1.^2,2))); % normalize to unit variance
tmp3=bsxfun(@minus,d2,mean(d2,2)); % center data
tmp4=bsxfun(@times,tmp3,1./sqrt(sum(tmp3.^2,2))); % normalize to unit variance
c = sum(tmp2 .* tmp4, 2);
% Clip both tails
c(c >  1 & isfinite(c)) =  1;
c(c < -1 & isfinite(c)) = -1;