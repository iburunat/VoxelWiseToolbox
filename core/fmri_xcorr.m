function c = fmri_xcorr(regr, data, maxlag)
% FMRI_XCORR  Voxelwise lagged cross-correlation between regressor and fMRI data.
%
% Correlates a regressor with every brain voxel across a range of time lags,
% returning a (228453 x 2*maxlag+1) correlation matrix. Column k corresponds
% to a temporal lag of (-maxlag + k - 1) scans. Useful for detecting
% haemodynamic delays or testing the HRF shape voxelwise.
%
% Usage:
%   c = fmri_xcorr(regr, data, maxlag)
%
% Inputs:
%   REGR    - Regressor (T x 1) or (T x R) for R regressors.
%   DATA    - fMRI time series, vectorized (228453 x T).
%   MAXLAG  - Maximum lag in scans (integer). The function computes
%             correlations for lags in [-maxlag, +maxlag].
%
% Outputs:
%   C  - Cross-correlation matrix (228453 x (2*maxlag+1)).
%        Column (maxlag+1) is the zero-lag correlation (= fmri_corregressor).
%
% Examples:
%   c = fmri_xcorr(stim_ts, data, 5);
%   [peak_r, peak_lag] = max(c, [], 2);
%   peak_lag = peak_lag - (maxlag+1);     % convert to signed lag
%   fmri_showslices(peak_lag .* (peak_r > 0.3), 1, 2, [-5 5])
%
% See also: fmri_corregressor, fmri_doublegamma, fmri_corrvoldata

if size(regr, 1) ~= size(data, 2)
    error('fmri_xcorr:sizeMismatch', ...
          ['REGR has %d time points but DATA has %d columns.\n' ...
           'REGR must be (T x R) and DATA (voxels x T) with matching T.'], ...
          size(regr, 1), size(data, 2));
end
if maxlag < 1 || maxlag >= size(data, 2)
    error('fmri_xcorr:badMaxlag', ...
          'MAXLAG must be between 1 and T-1 = %d; got %d.', ...
          size(data, 2) - 1, maxlag);
end

if ~isfloat(data), data = double(data); end
if ~isfloat(regr), regr = double(regr); end

nlags = 2*maxlag + 1;
c     = zeros(size(data,1), nlags);

for k = 1:nlags
    lag = -maxlag + k - 1;
    if lag < 0
        regr0 = regr((1-lag):end,:);
        data0 = data(:,1:(end+lag));
    else
        regr0 = regr(1:(end-lag),:);
        data0 = data(:,(1+lag):end);
    end
    tmp1 = bsxfun(@minus, regr0, mean(regr0,1));
    tmp2 = bsxfun(@times, tmp1, 1./sqrt(sum(tmp1.^2,1)));
    tmp3 = bsxfun(@minus, data0, mean(data0,2));
    tmp4 = bsxfun(@times, tmp3, 1./sqrt(sum(tmp3.^2,2)));
    c(:,k) = tmp4 * tmp2;
end

% Clip both tails; leave NaN visible.
c(c >  1 & isfinite(c)) =  1;
c(c < -1 & isfinite(c)) = -1;