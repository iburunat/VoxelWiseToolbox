function actmask = fmri_actmask(data, threshold, climits)
% FMRI_ACTMASK  Decides which voxels a viewer draws.
%
%   THRESHOLD > 0  : draw where abs(data) >= THRESHOLD, keeping both signs
%   THRESHOLD == 0 : draw every finite value; zero is ordinary, hide with NaN
%   THRESHOLD []   : legacy rule, draw where data >= CLIMITS(1)
%
% Callers clamp DATA to CLIMITS before masking. Therefore, CLIMITS(1) must be
% lower than a positive THRESHOLD; otherwise clamped subthreshold values may
% pass the mask and be displayed. A warning is issued because this setting
% may still be intentional.
%
% Shared by the viewers so that the rule, and the guard, cannot drift apart.
%
% See also: fmri_showslices, fmri_showselectslices, fmri_showplanes

if ~isempty(threshold) && threshold > 0 && climits(1) >= threshold
    warning('fmri_actmask:climitsAboveThreshold', ...
        ['CLIMITS(1) = %g is not below THRESHOLD = %g.\n' ...
         'Data is clamped into CLIMITS before masking, so every sub-threshold ' ...
         'voxel\nwill still be drawn. Set CLIMITS(1) strictly below THRESHOLD ' ...
         '(0 is usually right).'], climits(1), threshold);
end

if ~isempty(threshold)
    if threshold > 0
        actmask = abs(data) >= threshold;
    else
        actmask = isfinite(data);
    end
else
    actmask = data >= climits(1);
end