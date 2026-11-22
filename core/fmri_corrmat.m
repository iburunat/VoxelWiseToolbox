function c = fmri_corrmat(d1, d2)
% FMRI_CORRMAT  Column-wise pattern similarity matrix between two fMRI datasets.
%
% Computes the Pearson correlation between every pair of columns across two
% multivariate datasets, yielding an output matrix of size Ncol1 × Ncol2.
% Columns can represent time points, trials, conditions, or group-level patterns.
% If a single dataset is provided, the result is the autocorrelation matrix
% of its columns (e.g., T × T for time points).
%
% Usage:
%   c = fmri_corrmat(d1)       % autocorrelation of columns (Ncol × Ncol)
%   c = fmri_corrmat(d1, d2)   % cross-correlation between two datasets (Ncol1 × Ncol2)
%
% Inputs:
%   D1  - Multivariate data (e.g., voxels × columns); correlations are across rows
%   D2  - Optional second dataset (same number of rows). Default: D2 = D1
%
% Outputs:
%   C   - Similarity matrix of Pearson correlations between columns of D1 and D2
%
% Examples:
%   % Temporal similarity between time points
%   c = fmri_corrmat(data);           % T × T matrix
%   imagesc(c, [-1 1]); colorbar
%
%   % Cross-condition / trial / group-level similarity
%   c = fmri_corrmat(cond_data1, cond_data2);  % C1 × C2 matrix
%   imagesc(c, [-1 1]); colorbar
%
% See also: fmri_corregressor, fmri_corrvoldata, fmri_rv2, fmri_rsa

if nargin == 1
    d2 = d1;
end
if size(d1, 1) ~= size(d2, 1)
    error('fmri_corrmat:sizeMismatch', ...
          'D1 and D2 must have the same number of rows; got %d and %d.', ...
          size(d1, 1), size(d2, 1));
end

% Centre each time point (subtract mean across voxels)
tmp1 = bsxfun(@minus, d1, mean(d1, 1));
tmp2 = bsxfun(@times, tmp1, 1./sqrt(sum(tmp1.^2, 1)));  % unit norm per column
tmp3 = bsxfun(@minus, d2, mean(d2, 1));
tmp4 = bsxfun(@times, tmp3, 1./sqrt(sum(tmp3.^2, 1)));

c = tmp2' * tmp4;  % (T1 x T2) correlation matrix

% Clip both tails against floating-point overshoot; leave NaN (from constant
% columns) untouched so it stays visible.
c(c >  1 & isfinite(c)) =  1;
c(c < -1 & isfinite(c)) = -1;