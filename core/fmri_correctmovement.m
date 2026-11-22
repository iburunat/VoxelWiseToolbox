function residual = fmri_correctmovement(data, movementfilepath)
% FMRI_CORRECTMOVEMENT  Removes motion artefacts from fMRI data via regression.
%
% Regresses motion parameters from the fMRI time series using ordinary least
% squares. The regressors are z-scored and fitted with an intercept. The
% returned residuals are therefore motion-adjusted and mean-centred.
%
% Usage:
%   residual = fmri_correctmovement(data, movementfilepath)
%
% Inputs:
%   DATA             - fMRI time series, in any accepted layout:
%                        228453 x T          canonical (voxels x time)
%                        91 x 109 x 91 x T   volume
%   MOVEMENTFILEPATH - Path to the motion parameter file, or a numeric T x P
%                      matrix of motion regressors. The file should contain a
%                      numeric matrix with one row per scan and one column per
%                      regressor (typically 6: three translations and three
%                      rotations).
%
% Outputs:
%   RESIDUAL - Motion-corrected data, in the same layout as DATA.
%
% Examples:
%   data = fmri_correctmovement(data, 'sub01_motion.txt');
%   data = fmri_correctmovement(data, 'rp_asub-01_task-music_bold.txt');
%   data = fmri_correctmovement(data, rp);        % regressors already loaded
%
% Notes:
%   Motion parameter files are typically produced by SPM (rp_*.txt) or FSL
%   (*.par). Both 6-column rigid-body sets and extended sets (such as the
%   24-parameter Friston expansion) are accepted; every column of the file is
%   used as a regressor.
%
%   In a preprocessing pipeline, motion regression is normally applied before
%   detrending and temporal smoothing.
%
% See also: fmri_detrend, fmri_tempsmooth, fmri_bandpassfilter, fmri_readnii

[data, fmt] = fmri_asvoxtime(data, 'fmri_correctmovement');
T = size(data, 2);

% ---- load motion regressors -------------------------------------------
if ischar(movementfilepath) || isstring(movementfilepath)
    if ~exist(movementfilepath, 'file')
        error('fmri_correctmovement:fileNotFound', ...
              'Motion parameter file not found: %s', movementfilepath);
    end
    X = load(movementfilepath);
elseif isnumeric(movementfilepath)
    X = movementfilepath;                      % regressors passed directly
else
    error('fmri_correctmovement:badInput', ...
          'MOVEMENTFILEPATH must be a file path or a numeric T x P matrix.');
end

if size(X, 1) ~= T
    error('fmri_correctmovement:lengthMismatch', ...
          ['The motion file has %d rows but the data have %d scans. ' ...
           'They must match.'], size(X, 1), T);
end

% The intercept below already accounts for a constant regressor, 
% so such columns are dropped.
sd   = std(X);
flat = (sd == 0);
if any(flat)
    warning('fmri_correctmovement:constantRegressor', ...
            ['Motion regressor column(s) %s are constant and carry no ' ...
             'information. Dropping them; the intercept covers them.'], ...
            mat2str(find(flat)));
    X  = X(:, ~flat);
    sd = sd(~flat);
end
X = (X - mean(X)) ./ sd;                         % T x P (zscore equiv)

% ---- OLS regression with intercept ------------------------------------
% Work in T x V here because that is the natural orientation for a design
% matrix. The canonical layout is restored on exit.
Y        = data.';                             % T x V
Xc       = [ones(T, 1), X];                    % T x (P+1), intercept first
B        = (Xc' * Xc) \ (Xc' * Y);             % (P+1) x V
residual = (Y - Xc * B).';                     % back to V x T

residual = fmri_restoreformat(residual, fmt);
end
