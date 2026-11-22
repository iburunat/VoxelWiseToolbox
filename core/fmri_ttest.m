function [t, p, df] = fmri_ttest(data1, data2, varargin)
% FMRI_TTEST  Voxelwise t-test across participants.
%
% Runs a t-test at every voxel and returns the t-statistic, the p-value and the
% degrees of freedom. Covers the three designs used in fMRI group analysis, and
% offers a permutation alternative when the normality assumption is doubtful.
%
% Usage:
%   [t, p, df] = fmri_ttest(x)                       % one-sample, x vs 0
%   [t, p, df] = fmri_ttest(x, y)                    % two-sample, x vs y
%   [t, p, df] = fmri_ttest(x, y, 'paired', true)    % paired
%   [t, p, df] = fmri_ttest(x, [], 'nperm', 5000)    % permutation, one-sample
%
% Inputs:
%   DATA1 - Voxels x participants. One column per participant.
%   DATA2 - Optional second group, voxels x participants. Leave empty ([]) for
%           a one-sample test. For a PAIRED test the columns must correspond,
%           i.e. column k of each is the same participant.
%
% Name-value options:
%   'paired'  - true for a paired test (requires equal numbers of columns).
%               Default: false.
%   'tail'    - 'both' (default), 'right' (DATA1 > DATA2), or 'left'.
%   'nperm'   - Number of permutations used to calculate p-values. Default: 0,
%               which uses the parametric t-distribution. For one-sample and
%               paired tests, permutations randomly flip participant signs;
%               for two-sample tests, they shuffle group labels. The observed
%               t-statistic and degrees of freedom are unchanged. Whole-brain
%               permutation tests may take several minutes, with progress
%               reported approximately every 10%.
% 
% Outputs:
%   T   - Voxels x 1 t-statistic.
%   P   - Voxels x 1 p-value.
%   DF  - Degrees of freedom (scalar).
%
% CHOOSING THE TEST
%   ONE-SAMPLE tests whether participant-level values differ from zero. In a
%   typical group analysis, each participant contributes one contrast map or
%   Fisher-z-transformed correlation map. The degrees of freedom are N-1,
%   where N is the number of participants. Temporal autocorrelation is a
%   first-level concern and does not enter this group-level test.
%
%   TWO-SAMPLE compares two independent groups, such as patients and controls.
%
%   PAIRED compares two measurements from the same participants, such as
%   pre- and post-intervention values. It is equivalent to a one-sample test
%   on the within-participant differences.
%
% PREPARING CORRELATION MAPS
%   Transform participant-level correlation maps before testing:
%
%       z_maps = atanh(r_maps);
%       [t, p] = fmri_ttest(z_maps);
%
%   Use ATANH rather than fmri_fisherz. fmri_fisherz also standardises the
%   transformed correlations by sqrt(df-3), which is not appropriate before
%   a group t-test.
%
% CONSTANT OR NON-FINITE VOXELS
%   Voxels with zero variance across participants, or with any non-finite
%   participant value, cannot produce a valid t-statistic. They are returned
%   as t = 0 and p = 1, keeping the output finite for subsequent analyses.
%
% Examples:
%   % Standard group analysis from per-participant correlation maps
%   z_maps  = atanh(r_maps);                 % voxels x participants
%   [t, p]  = fmri_ttest(z_maps);
%   sig     = p < 0.001;
%   fmri_showslices(t, 1, 2, [-6 6], [], [], 1, [], fmri_p2t(0.001, size(z_maps,2)-1));
%
%   % Patients vs controls
%   [t, p, df] = fmri_ttest(z_patients, z_controls);
%
%   % Permutation p-values, for small N or non-normal data
%   [t, p] = fmri_ttest(z_maps, [], 'nperm', 5000);
%
% See also: fmri_p2t, fmri_p2r, fmri_r2p, fmri_fisherz, fmri_effdf,
%           fmri_cleanclusters, fmri_tfce

%% --- arguments ------------------------------------------------------------
if nargin < 2, data2 = []; end

