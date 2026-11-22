function rv2 = fmri_rv2(vol1, vol2)
% FMRI_RV2  Modified RV coefficient between two multivariate datasets.
%
% Computes the modified RV coefficient (RV2; Smilde et al., 2009) between
% two voxel-by-time fMRI datasets. The coefficient quantifies similarity
% between the time-by-time configuration matrices of the two datasets after
% removing diagonal elements, which reduces the positive bias of the
% classical RV coefficient in high-dimensional settings.
%
% Each input is treated as a matrix of size [V x T], where rows are voxels
% and columns are time points. For each dataset, voxel time series are
% mean-centered across time, and a time-by-time configuration matrix is
% computed as X' * X. The modified RV coefficient is then calculated from
% the off-diagonal elements only.
%
% Usage:
%   rv2 = fmri_rv2(vol1, vol2)
%
% Inputs:
%   vol1, vol2  - Voxel-by-time matrices [V x T]. Both must have the same
%                 number of time points.
%
% Outputs:
%   rv2         - Modified RV coefficient (scalar, range [-1 1]).
%
% Examples:
%   rv2 = fmri_rv2(data_subj1, data_subj2);
%
% References:
%   Smilde, A. K., Kiers, H. A. L., Bijlsma, S., Rubingh, C. M., &
%   van Erk, M. J. (2009). Matrix correlations for high-dimensional data:
%   the modified RV-coefficient. Bioinformatics, 25(3), 401-405.
%
% See also: fmri_corrmat, fmri_corrvoldata, fmri_rsa

    if ndims(vol1) ~= 2 || ndims(vol2) ~= 2
        error('fmri_rv2:notMatrix', 'Inputs must be 2D matrices (voxels x time).');
    end

    if size(vol1,2) ~= size(vol2,2)
        error('fmri_rv2:sizeMismatch', 'Inputs must have the same number of time points.');
    end

    if any(~isfinite(vol1(:))) || any(~isfinite(vol2(:)))
        error('fmri_rv2:nonFinite', 'Inputs must contain only finite values.');
    end

    % Mean-center each voxel time series across time
    vol1 = vol1 - mean(vol1, 2);
    vol2 = vol2 - mean(vol2, 2);

    % Time-by-time configuration matrices
    z1 = vol1' * vol1;
    z2 = vol2' * vol2;

    % Remove diagonal elements
    z1(1:size(z1,1)+1:end) = 0;
    z2(1:size(z2,1)+1:end) = 0;

    % Compute modified RV coefficient
    denom = sqrt(sum(z1(:).^2) * sum(z2(:).^2));
    if denom == 0
        rv2 = NaN;
        return
    end

    rv2 = sum(z1(:) .* z2(:)) / denom;
end