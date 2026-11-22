function fs = fmri_scramblephases(f, dim)
% FMRI_SCRAMBLEPHASES  Phase-scrambles a brain volume or time series.
%
% Randomises the Fourier phases of the input while preserving its amplitude
% spectrum. The resulting surrogate retains the original power spectrum and
% corresponding circular autocorrelation structure, while disrupting the 
% temporal or spatial arrangement of the signal.
%
% This is useful for permutation tests that require surrogate data with the
% same spectral properties as the observed data but without its original
% phase relationships. Phase-scrambled surrogates can be used to build 
% permutation null distributions while preserving spatial or temporal 
% autocorrelation. This approach is used by fmri_acfestimate and 
% fmri_csdist for cluster-size correction.
%
% Usage:
%   fs = fmri_scramblephases(f)        % scramble across ALL dimensions
%   fs = fmri_scramblephases(f, dim)   % scramble along DIM only
%
% Inputs:
%   F    - Data to scramble, real and finite: a vector (one time series), a
%          volume (91 x 109 x 91), or a matrix (228453 x T).
%   DIM  - Dimension along which phases are scrambled. Each series along DIM
%          is processed independently. Default: [] applies one joint
%          N-dimensional transform across the full input array. The default 
%          is appropriate for a 3D volume or a 2D image, where the whole
%          spatial structure is to be randomised, and harmless for a vector,
%          which has only one dimension to scramble.
%
% Outputs:
%   FS   - Phase-scrambled array, the same size and floating-point class as F.
%          The result is real; the real() call in the code removes only 
%          the small imaginary component caused by numerical round-off.
%
% CHOOSING DIM
%   Leave DIM empty for a vector, or to jointly scramble the spatial structure
%   of a 2D image or a 3D volume. 
%
%   For a voxels x time matrix, use DIM = 2 to scramble each voxel time
%   series independently while preserving its temporal power spectrum:
%
%      fs = fmri_scramblephases(data, 2);     % data is 228453 x T
%
%   Omitting DIM for a matrix applies a joint transform across voxels and
%   time, altering both its spatial and temporal phase relationships.
%
%   Passing a 2D matrix without DIM therefore raises a warning: the function
%   cannot tell an image from a voxels x time matrix. Vectors and 3D volumes 
%   do not, since for them the joint form is the only sensible one.
%
%   The DIM form is vectorised - one FFT over the whole array rather than a loop
%   over voxels, which at 228453 voxels is the difference between seconds and
%   hours. No loop is needed for per-voxel temporal scrambling.
%
% HOW RANDOM PHASES ARE GENERATED
%   Random phases are obtained from the FFT of a real random array:
%   angle(fftn(rand(...))). Their conjugate symmetry ensures a real-valued 
%   surrogate while preserving the input amplitude spectrum to numerical precision.
%
% Examples:
%   % Surrogate volume with the same spatial autocorrelation
%   vol_null = fmri_scramblephases(vol3d);
%
%   % Null time series for every voxel, preserving each one's spectrum
%   data_null = fmri_scramblephases(data, 2);        % 228453 x T
%
%   % One regressor
%   reg_null = fmri_scramblephases(reg, 1);          % T x 1
%
%   % Null correlations for a permutation test
%   r_null = fmri_corregressor(fmri_scramblephases(reg, 1), data);
%
% References:
%   Ebisuzaki, W. (1997). A method to estimate the statistical significance
%   of a correlation when the data are serially correlated. Journal of
%   Climate, 10(6), 2147-2153.
%   Prichard, D. & Theiler, J. (1994). Generating surrogate data for time
%   series with several simultaneously measured variables. Physical Review
%   Letters, 73(7), 951-954.
%
% See also: fmri_acfestimate, fmri_corregressor, fmri_csdist

if ~isreal(f)
    error('fmri_scramblephases:complexInput', ...
          'F must be real; got a complex array.');
end
if any(~isfinite(f(:)))
    error('fmri_scramblephases:nonFinite', ...
          'F contains NaN or Inf. Remove non-finite values before scrambling.');
end
if ~isfloat(f)
    error('fmri_scramblephases:integerInput', ...
          ['F must be single or double: phase scrambling produces ' ...
           'floating-point values.\nCast first, e.g. ' ...
           'fmri_scramblephases(double(f)).']);
end
if nargin < 2 || isempty(dim)
    if ismatrix(f) && ~isvector(f) && ~isscalar(f)
        warning('fmri_scramblephases:ambiguousDim', ...
            ['No DIM on a 2D matrix scrambles across BOTH dimensions.\n' ...
             'For voxels x time, use fmri_scramblephases(data, 2).\n' ...
             'For a 2D image the joint form is correct: silence with\n' ...
             'warning(''off'', ''fmri_scramblephases:ambiguousDim'').']);
    end
    % All dimensions at once.
    fs = real(ifftn( abs(fftn(f)) .* exp(1i * angle(fftn(rand(size(f))))) ));
else
    if ~isscalar(dim) || dim < 1 || dim ~= fix(dim) || dim > ndims(f)
        error('fmri_scramblephases:badDim', ...
            'DIM must be an integer between 1 and ndims(F) = %d. Got %s.', ...
            ndims(f), mat2str(dim));
    end
    % Each series along DIM, independently (vectorised instead of looped: 
    % at 228453 voxels that is seconds against hours).
    F  = fft(f, [], dim);
    R  = fft(rand(size(f)), [], dim);
    fs = real(ifft( abs(F) .* exp(1i * angle(R)), [], dim ));
end

% Restore the input's floating-point class, such as single.
fs = cast(fs, 'like', f);