function [data, fmt] = fmri_asvoxtime(data, fname)
% FMRI_ASVOXTIME  Normalises brain data to the canonical voxels-by-time layout.
%
% Internal helper used by time-series functions on input. It converts accepted
% data layouts to the canonical voxels-by-time format for processing;
% fmri_restoreformat restores the original layout before output.
%
% The canonical layout is 228453 x T: one row per voxel, one column per scan.
%
% Usage:
%   [data, fmt] = fmri_asvoxtime(data)
%   [data, fmt] = fmri_asvoxtime(data, fname)
%
% Inputs:
%   DATA  - Brain data in any of the accepted layouts:
%             228453 x T           canonical, whole brain (voxels x time)
%             91 x 109 x 91 x T    4D volume
%             V x T                canonical, voxel subset (ROI, downsampled)
%             T x 228453           legacy transposed (deprecated)
%   FNAME - Name of the calling function, used in the deprecation warning.
%           Optional.
%
% Outputs:
%   DATA  - Data in canonical 228453 x T layout, class double.
%   FMT   - Struct recording the input layout, to be passed to
%           fmri_restoreformat so the output matches the input's shape.
%
% Notes:
%   Full-brain data are oriented automatically: 228453 x T is used directly,
%   while T x 228453 is transposed with a one-time warning.
%
%   Smaller voxel sets are assumed to be V x T because their orientation
%   cannot be determined from size alone. They are never transposed
%   automatically, although unusual shapes may trigger a warning. A single row
%   (1 x T, one time series) is exempt: it is the normal way to pass a
%   regressor and carries no ambiguity.
% 
% See also: fmri_restoreformat, fmri_vol2vect, fmri_vect2vol

persistent warned          % one-time deprecation notice per MATLAB session

NVOX = 228453;

if nargin < 2 || isempty(fname), fname = 'This function'; end

fmt = struct('wasvol', false, 'wastransposed', false, 'volsize', []);

if ndims(data) == 4
    % ---- 4D volume: vectorise through the standard brain mask ----------
    fmt.wasvol  = true;
    fmt.volsize = size(data);
    data = fmri_vol2vect(data);

elseif ismatrix(data)
    [r, c] = size(data);
    if r == NVOX
        % ---- canonical, full brain: unambiguous ---------------------------
    elseif c == NVOX
        % ---- legacy transposed, full brain: correct it and warn once ------
        fmt.wastransposed = true;
        data = data.';
        
        if isempty(warned)
            warned = true;
            warning('fmri:deprecatedOrientation', ...
                ['%s received data as %d x %d (time x voxels).\n' ...
                 'The canonical layout is %d x T (voxels x time), and all toolbox\n' ...
                 'functions now use it, so transposing is no longer necessary.\n' ...
                 'The input has been transposed automatically and the output will\n' ...
                 'be returned in the layout you supplied. Please update your code:\n' ...
                 '    data = %s(data, ...);      %% no transposes\n' ...
                 'This notice is shown once per session. To silence it entirely:\n' ...
                 '    warning(''off'', ''fmri:deprecatedOrientation'')'], ...
                 fname, r, c, NVOX, lower(fname));
        end
    else
        % ---- voxel subset -------------------------------------------------------
        % Assume voxels x time: subset orientation cannot be inferred from size.
        % Warn about unusual shapes but never transpose. A single row (1 x T) is
        % one time series, not ambiguous, so it is exempt.
        if r > 1 && c > 4 * r && isempty(warned)
            warned = true;
            warning('fmri:ambiguousOrientation', ...
                ['%s received a %d x %d matrix and is treating it as %d voxels x\n' ...
                 '%d time points (the canonical layout). If you meant the reverse,\n' ...
                 'transpose the input before calling: %s(data.'', ...).\n' ...
                 'Full-brain data (%d voxels) is detected and oriented\n' ...
                 'automatically; subsets are always assumed to be voxels x time.\n' ...
                 'This notice is shown once per session; to silence it:\n' ...
                 '    warning(''off'', ''fmri:ambiguousOrientation'')'], ...
                 fname, r, c, r, c, lower(fname), NVOX);
        end
    end

else
    error('fmri:badInput', ...
        '%s expects a 2D matrix or a 4D volume, but received a %dD array.', ...
        fname, ndims(data));
end

data = double(data);
end