pa = inputParser;
pa.FunctionName = 'fmri_ttest';
addParameter(pa, 'paired', false, @(v) islogical(v) || isnumeric(v));
addParameter(pa, 'tail',   'both', @(s) ischar(s) || isstring(s));
addParameter(pa, 'nperm',  0,      @(v) isnumeric(v) && isscalar(v) && v >= 0);
parse(pa, varargin{:});
paired = logical(pa.Results.paired);
tail   = lower(char(pa.Results.tail));
nperm  = round(pa.Results.nperm);

if ~ismember(tail, {'both', 'right', 'left'})
    error('fmri_ttest:badTail', ...
        ['TAIL must be ''both'', ''right'' or ''left''.\n' ...
         'Got ''%s''.'], tail);
end
if ~ismatrix(data1) || ~isnumeric(data1)
    error('fmri_ttest:badData', ...
        ['DATA1 must be a numeric voxels x participants matrix.\n' ...
         'Got a %s of size %s.'], class(data1), mat2str(size(data1)));
end
if ~isreal(data1) || (~isempty(data2) && ~isreal(data2))
    error('fmri_ttest:complexInput', ...
          ['Input data must be real-valued. Note that an array counts as ' ...
           'complex if it is STORED as complex, even with a zero imaginary ' ...
           'part - apply real() if it came from an inverse FFT.']);
end
if size(data1, 2) < 2
    error('fmri_ttest:tooFewParticipants', ...
        ['DATA1 has %d column(s); a t-test needs at least 2 participants.\n' ...
         'Columns are participants and rows are voxels - transpose if reversed.'], ...
        size(data1, 2));
end
if ~isempty(data2)
    if size(data2, 1) ~= size(data1, 1)
        error('fmri_ttest:voxelMismatch', ...
            ['DATA1 and DATA2 must have the same number of voxels.\n' ...
             'Got %d and %d.'], size(data1, 1), size(data2, 1));
    end
    if paired && size(data2, 2) ~= size(data1, 2)
        error('fmri_ttest:pairMismatch', ...
            ['A paired test needs the same number of columns in both inputs.\n' ...
             'Got %d and %d. For independent groups omit ''paired''.'], ...
            size(data1, 2), size(data2, 2));
    end
