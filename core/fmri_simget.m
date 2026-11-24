function out = fmri_simget(X_compressed, svd_info, p, as_vector)
% FMRI_SIMGET  Extracts one participant's fMRI data from fmri_simdata output.
%
% Reconstructs the 4D fMRI volume (or 228453 x T brain vector) for a single
% participant from the SVD-compressed output of fmri_simdata.
%
% Usage:
%   data = fmri_simget(X_compressed, svd_info, p)       % 228453 x T
%   X4D  = fmri_simget(X_compressed, svd_info, p, 0)    % 91 x 109 x 91 x T
%
% Inputs:
%   X_COMPRESSED - Cell array {1 x N_PARTICIPANTS} of SVD-compressed data.
%                  Each cell contains a struct with fields U, S, V.
%                  Reconstruct one participant at a time.
%   SVD_INFO     - Struct array (1 x N) with the singular values and volume
%                  dimensions, as returned by fmri_simdata.
%   P            - Participant index (integer in [1, N]).
%   AS_VECTOR    - If 1 (default), return vectorized brain data (228453 x T).
%                  If 0, return the full 4D volume (91 x 109 x 91 x T).
%
% Outputs:
%   OUT  - Reconstructed fMRI data: vectorized brain data (228453 x T) by
%          default, or the 4D volume (91 x 109 x 91 x T) if AS_VECTOR = 0.
%
% Note:
%   fmri_simdata uses truncated SVD compression, retaining enough components
%   to explain 95% of the variance by default. The reconstructed data are
%   therefore a low-rank approximation of the simulated data. For the exact
%   simulated volumes, request X_FULL from fmri_simdata.
%
% Examples:
%   % Analyse one participant: reconstruct, then correlate with the task
%   [X_comp, S_3D, W, svd_info] = fmri_simdata(10, 8, 200, 2);
%   data = fmri_simget(X_comp, svd_info, 1);        % participant 1, 228453 x T
%   r    = fmri_corregressor(W.bold(:, 1, 1), data);
%   fmri_showslices(r, 1, 2, [-0.8 0.8]);
%
%   % A map purely for trying the display functions: no data and no analysis,
%   % just the source maps combined with chosen weights, two positive and two
%   % negative. This is NOT a statistical map; see demo_glm.
%   S   = fmri_vol2vect(S_3D);                      % 228453 x N_SOURCES
%   map = S(:, 1:4) * [3 2.7 -3 -2.4]';
%   fmri_showslices(map, 1, 2, [-4 4], [], [], 1, [], 1);
%
% See also: fmri_simdata, fmri_vol2vect, fmri_vect2vol

if nargin < 4 || isempty(as_vector), as_vector = 1; end

if p < 1 || p > numel(X_compressed)
    error('fmri_simget:participantOutOfRange', ...
        'Participant index %d is out of range [1 %d].', p, numel(X_compressed));
end

% reconstruct 2D (voxels x T) from the compressed (truncated) SVD
svd_p = X_compressed{p};
if ~all(isfield(svd_p, {'U', 'S', 'V'}))
    error('fmri_simget:badStruct', ...
          ['X_COMPRESSED{%d} is missing U/S/V fields.\n' ...
           'Pass the cell array returned by fmri_simdata unchanged.'], p);
end
X2D = svd_p.U * svd_p.S * svd_p.V';   % (xdim*ydim*zdim) x T

% reshape to the full 4D grid using the stored dimensions
if ~all(isfield(svd_info, {'xdim', 'ydim', 'zdim'}))
    error('fmri_simget:badInfo', ...
          'SVD_INFO is missing xdim/ydim/zdim. Pass the struct from fmri_simdata.');
end
xdim = svd_info(p).xdim;
ydim = svd_info(p).ydim;
zdim = svd_info(p).zdim;
if size(X2D, 1) ~= xdim * ydim * zdim
    error('fmri_simget:sizeMismatch', ...
          ['Reconstructed data has %d rows but the stored dimensions imply ' ...
           '%d (%dx%dx%d). X_COMPRESSED and SVD_INFO may be mismatched.'], ...
          size(X2D,1), xdim*ydim*zdim, xdim, ydim, zdim);
end
X4D = reshape(X2D, xdim, ydim, zdim, size(X2D,2));

if as_vector
    out = fmri_vol2vect(X4D);   % 228453 x T
else
    out = X4D;
end
end