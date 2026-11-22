function data = fmri_restoreformat(data, fmt)
% FMRI_RESTOREFORMAT  Returns data to the layout the caller supplied.
%
% Internal helper paired with fmri_asvoxtime. Toolbox functions first convert
% input data to the canonical 228453 x T layout for processing, then use this
% function to restore the original layout before returning the result.
%
% Usage:
%   data = fmri_restoreformat(data, fmt)
%
% Inputs:
%   DATA - Result in canonical 228453 x T layout.
%   FMT  - Format struct returned by fmri_asvoxtime.
%
% Outputs:
%   DATA - Result in the layout originally supplied by the caller:
%            228453 x T         canonical input -> unchanged
%            91x109x91 x T      volume input    -> re-expanded to a volume
%            T x 228453         legacy input    -> transposed back
%
% Notes:
%   If the operation changed the number of time points, the volume is rebuilt
%   with the new T rather than the original one.
%
% See also: fmri_asvoxtime, fmri_vect2vol

if fmt.wasvol
    data = fmri_vect2vol(data);
elseif fmt.wastransposed
    data = data.';
end
end