end
if paired && isempty(data2)
    error('fmri_ttest:pairedNeedsTwo', ...
        ['''paired'' was requested but DATA2 is empty.\n' ...
         'Supply both conditions, or omit ''paired'' for a one-sample test.']);
end

%% --- reduce every design to a t-statistic ---------------------------------
if isempty(data2)
    design = 'one-sample';
    x = data1;
elseif paired
    design = 'paired';
    x = data1 - data2;                 % a paired test IS one-sample on the diffs
else
    design = 'two-sample';
end

switch design
    case {'one-sample', 'paired'}
        [t, df, flat] = local_onesample(x);
    case 'two-sample'
        [t, df, flat] = local_twosample(data1, data2);
end

% Voxels with no variance carry no evidence. FLAT comes from the helper, which
% computes it from the raw standard error before any patching - see the note
% there for why testing it here instead does not work.
flat = flat | ~isfinite(t);
t(flat) = 0;

%% --- p-values -------------------------------------------------------------
if nperm == 0
    p = local_tp(t, df, tail);
else
    p = local_permp(design, data1, data2, t, tail, nperm);
end
p(flat) = 1;

end

% =========================================================================
%  local helpers
% =========================================================================

function [t, df, flat] = local_onesample(x)
n  = size(x, 2);
m  = mean(x, 2);
sd = std(x, 0, 2);
se = sd ./ sqrt(n);
df = n - 1;

% FLAT is computed from the RAW standard error, before any patching, and
% returned so the caller can act on it. An earlier version patched se to eps
% here and left the caller testing `se == 0`, which by then could never be
% true - so a constant voxel came back as t = mean/eps ~ 1e16 with
% p ~ 1e-110, i.e. as the single most significant voxel in the map. The
% failure was silent because 1e16 is finite, so an isfinite check passed too.
flat = (se == 0) | ~isfinite(se);
se(flat) = 1;                         % placeholder; these entries are zeroed
t  = m ./ se;
t(flat) = 0;
end

function [t, df, flat] = local_twosample(a, b)
% Pooled-variance (Student) two-sample test.
n1 = size(a, 2);  n2 = size(b, 2);
m1 = mean(a, 2);  m2 = mean(b, 2);
v1 = var(a, 0, 2); v2 = var(b, 0, 2);
df = n1 + n2 - 2;
sp2 = ((n1-1)*v1 + (n2-1)*v2) / df;   % pooled variance
se  = sqrt(sp2 * (1/n1 + 1/n2));

flat = (se == 0) | ~isfinite(se);     % see the note in local_onesample
se(flat) = 1;
t   = (m1 - m2) ./ se;
t(flat) = 0;
end

function p = local_tp(t, df, tail)
% Student's t CDF via the regularised incomplete beta function. betainc is base
% MATLAB, so no Statistics Toolbox is required.
%
% The upper tail is computed directly as 0.5*I_x(df/2, 1/2) rather than as
% 1 - tcdf(|t|). The subtraction loses precision when p is small and saturates
% at exactly 0 for large |t|, which then silently survives any p < alpha test.
x  = df ./ (df + t.^2);
up = 0.5 * betainc(x, df/2, 0.5);     % P(T > |t|), for |t|
switch tail
    case 'both'
        p = 2 * up;
    case 'right'
        p = up;  p(t < 0) = 1 - up(t < 0);
    case 'left'
        p = up;  p(t > 0) = 1 - up(t > 0);
end
p = min(max(p, 0), 1);
end

function p = local_permp(design, data1, data2, t_obs, tail, nperm)
% Permutation null. The permutation scheme differs by design because what is
% exchangeable under the null differs:
%   one-sample / paired : the SIGN of each participant's value (the null says
%                         the distribution is symmetric about zero)
%   two-sample          : the group LABELS (the null says the two samples come
%                         from the same distribution)
t_start = tic;
step    = max(1, round(nperm / 10));

switch design
    case {'one-sample', 'paired'}
        if strcmp(design, 'paired'), x = data1 - data2; else, x = data1; end
        n = size(x, 2);
        cnt = zeros(size(t_obs));
        for k = 1:nperm
            s  = (rand(1, n) < 0.5) * 2 - 1;          % random +/-1 per participant
            tk = local_onesample(x .* s);   % first output only
            cnt = cnt + local_asExtreme(tk, t_obs, tail);
            local_progress(k, nperm, step, t_start);
        end
    case 'two-sample'
        n1 = size(data1, 2);
        allc = [data1, data2];
        n = size(allc, 2);
        cnt = zeros(size(t_obs));
        for k = 1:nperm
            idx = randperm(n);
            tk  = local_twosample(allc(:, idx(1:n1)), allc(:, idx(n1+1:end)));
            cnt = cnt + local_asExtreme(tk, t_obs, tail);
            local_progress(k, nperm, step, t_start);
        end
end
% (1 + count) / (1 + nperm) so p is never exactly 0: with a finite number of
% permutations, zero is not an attainable probability.
p = (1 + cnt) ./ (1 + nperm);
end

function e = local_asExtreme(tk, t_obs, tail)
switch tail
    case 'both',  e = abs(tk) >= abs(t_obs);
    case 'right', e = tk >= t_obs;
    case 'left',  e = tk <= t_obs;
end
end

function local_progress(k, nperm, step, t_start)
% One reporter called from both permutation loops, so the two cannot drift into
% printing different things. The same argument fmri_csdist makes applies here: a
% whole-brain run prints nothing for minutes, which a user cannot tell from a
% hang.
if mod(k, step) == 0 || k == nperm
    elapsed = toc(t_start);
    fprintf(['    permutation %d/%d (%.0f%%), %.0fs elapsed, ' ...
             '~%.0fs remaining\n'], ...
            k, nperm, 100 * k / nperm, elapsed, ...
            elapsed * (nperm - k) / k);
end
end