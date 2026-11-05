% TEST_SCRAMBLEPHASES  Does the DIM argument scramble the axis it claims to?
%
% fmri_scramblephases originally applied an N-dimensional FFT, which scrambles
% every dimension jointly. For a VOXELS x TIME matrix that also randomises phase
% across voxels, destroying the spatial arrangement along with the temporal one -
% almost never what is wanted, and silent when it happens.
%
% These tests check that DIM = 2 does what the vectorised loop over rows would
% do, that the amplitude spectrum survives, that the ambiguous 2D case warns,
% and that fmri_isc still agrees with itself now that it delegates here rather
% than carrying its own copy.
%
% See also: fmri_scramblephases, fmri_isc, fmri_acfestimate

fmritoolbox_setup;
fprintf('=== fmri_scramblephases: DIM argument ===\n\n');

rng(11);
V = 40;  T = 128;
M = cumsum(randn(V, T), 2);          % autocorrelated rows, so the spectrum is
                                     % structured rather than flat

%% --- DIM = 2 preserves each row's amplitude spectrum exactly ---------------
S = fmri_scramblephases(M, 2);

amp_in  = abs(fft(M, [], 2));
amp_out = abs(fft(S, [], 2));
d = max(abs(amp_in(:) - amp_out(:))) / max(amp_in(:));

fprintf('--- DIM = 2: amplitude spectrum per row ---\n');
fprintf('  max relative difference : %.2e\n', d);
fprintf('  output is real          : %s\n', string(isreal(S)));
assert(d < 1e-10, 'Amplitude spectrum not preserved (relative error %.2e)', d);
assert(isreal(S), 'Output is not real; the conjugate symmetry was broken.');
fprintf('  preserved\n\n');

%% --- DIM = 2 matches a per-row loop ---------------------------------------
% Not value-for-value: each call draws its own random phases. What must match is
% the STATISTICAL behaviour - every row keeps its own spectrum and loses its
% temporal alignment - so the test compares spectra, not samples.
fprintf('--- DIM = 2 vs a per-row loop ---\n');
L = zeros(V, T);
for v = 1:V
    L(v, :) = fmri_scramblephases(M(v, :), 2);
end
amp_loop = abs(fft(L, [], 2));
d2 = max(abs(amp_in(:) - amp_loop(:))) / max(amp_in(:));
fprintf('  loop, max relative difference : %.2e\n', d2);
fprintf('  %s\n\n', ternary(d2 < 1e-10, 'the vectorised and looped forms agree', ...
        '*** THEY DISAGREE'));
assert(d2 < 1e-10, 'Vectorised and looped forms disagree (relative error %.2e)', d2); 

%% --- the scrambling is temporal, not spatial ------------------------------
% The decisive check. Column correlations across voxels should survive DIM = 2
% (each row is scrambled independently, so the spatial pattern at a given time
% is destroyed) - but crucially, the ROW spectra survive while the row VALUES
% decorrelate from the original. Joint scrambling would destroy both.
fprintf('--- temporal, not joint ---\n');
r_row = mean(arrayfun(@(v) fmri_corrmat(M(v,:)', S(v,:)'), 1:V));
fprintf('  mean fmri_corrmat(original row, scrambled row) : %+.3f (expect near 0)\n', r_row);
assert(abs(r_row) < 0.3, 'Rows did not decorrelate; scrambling had little effect.');

J = fmri_scramblephases(M, 1);       % scramble DOWN columns instead
amp_col_in  = abs(fft(M, [], 1));
amp_col_out = abs(fft(J, [], 1));
d3 = max(abs(amp_col_in(:) - amp_col_out(:))) / max(amp_col_in(:));
fprintf('  DIM = 1 preserves column spectra       : %.2e\n', d3);
assert(d3 < 1e-10, 'DIM = 1 did not preserve the column spectra (%.2e)', d3);           
fprintf('  each dimension is scrambled independently of the other\n\n');

%% --- the ambiguity warning -------------------------------------------------
fprintf('--- warning on a 2D matrix without DIM ---\n');
lastwarn('');
w = warning('off', 'fmri_scramblephases:ambiguousDim');
fmri_scramblephases(M);
warning(w);
[~, id] = lastwarn;
fprintf('  identifier raised : %s\n', ternary(isempty(id), '(none)', id));
assert(strcmp(id, 'fmri_scramblephases:ambiguousDim'), ...
    'The 2D ambiguity warning was not raised.');

% Vectors and volumes must NOT warn: for them the joint form is correct.
for tc = {{randn(T,1), 'column vector'}, {randn(1,T), 'row vector'}, ...
          {randn(9,11,7), '3D volume'}}
    lastwarn('');
    fmri_scramblephases(tc{1}{1});
    [~, id2] = lastwarn;
    fprintf('  %-14s warns : %s\n', tc{1}{2}, ternary(isempty(id2), 'no (correct)', ...
            ['*** ' id2]));
    assert(isempty(id2), '%s should not warn.', tc{1}{2});
end
fprintf('\n');

%% --- validation ------------------------------------------------------------
fprintf('--- validation ---\n');
check(@() fmri_scramblephases(M, 0),  'fmri_scramblephases:badDim');
check(@() fmri_scramblephases(M, 5),  'fmri_scramblephases:badDim');
check(@() fmri_scramblephases(M, 1.5),'fmri_scramblephases:badDim');

%% --- fmri_isc still works after delegating ---------------------------------
fprintf('\n--- fmri_isc with the delegated scramble ---\n');
rng(3);
Vs = 300;  Ts = 60;  N = 5;
shared = randn(1, Ts);
D = 0.9 * randn(Vs, Ts, N);
D(1:80, :, :) = D(1:80, :, :) + repmat(shared, [80 1 N]);

[isc, p] = fmri_isc(D, 'leaveoneout', 200);
fprintf('  ISC inside the shared block : %.3f\n', mean(isc(1:80)));
fprintf('  ISC outside it              : %.3f\n', mean(isc(81:end)));
fprintf('  p inside  (median)          : %.4f\n', median(p(1:80)));
fprintf('  p outside (median)          : %.4f\n', median(p(81:end)));
assert(mean(isc(1:80)) > 5*abs(mean(isc(81:end))), 'Shared signal not recovered.');
assert(median(p(1:80)) < median(p(81:end)), ...
    'Permutation p-values do not separate signal from noise.');
assert(min(p) > 0, 'A permutation p-value of exactly 0 is not attainable.');
fprintf('  signal separates from noise, and no p-value is exactly zero\n');

fprintf('\ndone.\n');

function check(fn, want)
raised = true;
try
    fn();
    raised = false;
catch ME
    assert(strcmp(ME.identifier, want), 'Expected %s, got %s', want, ME.identifier);
    fprintf('  %-34s caught\n', want);
end
assert(raised, '%s: no error was raised', want);
end

function out = ternary(cond, a, b)
if cond, out = a; else, out = b; end
end
