% TEST_ISC_STREAMING  Does the streaming path give the same answer as the array?
%
% The streaming leave-one-out computation replaces
%       mean(data(:,:,[1:s-1 s+1:end]), 3)
% with
%       (total - data(:,:,s)) / (N-1)
% which is algebraically identical but reaches the same numbers by a different
% route. This test asserts they agree to floating-point tolerance rather than
% assuming it, because a subtraction-based mean can differ in the last bits from
% a direct one and an error in the (N-1) divisor would be invisible in a single
% map inspected by eye.
%
% Also checks that the paths refused for streaming - pairwise and permutations -
% raise their own identifiers rather than failing obscurely or, worse, running
% for hours.
%
% See also: fmri_isc

fmritoolbox_setup;
fprintf('=== fmri_isc: streaming vs in-memory ===\n\n');

rng(7);
V = 500;  T = 80;  N = 6;

% A shared signal plus per-participant noise, so ISC is genuinely non-zero and
% the comparison is not made on a map of near-identical zeros.
shared = randn(1, T);
data   = 0.8 * randn(V, T, N);
data(1:120, :, :) = data(1:120, :, :) + repmat(shared, [120 1 N]);

%% --- in-memory reference ---------------------------------------------------
isc_mem = fmri_isc(data, 'leaveoneout');
fprintf('--- in-memory ---\n');
fprintf('  ISC range %.4f to %.4f, median %.4f\n', ...
        min(isc_mem), max(isc_mem), median(isc_mem));
fprintf('  inside the shared block  : %.3f\n', mean(isc_mem(1:120)));
fprintf('  outside it               : %.3f\n\n', mean(isc_mem(121:end)));
assert(mean(isc_mem(1:120)) > 5 * abs(mean(isc_mem(121:end))), ...
    'The shared signal was not recovered; the rest of the test would be vacuous.');

%% --- same data, streamed from disk -----------------------------------------
tmp = fullfile(tempdir, sprintf('isc_stream_%d', feature('getpid')));
if ~exist(tmp, 'dir'), mkdir(tmp); end
cleanupDir = onCleanup(@() rmdir(tmp, 's'));

for s = 1:N
    d = data(:, :, s);                                  %#ok<NASGU>
    save(fullfile(tmp, sprintf('subj_%02d.mat', s)), 'd');
end

isc_dir = fmri_isc(tmp, 'leaveoneout');

files    = arrayfun(@(s) fullfile(tmp, sprintf('subj_%02d.mat', s)), 1:N, ...
                    'UniformOutput', false);
isc_cell = fmri_isc(files, 'leaveoneout');

fprintf('--- streaming ---\n');
d1 = max(abs(isc_mem - isc_dir));
d2 = max(abs(isc_mem - isc_cell));
fprintf('  max |array - directory|  : %.2e\n', d1);
fprintf('  max |array - cell array| : %.2e\n', d2);
assert(d1 < 1e-12, 'Directory streaming disagrees with the in-memory result by %.2e', d1);
assert(d2 < 1e-12, 'Cell-array streaming disagrees with the in-memory result by %.2e', d2);
fprintf('  identical to floating-point tolerance\n\n');

%% --- refusals carry their own identifiers ----------------------------------
fprintf('--- streaming refusals ---\n');
check(@() fmri_isc(tmp, 'pairwise'),          'fmri_isc:pairwiseNeedsMemory');
check(@() fmri_isc(tmp, 'leaveoneout', 100),  'fmri_isc:permNeedsMemory');
check(@() fmri_isc(fullfile(tmp,'nowhere')),  'fmri_isc:noFiles');
check(@() fmri_isc(data(:,:,1:2)),            'fmri_isc:tooFewSubjects');
check(@() fmri_isc(data, 'sideways'),         'fmri_isc:badMethod');

fprintf('\ndone.\n');

function check(fn, want)
try
    fn();
    fprintf('  %-34s NOT CAUGHT\n', want);
catch ME
    if strcmp(ME.identifier, want)
        fprintf('  %-34s caught\n', want);
    else
        fprintf('  %-34s WRONG ERROR: %s\n', want, ME.identifier);
    end
end
end
