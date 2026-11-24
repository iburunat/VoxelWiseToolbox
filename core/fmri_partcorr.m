function rho = fmri_partcorr(Y, x, Z)
% FMRI_PARTCORR  Computes voxelwise partial correlations controlling for confounds.
%
% At each voxel, correlates the brain data Y with the regressor x after
% removing the effects of one or more confound variables Z. Observations may
% be participants in a second-level analysis or time points in a first-level
% analysis.
% 
% The partial correlation is obtained by:
%   1. Regressing Z out of both x and Y (separately)
%   2. Correlating the residuals
%
% Usage:
%   rho = fmri_partcorr(Y, x, Z)
%
% Inputs:
%   Y   - Brain data: one vectorised map per observation, in either layout.
%         228453 x N is canonical and matches every other function;
%         N x 228453 is also accepted. N is participants for a second-level
%         analysis, or time points for a first-level one.
%   X   - Regressor of interest, (observations x 1). At the second level a
%         participant-level variable such as age, a behavioural score or group
%         membership; at the first level, a time-varying regressor.
%   Z   - Confound regressors, (observations x C) for C confounds.
%         E.g. [age, sex, total-intracranial-volume].
%
% Outputs:
%   RHO - Partial correlation map, vectorized (228453 x 1). Values are
%         Pearson r after controlling for Z.
%
% Examples:
%   % Correlate musical ability with brain activity, controlling for age
%   rho = fmri_partcorr(subj_maps, musical_score, age_vector);
%   fmri_showslices(rho, 1, 2, [0.2 0.7])
%
%   % Multiple confounds
%   rho = fmri_partcorr(subj_maps, IQ, [age, sex, education]);
%
% Notes:
%   All inputs are z-scored internally. Y, x and Z must contain the same
%   number of observations. In Y, observations correspond to the dimension
%   other than the 228453-voxel dimension.
%
%   To obtain p-values, pass RHO and the adjusted sample size to fmri_r2p.
%   Subtract one for each confound in Z:
%
%       p = fmri_r2p(rho, N - size(Z,2));                  % independent observations
%       p = fmri_r2p(rho, fmri_effdf(x,x) - size(Z,2));    % autocorrelated time points
%
%   Use the first form for independent observations, such as participants in
%   a group analysis, and the second for autocorrelated time-series data.
%   Do not subtract an additional 2, because fmri_r2p already applies the
%   Fisher correction using sqrt(df-3).
%
% See also: fmri_corregressor, fmri_r2p, fmri_effdf

% ---- ORIENTATION ---------------------------------------------------------
% Either layout is accepted. One dimension must be 228453, so the
% orientation is determined. The canonical form is the toolbox's own, 
% 228453 x observations, as in every other function.

NVOX = 228453;
if ~ismatrix(Y)
    error('fmri_partcorr:badY', 'Y must be a 2-D matrix, got %s.', ...
          mat2str(size(Y)));
end
if size(Y, 1) == NVOX
    Y = Y.';                        % canonical 228453 x N -> N x 228453
elseif size(Y, 2) ~= NVOX
    error('fmri_partcorr:badY', ...
        ['Y must have one dimension of length %d, one vectorised map per\n' ...
         'observation. Got %s.'], NVOX, mat2str(size(Y)));
end

if isvector(Z), Z = Z(:); end        % a single confound passed as a row

if size(Y, 1) ~= numel(x) || size(Z, 1) ~= numel(x)
    error('fmri_partcorr:sizeMismatch', ...
        ['Y, x and Z must agree on the number of observations. x has %d, ' ...
         'Y has %d,\nZ has %d.'], numel(x), size(Y, 1), size(Z, 1));
end

if size(Y, 1) < size(Z, 2) + 3
    error('fmri_partcorr:tooFewObservations', ...
        ['Partial correlation against %d confounds needs at least %d ' ...
         'observations; got %d.\nBelow that the confounds span the data, ' ...
         'every residual is zero, and RHO is all NaN.'], ...
        size(Z, 2), size(Z, 2) + 3, size(Y, 1));
end

if any(std(Z) == 0)
    error('fmri_partcorr:constantConfound', ...
        ['Z has a constant column (%s). Z is z-scored internally, so a ' ...
         'constant column\nbecomes NaN and RHO comes back all NaN. Do not ' ...
         'include an intercept: x, Y and Z\nare centred internally, so one ' ...
         'is unnecessary.'], mat2str(find(std(Z) == 0)));
end
if std(x) == 0
    error('fmri_partcorr:constantRegressor', ...
          'x is constant, so it cannot be correlated with anything.');
end

% Column-wise z-score without the Statistics Toolbox.
x = x(:);
x = (x - mean(x)) ./ std(x);
Y = (Y - mean(Y)) ./ std(Y);
Z = (Z - mean(Z)) ./ std(Z);

% Residualise x and Y with respect to Z (multiple regression)
ex  = x - Z * (Z \ x);     % residual of x after removing Z
eY  = Y - Z * (Z \ Y);     % residual of Y after removing Z (voxelwise)

% Partial correlation = correlation of residuals
% corr(ex, eY) with ex a T x 1 vector and eY a T x nvox matrix. Computed
% directly from z-scored columns, so no Statistics Toolbox is needed.
exz = (ex - mean(ex)) ./ std(ex);
eYz = (eY - mean(eY)) ./ std(eY);
rho = ((exz' * eYz) / (numel(exz) - 1))';   % 228453 x 1

% Voxels with no residual variance (flat, or fully explained by Z) give NaN.
% Leave them NaN rather than setting them to 0, so they are distinguishable
% from a genuine zero partial correlation. Callers can mask with isnan.