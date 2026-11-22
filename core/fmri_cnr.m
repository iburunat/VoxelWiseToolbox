function CNR = fmri_cnr(v)
% FMRI_CNR  Temporal contrast-to-noise ratio (tCNR) for fMRI data.
%
% Calculates the functional CNR per unit time (fCNR), defined as the ratio
% of the mean absolute scan-to-scan signal change (delta-S) to the temporal
% standard deviation of the signal per voxel:
%
%   fCNR = mean|delta-St| / sigma_t
%
%   Here delta-St is the time-dependent signal change, operationalised for a
%   continuous (naturalistic) paradigm as the mean absolute scan-to-scan change
%   of the voxel time series. Equivalently fCNR = fSNR * (delta-St / St), where
%   fSNR = St / sigma_t; the mean signal St cancels (no division by the mean
%   is applied). For a block design delta-St would instead be the modelled
%   condition contrast; this successive-difference form is the continuous-data
%   analogue, appropriate to the paradigms this toolbox targets.
%
% Usage:
%   CNR = fmri_cnr(v)
%
% Inputs:
%   V   - fMRI data, vectorized (228453 x T) or volume (91 x 109 x 91 x T)
%
% Outputs:
%   CNR - Voxelwise tCNR map, vectorized (228453 x 1). Voxels with zero
%         temporal variance (e.g. outside the brain mask) are set to 0.
%
% Examples:
%   CNR = fmri_cnr(data);
%   fmri_showslices(CNR, 1, 2, [0 5])
%
% References:
%   Welvaert, M. & Rosseel, Y. (2013). On the definition of signal-to-noise
%   ratio and contrast-to-noise ratio for fMRI data. PLoS ONE, 8(11).
%
% See also: fmri_snri, fmri_snrt

if ndims(v) > 2
    v = fmri_vol2vect(v);
end

% Checked AFTER vectorisation: for a 91x109x91xT volume size(v,2) is 109, the
% second spatial dimension, so this test would pass for any T, including 1.
if size(v, 2) < 2
    error('fmri_cnr:tooFewTimepoints', ...
        ['V must contain at least 2 time points (228453 x T, T >= 2).\n' ...
         'CNR is a ratio to the TEMPORAL standard deviation, which is undefined ' ...
         'for a single volume.']);
end

d       = diff(v, 1, 2);                    % scan-to-scan differences (voxel x T-1)

sigma_t = std(v, 0, 2, 'omitnan');          % temporal std per voxel   (voxel x 1)
CNR     = mean(abs(d), 2, 'omitnan') ./ sigma_t;  % mean |delta-S| / sigma_t
CNR(~isfinite(CNR)) = 0;                    % zero out NaN/Inf (e.g. constant voxels)

end