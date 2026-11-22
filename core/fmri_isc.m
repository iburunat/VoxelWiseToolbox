function [isc, p] = fmri_isc(data, method, n_perm)
% FMRI_ISC  Voxelwise intersubject correlation (ISC).
%
% Computes intersubject correlation (ISC) at each voxel, measuring the
% similarity of participants' time series while they experience the same
% stimulus. Participant data can be supplied as an in-memory array or read
% from disk one participant at a time, allowing full-resolution datasets to
% be analysed with substantially lower memory requirements.
% 
%
% Usage:
%   isc      = fmri_isc(data)
%   isc      = fmri_isc(data, method)
%   [isc, p] = fmri_isc(data, method, n_perm)
%
% Inputs:
%   DATA    - Participants' time series, in any of three forms:
%               * 228453 x T x N numeric array (all participants in memory)
%               * cell array of paths to .mat files, one per participant
%               * path to a directory containing one .mat file per participant
%
%             The latter two options read one participant at a time and are
%             recommended for full-resolution datasets. For example, data with
%             228453 voxels, 451 volumes and 15 participants require 12.4 GB
%             in memory, compared with about 1.7 GB when streamed.
%
%             Each .mat file must contain a single variable, or one named 
%             'data' or 'voldata'.
%
%             Streaming supports only 'leaveoneout' without permutations.
%             Pairwise ISC and permutation testing require repeated access to
%             every participant and are therefore available only for in-memory
%             data.
% 
%   METHOD  - 'leaveoneout' (default) or 'pairwise'.
%   N_PERM  - Number of phase-scrambling permutations for p-values
%             (default 0, no permutation testing).
%
% Outputs:
%   ISC     - 228453 x 1 vector of ISC values, obtained by Fisher-z averaging
%             participant correlations. Voxels where the correlation is
%             undefined, such as a zero-variance time series in any
%             participant, are returned as NaN.
%   P       - 228453 x 1 vector of permutation p-values, or [] if N_PERM = 0.
%             Voxels with non-finite ISC are assigned p = 1.
%
% Description:
%   Leave-one-out ISC (Hasson et al., 2004): at each voxel, correlate each
%   participant's time series with the mean of the others, then average the
%   correlations in Fisher-z space.
%
%   Pairwise ISC: at each voxel, correlate every pair of participants and
%   average the N*(N-1)/2 correlations in Fisher-z space. Values are typically
%   lower than leave-one-out ISC because a group mean is generally less noisy
%   than an individual time series.
%
%   Permutation p-values: independently phase-scramble each participant's time
%   series at every voxel, preserving its power spectrum while disrupting
%   intersubject synchrony. The p-value is the proportion of permutations with
%   ISC equal to or greater than the observed value, using a standard +1
%   correction to prevent p = 0.
% 
% Examples:
%   isc = fmri_isc(data);
%   [isc, p] = fmri_isc(data, 'leaveoneout', 1000);
%   fmri_showslices(isc .* (p < 0.05), 1, 2, [0.1 0.6]);
%
% References:
%   Hasson, U., Nir, Y., Levy, I., Fuhrmann, G. & Malach, R. (2004).
%   Intersubject synchronization of cortical activity during natural vision.
%   Science, 303(5664), 1634-1640.
%   Nastase, S.A., Gazzola, V., Hasson, U. & Keysers, C. (2019). Measuring
%   shared responses across subjects using intersubject correlation. Social
%   Cognitive and Affective Neuroscience, 14(6), 667-685.
%
% See also: fmri_corrvoldata, fmri_fisherz, fmri_scramblephases

if nargin < 2 || isempty(method), method = 'leaveoneout'; end
if nargin < 3 || isempty(n_perm), n_perm = 0;             end

% Accept an in-memory array or a streaming source. For streaming input,
% leave-one-out ISC is computed without loading all participants at once:
%
%     mean of others = (running_sum - subject_s) / (N - 1)
%
% This requires only the running sum and one participant in memory.
[src, n_subj, streaming] = local_source(data);

if ~ismember(lower(method), {'leaveoneout', 'pairwise'})
    error('fmri_isc:badMethod', ...
        ['METHOD must be ''leaveoneout'' or ''pairwise''. Got ''%s''.'], method);
end
if n_subj < 3
    error('fmri_isc:tooFewSubjects', ...
        ['ISC needs at least 3 participants, got %d.'], n_subj);
end

method = lower(method);

if streaming && strcmp(method, 'pairwise')
    error('fmri_isc:pairwiseNeedsMemory', ...
        ['The pairwise method is not available for a streaming input.\n' ...
         'It visits every pair, so streaming would re-read each participant ' ...
         'N-1 times -\nfor 15 participants that is 210 file reads rather than ' ...
         '15. Use ''leaveoneout'',\nwhich answers the same question in one ' ...
         'pass, or pass\nthe data as an array if it fits in memory.']);
end

if streaming && n_perm > 0
    error('fmri_isc:permNeedsMemory', ...
        ['Permutation p-values are not available for a streaming input.\n' ...
         'Each permutation requires freshly scrambled data for every ' ...
         'participant, so %d\npermutations would mean %d file reads. Compute ' ...
         'the ISC map by streaming, then\nassess significance on a reduced ' ...
         'voxel set held in memory - a brain mask or a\nregion of interest - ' ...
         'where the array form fits comfortably.'], n_perm, 2*n_perm*n_subj);
end

isc = isc_compute(src, method, streaming);

