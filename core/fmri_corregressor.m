function c = fmri_corregressor(regr, data, method)
% FMRI_CORREGRESSOR  Voxelwise correlation of regressor(s) with fMRI data.
%
% Correlates one or more regressors with every voxel in the brain, returning
% a brain map of Pearson r values (or Spearman rho if requested). This is
% the primary function for univariate GLM-style analysis (e.g. correlating
% a stimulus time course, a behavioural score, or a seed-region time series
% with the whole brain).
%
% Usage:
%   c = fmri_corregressor(regr, data)
%   c = fmri_corregressor(regr, data, method)
%
% Inputs:
%   REGR    - Regressor matrix (T x R): T time points, R regressors.
%             Will be normalised internally. For a single regressor, a
%             (T x 1) vector is accepted.
%   DATA    - fMRI time series, vectorized (228453 x T). Each row is a
%             voxel, each column a time point.
%   METHOD  - Correlation method: 'pearson' (default) or 'spearman'.
%             Spearman is rank-based and more robust to outliers but slower.
%
% Outputs:
%   C     - Correlation map (228453 x R). Each column is the r-map for one
%           regressor. Values are clipped to [-1, 1].
%
% Examples:
%   r = fmri_corregressor(stim_ts, data);
%   fmri_showslices(r, 1, 2, [0.2 0.6])
%
%   % Spearman (rank-based, outlier-robust)
%   r = fmri_corregressor(score, group_data, 'spearman');
%
%   % Multiple regressors at once
%   r = fmri_corregressor([regr1, regr2], data);
%
% See also: fmri_corrvoldata, fmri_xcorr, fmri_r2p, fmri_partcorr

if nargin < 3 || isempty(method), method = 'pearson'; end

if isvector(regr), regr = regr(:); end   % accept a row vector for one regressor

if size(regr, 1) ~= size(data, 2)
    error('fmri_corregressor:sizeMismatch', ...
          ['REGR has %d time points but DATA has %d columns.\n' ...
           'REGR must be (T x R) and DATA (voxels x T) with matching T.'], ...
          size(regr, 1), size(data, 2));
end
if ~ismember(lower(method), {'pearson', 'spearman'})
    error('fmri_corregressor:badMethod', ...
          'METHOD must be ''pearson'' or ''spearman''; got ''%s''.', method);
end

% Constant series have zero variance, so their correlation is undefined and the
% normalisation below would divide by zero. Warn about it.
if any(var(regr, 0, 1) == 0)
    warning('fmri_corregressor:constantRegressor', ...
            'One or more regressors are constant; their correlation map will be NaN.');
end

% Convert before any arithmetic. bsxfun rejects mixed integer/double input,
% and where it does not - a single regressor, whose column mean is a scalar
% double - integer arithmetic rounds the centred and normalised values to
% whole numbers, and the correlations come back silently wrong.
if ~isfloat(data), data = double(data); end
if ~isfloat(regr), regr = double(regr); end
    
if strcmpi(method, 'spearman')
    % Convert to ranks along time dimension
    regr = tiedrank_local(regr);
    data = tiedrank_local(data')';  % rank along rows (time axis)
end

% Pearson r as a matrix product of z-normalised regressors and voxels. Each
% regressor column and each voxel row is centred and scaled to unit norm, so
% their inner product is the correlation.
tmp1 = bsxfun(@minus, regr, mean(regr, 1));               % centre (time)
tmp2 = bsxfun(@times, tmp1, 1 ./ sqrt(sum(tmp1.^2, 1)));  % unit-norm columns
tmp3 = bsxfun(@minus, data, mean(data, 2));               % centre (time)
tmp4 = bsxfun(@times, tmp3, 1 ./ sqrt(sum(tmp3.^2, 2)));  % unit-norm rows
c = tmp4 * tmp2;                                           % voxels x regressors

% Voxels with no variation over time (e.g. dropout) have undefined
% correlations, so their values remain NaN. Only clip finite values 
% that exceed the range through floating-point error.
c(c >  1 & isfinite(c)) =  1;
c(c < -1 & isfinite(c)) = -1;