if n_perm > 0
    % Permutations require in-memory data, so DATA is a V x T x N numeric array
    % here. Preallocate DATA_PERM once to avoid creating or detaching a full-size
    % array on every permutation.
    bad0      = ~isfinite(isc);          % undefined OBSERVED ISC
    bad       = bad0;
    ge_count  = zeros(numel(isc), 1);
    data_perm = zeros(size(data), 'like', data);

    fprintf('  ISC permutation test: %d permutations\n', n_perm);
    t_start = tic;
    step    = max(1, round(n_perm / 10));

    for k = 1:n_perm
        for s = 1:n_subj
            data_perm(:,:,s) = fmri_scramblephases(data(:,:,s), 2);
        end
        isc_null = isc_compute(data_perm, method, false);

        % A non-finite null ISC would incorrectly lower p because NaN >= ISC is false.
        % Phase scrambling can (rarely) produce an undefined ISC. Mark affected
        % voxels and assign p = 1 instead of aborting a long-running permutation test.
        bad      = bad | ~isfinite(isc_null);
        ge_count = ge_count + (isfinite(isc_null) & isc_null >= isc);

        if mod(k, step) == 0 || k == n_perm
            elapsed = toc(t_start);
            fprintf(['    permutation %d/%d (%.0f%%), %.0fs elapsed, ' ...
                     '~%.0fs remaining\n'], ...
                    k, n_perm, 100 * k / n_perm, elapsed, ...
                    elapsed * (n_perm - k) / k);
        end
    end

    % Apply the standard +1 correction so permutation p-values are never zero.
    % Assign p = 1 when the observed or null ISC is undefined (no valid
    % significance test can be performed at those voxels).
    p = (1 + ge_count) / (1 + n_perm);
    p(bad) = 1;

    if any(bad & ~bad0)
        warning('fmri_isc:nonfiniteNull', ...
            ['%d voxel(s) had a finite observed ISC but a non-finite value in ' ...
             'at least one permutation; they are returned with p = 1.'], ...
            nnz(bad & ~bad0));
    end
else
    p = [];
end

end % main function
% --- helper -----------------------------------------------------------------
function isc = isc_compute(src, method, streaming)

n_subj = local_count(src, streaming);

if strcmp(method, 'leaveoneout')
    % Two passes through the data. The first accumulates the sum across
    % participants. The second computes each participant's leave-one-out
    % reference by subtraction, avoiding a separate array of the other
    % participants:
    %       mean of others = (total - subject_s) / (N - 1)
    % This gives the exact leave-one-out mean while substantially reducing
    % memory requirements, making full-resolution streaming practical.    
    total = [];
    for s = 1:n_subj
        d = local_get(src, s, streaming);
        if isempty(total), total = zeros(size(d)); end
        total = total + d;
    end

    z_sum = [];
    for s = 1:n_subj
        d      = local_get(src, s, streaming);
        others = (total - d) / (n_subj - 1);
        r_s    = fmri_corrvoldata(d, others);
        if isempty(z_sum), z_sum = zeros(size(r_s)); end
        z_sum  = z_sum + atanh(r_s);
    end
    isc = tanh(z_sum / n_subj);

else  % pairwise, in-memory only
    [n_vox, ~, ~] = size(src);
    z_sum   = zeros(n_vox, 1);
    n_pairs = 0;
    for s1 = 1:n_subj
        for s2 = s1+1:n_subj
            z_sum   = z_sum + atanh(fmri_corrvoldata(src(:,:,s1), src(:,:,s2)));
            n_pairs = n_pairs + 1;
        end
    end
    isc = tanh(z_sum / n_pairs);
end

end

% --- streaming source helpers -----------------------------------------------

function [src, n_subj, streaming] = local_source(data)
% DATA may be a V x T x N array, a cell array of file paths, or a directory
% containing one .mat file per participant.
if isnumeric(data)
    if ndims(data) ~= 3
        error('fmri_isc:badInput', ...
            ['DATA must be a 228453 x T x N array, a cell array of file paths, ' ...
             'or a directory.\nGot a numeric array of size %s.'], mat2str(size(data)));
    end
    src = data; n_subj = size(data, 3); streaming = false; return
end

if ischar(data) || isstring(data)
    d = dir(fullfile(char(data), '*.mat'));
    if isempty(d)
        error('fmri_isc:noFiles', ...
            'No .mat files found in %s.', char(data));
    end
    src = arrayfun(@(f) fullfile(f.folder, f.name), d, 'UniformOutput', false);
elseif iscell(data)
    src = data;
else
    error('fmri_isc:badInput', ...
        ['DATA must be a numeric array, a cell array of file paths, or a ' ...
         'directory path.\nGot a %s.'], class(data));
end

missing = src(~cellfun(@(f) exist(f, 'file') == 2, src));
if ~isempty(missing)
    error('fmri_isc:missingFile', ...
        'File not found: %s', missing{1});
end
n_subj = numel(src); streaming = true;
end

function n = local_count(src, streaming)
if streaming, n = numel(src); else, n = size(src, 3); end
end

function d = local_get(src, s, streaming)
% One participant as V x T. Files must contain a single variable, or one named
% 'data' or 'voldata'.
if ~streaming, d = src(:,:,s); return, end
S = load(src{s});
f = fieldnames(S);
if isfield(S, 'data'),         d = S.data;
elseif isfield(S, 'voldata'),  d = S.voldata;
elseif numel(f) == 1,          d = S.(f{1});
else
    error('fmri_isc:ambiguousFile', ...
        ['%s contains %d variables (%s) and none is named ''data'' or ' ...
         '''voldata'',\nso the time series cannot be identified.'], ...
        src{s}, numel(f), strjoin(f', ', '));
end
d = double(d);
end