function tests = test_temporal
% TEST_TEMPORAL  Unit tests for the temporal preprocessing module.
%
% Verifies that the vectorised, canonical-orientation rewrites of fmri_detrend,
% fmri_tempsmooth, fmri_correctmovement and fmri_bandpassfilter reproduce the
% behaviour of the original implementations (kept in tests/legacy as *_old.m),
% and that the orientation contract holds.
%
% This file lives in core/ rather than tests/ because three tests exercise
% fmri_asvoxtime, which is private and so visible only from the parent folder.
% setupOnce therefore locates tests/legacy from the toolbox root rather than
% relative to this file, and asserts it exists - the comparisons would
% otherwise pass on a stale path entry and fail only in a fresh session.
%
% Run with:
%   results = runtests('test_temporal')

tests = functiontests(localfunctions);
end

% =========================================================================
% Setup
% =========================================================================
function setupOnce(tc)
% Small synthetic dataset: drift + signal + noise. Small V keeps the legacy
% voxel-loop implementations fast enough to use as a reference.
rng(42);
V = 200; T = 150;
t = (1:T);
drift  = (1:V)' * 0.01 .* (t / T).^2 * 50;         % quadratic drift per voxel
signal = sin(2*pi*0.03*t) .* (rand(V,1)*2);        % slow BOLD-like signal
noise  = randn(V, T) * 2;
tc.TestData.data = 100 + drift + signal + noise;   % V x T, canonical
tc.TestData.V = V;
tc.TestData.T = T;

% Motion regressors: 6 columns, T rows
tc.TestData.rp = cumsum(randn(T, 6) * 0.1);

% The toolbox root, found from this file wherever it lives. This test now sits
% in core/ (it needs fmri_asvoxtime, which is private and so visible only from
% the parent folder), but legacy/ is beside tests/. Deriving both from the root
% means moving the file again cannot silently break the reference copies - the
% *_old comparisons would otherwise keep passing on a stale path entry and fail
% only in a fresh session.
here = fileparts(mfilename('fullpath'));
root = fileparts(here);                  % core/ -> toolbox root
addpath(root);
legacydir = fullfile(root, 'tests', 'legacy');   
assert(isfolder(legacydir), ...
    'legacy/ not found at %s; the *_old equivalence tests cannot run.', legacydir);
addpath(legacydir);

end

% =========================================================================
% fmri_detrend
% =========================================================================
function testDetrendMatchesLegacy(tc)
% The vectorised implementation must reproduce the voxel-loop original to
% floating-point precision, for every knot count.
data = tc.TestData.data;
for K = [3 4 6 10 20]
    ref = fmri_detrend_old(data, K);
    new = fmri_detrend(data, K);
    verifyEqual(tc, new, ref, 'AbsTol', 1e-9, ...
        sprintf('fmri_detrend differs from legacy at K = %d.', K));
end
end

function testDetrendDefaultKnots(tc)
% Default must remain 6 knots.
data = tc.TestData.data;
verifyEqual(tc, fmri_detrend(data), fmri_detrend(data, 6), 'AbsTol', 1e-12);
end

function testDetrendMeanCentres(tc)
% Each voxel time series is mean-centred on output.
out = fmri_detrend(tc.TestData.data, 6);
verifyEqual(tc, mean(out, 2), zeros(tc.TestData.V, 1), 'AbsTol', 1e-9);
end

function testDetrendRemovesDrift(tc)
% Detrending should massively reduce the variance of a slow drift. A linear
% ramp is NOT removed to exactly zero: the spline anchors are means of the
% scans nearest each knot, and the end knots average one-sided windows, so
% their anchor values sit slightly inward and the fit cannot reach the true
% ramp value at the very edges (the documented edge effect). The right thing
% to assert is therefore a large drop in variance, not an absolute zero.
T    = 150;
ramp = repmat(linspace(0, 100, T), 200, 1);     % 200 voxels x 150 scans (V > T)
out  = fmri_detrend(ramp, 6);

var_ratio = var(out(1, :)) / var(ramp(1, :));
verifyLessThan(tc, var_ratio, 0.01, ...
    'Detrending should reduce drift variance by at least 100x.');

interior = out(:, 21:130);
verifyLessThan(tc, max(abs(interior(:))), 1.0, ...
    'Interior residual after detrending a ramp should be small.');
end

function testDetrendRejectsBadKnots(tc)
data = tc.TestData.data;
verifyError(tc, @() fmri_detrend(data, 1),    'fmri_detrend:tooFewKnots');
verifyError(tc, @() fmri_detrend(data, 1000), 'fmri_detrend:tooManyKnots');
end

% =========================================================================
% fmri_tempsmooth
% =========================================================================
function testTempsmoothMatchesLegacyUpToGain(tc)
% The rewrite deliberately changes two things: the kernel is now normalised
% (the legacy kernel summed to ~0.5, so it halved the data), and the kernel
% spans +/-4 sigma rather than a fixed +/-32 s window. Everything else is
% unchanged. So at TR = 2 s the new output must equal the legacy output
% divided by the legacy kernel's sum, to within the truncation difference.
data = tc.TestData.data;
for sigma = [2 4 6 8]
    ref = fmri_tempsmooth_old(data, sigma);         % legacy: TR = 2 implied
    new = fmri_tempsmooth(data, sigma, 2);

    gain = sum(normpdf(-32:2:32, 0, sigma));        % the legacy kernel's sum
    % RelTol 1e-3 is deliberate, not loose: the new kernel spans +/-4 sigma while
    % the legacy kernel spanned a fixed +/-32 s, so the two differ by a genuine
    % ~5e-5 truncation term. The exact property (correlation identical) is
    % asserted separately in testTempsmoothPreservesCorrelationExactly.
    verifyEqual(tc, new, ref / gain, 'RelTol', 1e-3, ...
        sprintf('fmri_tempsmooth differs from rescaled legacy at sigma = %g.', sigma));
end
end

function testTempsmoothPreservesCorrelationExactly(tc)
% The guarantee that matters scientifically: because the only change at TR = 2
% is a constant scale factor, every correlation-based result is unchanged.
data = tc.TestData.data;
for sigma = [2 4 8]
    ref = fmri_tempsmooth_old(data, sigma);
    new = fmri_tempsmooth(data, sigma, 2);
    r = zeros(tc.TestData.V, 1);
    for v = 1:tc.TestData.V
        r(v) = corr(ref(v,:)', new(v,:)');
    end
    verifyEqual(tc, r, ones(tc.TestData.V, 1), 'AbsTol', 1e-6, ...
        sprintf(['Correlation between legacy and new output is not 1 at ' ...
                 'sigma = %g; the change is not a pure rescaling.'], sigma));
end
end

function testTempsmoothUnitGain(tc)
% A constant signal must survive smoothing unchanged. This is the property the
% legacy implementation lacked: its unnormalised kernel scaled the data by ~0.5.
const = ones(300, 200) * 7;                % 300 voxels x 200 scans (V > T)
out   = fmri_tempsmooth(const, 4, 2);
mid   = out(:, 50:150);                    % away from the edges
verifyEqual(tc, mid, ones(300, 101) * 7, 'AbsTol', 1e-9, ...
    'Smoothing must not change the amplitude of a constant signal.');
end

function testTempsmoothIsTRAware(tc)
% The central fix. The same sigma in seconds must produce the same physical
% amount of smoothing at any TR. Smoothing a fast-sampled signal with sigma = 4 s
% and a slow-sampled one with sigma = 4 s should attenuate the same frequency
% content, so the ratio of output to input variance should be comparable.
T  = 400;
for TR = [1 2]
    tt  = (0:T-1) * TR;                        % seconds
    sig = sin(2*pi*0.05*tt);                   % 0.05 Hz, well inside the band
    sig = repmat(sig, 120, 1);                 % 120 voxels x 400 scans (T < 4V)
    out = fmri_tempsmooth(sig, 4, TR);
    att(TR == [1 2]) = std(out(1, 100:300)) / std(sig(1, 100:300)); %#ok<AGROW>
end
verifyEqual(tc, att(1), att(2), 'RelTol', 0.05, ...
    ['A 4 s kernel must attenuate a 0.05 Hz signal by the same amount at ' ...
     'TR = 1 s and TR = 2 s. If this fails, TR is not being respected.']);
end

function testTempsmoothRejectsBadInputs(tc)
data = tc.TestData.data;
verifyError(tc, @() fmri_tempsmooth(data, -1),    'fmri_tempsmooth:badSigma');
verifyError(tc, @() fmri_tempsmooth(data, 4, 0),  'fmri_tempsmooth:badTR');
end

% =========================================================================
% fmri_correctmovement
% =========================================================================
function testCorrectmovementMatchesLegacy(tc)
% Legacy took T x V; the rewrite takes canonical V x T. Same numbers.
data = tc.TestData.data;
rp   = tc.TestData.rp;

f = [tempname '.txt'];
save(f, 'rp', '-ascii');
c = onCleanup(@() delete(f));

ref = fmri_correctmovement_old(data.', f).';    % legacy wants T x V
new = fmri_correctmovement(data, f);            % canonical V x T

verifyEqual(tc, new, ref, 'AbsTol', 1e-9, ...
    'fmri_correctmovement differs from legacy.');
end

function testCorrectmovementRemovesMotionVariance(tc)
% Data built as pure motion should be almost entirely removed.
rp   = tc.TestData.rp;                           % 150 x 6
data = (zscore(rp) * randn(6, 200)).';           % 200 voxels x 150 scans, pure motion
out  = fmri_correctmovement(data, rp);
verifyLessThan(tc, max(abs(out(:))), 1e-8, ...
    'Data lying entirely in the motion subspace should be fully removed.');
end

function testCorrectmovementAcceptsMatrix(tc)
% A numeric matrix of regressors is accepted as well as a file path.
data = tc.TestData.data;
rp   = tc.TestData.rp;
f = [tempname '.txt'];
save(f, 'rp', '-ascii');
c = onCleanup(@() delete(f));
% save -ascii writes ~8 significant digits, so the file-loaded regressors differ
% from the in-memory ones at ~1e-8. The tolerance reflects that round-trip, not
% a difference in the regression itself.
verifyEqual(tc, fmri_correctmovement(data, rp), ...
                fmri_correctmovement(data, f), 'AbsTol', 1e-5);
end

function testCorrectmovementCatchesLengthMismatch(tc)
data = tc.TestData.data;                        % T = 150
bad  = randn(99, 6);                            % wrong number of scans
verifyError(tc, @() fmri_correctmovement(data, bad), ...
    'fmri_correctmovement:lengthMismatch');
end

% =========================================================================
% fmri_bandpassfilter
% =========================================================================
function testBandpassMatchesLegacy(tc)
data = tc.TestData.data;
ref = fmri_bandpassfilter_old(data.', 0.5, 0.01, 0.10).';   % legacy wants T x V
new = fmri_bandpassfilter(data, 0.5, 0.01, 0.10);           % canonical V x T
verifyEqual(tc, new, ref, 'AbsTol', 1e-9, ...
    'fmri_bandpassfilter differs from legacy.');
end

function testBandpassRemovesOutOfBand(tc)
% A pure 0.2 Hz tone should be almost eliminated by a 0.01-0.10 Hz passband,
% while a 0.05 Hz tone should survive.
TR = 2; fs = 1/TR; T = 300;
tt = (0:T-1) * TR;
inband  = repmat(sin(2*pi*0.05*tt), 100, 1);   % 100 voxels x 300 scans (T < 4V)
outband = repmat(sin(2*pi*0.20*tt), 100, 1);

keep = fmri_bandpassfilter(inband,  fs, 0.01, 0.10);
drop = fmri_bandpassfilter(outband, fs, 0.01, 0.10);

verifyGreaterThan(tc, std(keep(1,:)), 0.5 * std(inband(1,:)), ...
    'An in-band signal should survive the filter.');
verifyLessThan(tc, std(drop(1,:)), 1e-6, ...
    'An out-of-band signal should be removed.');
end

function testBandpassAcceptsSingleTimeSeries(tc)
% A bare regressor must be filterable with the same call, so that data and
% regressor can share a passband.
regr = randn(1, 150);
out  = fmri_bandpassfilter(regr, 0.5, 0.01, 0.10);
verifySize(tc, out, [1 150]);
verifyTrue(tc, isreal(out));
end

function testBandpassRejectsBadBand(tc)
data = tc.TestData.data;
verifyError(tc, @() fmri_bandpassfilter(data, 0.5, 0.10, 0.01), ...
    'fmri_bandpassfilter:badBand');
verifyError(tc, @() fmri_bandpassfilter(data, -1, 0.01, 0.10), ...
    'fmri_bandpassfilter:badFs');
end

% =========================================================================
% Edge cases -- these document actual behaviour, they do not impose a policy
% =========================================================================
function testDetrendConstantIsZero(tc)
% A constant signal has no drift and is mean-centred to zero.
data = ones(200, 150) * 7;
out  = fmri_detrend(data, 6);
verifyEqual(tc, out, zeros(200, 150), 'AbsTol', 1e-9, ...
    'Detrending a constant should give zero after mean-centring.');
end

function testTempsmoothConstantIsPreserved(tc)
% Smoothing a constant must return the same constant (unit-gain kernel).
data = ones(200, 150) * 7;
out  = fmri_tempsmooth(data, 4, 2);
verifyEqual(tc, out(:, 30:120), ones(200, 91) * 7, 'AbsTol', 1e-9, ...
    'Smoothing a constant must preserve it (away from the edges).');
end

function testZeroInputStaysZero(tc)
% All-zero input must not produce NaNs (e.g. from a divide in normalisation).
z = zeros(200, 150);
verifyEqual(tc, fmri_detrend(z, 6),      z, 'AbsTol', 1e-12);
verifyEqual(tc, fmri_tempsmooth(z, 4, 2), z, 'AbsTol', 1e-12);
verifyFalse(tc, any(isnan(fmri_detrend(z, 6)), 'all'));
verifyFalse(tc, any(isnan(fmri_tempsmooth(z, 4, 2)), 'all'));
end

function testSingleVoxelWorks(tc)
% V = 1 must be handled (a 1 x T row is a single voxel, not a bare regressor
% for the temporal functions -- it still has more than one "voxel"? no: it is
% one voxel across T scans).
data = randn(1, 150);
verifySize(tc, fmri_detrend(data, 6),      [1 150]);
verifySize(tc, fmri_tempsmooth(data, 4, 2), [1 150]);
end

function testNaNBehaviourIsDocumented(tc)
% NaN handling is not enforced, but it must be KNOWN. This test records the
% actual behaviour so that any future change to it is caught deliberately. The
% two functions differ, which is itself worth documenting:
%   - fmri_detrend calls MATLAB's spline(), which REJECTS non-finite control
%     points and errors (MATLAB:chckxy:NotEnoughPts). A loud failure is
%     arguably the safest behaviour: a NaN in the data stops the pipeline
%     rather than silently corrupting the fit.
%   - fmri_tempsmooth calls conv(), which PROPAGATES a NaN across the kernel
%     width but does not error.
% In both cases the operations are row-independent, so a NaN in one voxel can
% never leak into another.
data = randn(5, 150);
data(1, 75) = NaN;

% detrend: errors on NaN input (spline rejects it)
verifyError(tc, @() fmri_detrend(data, 6), 'MATLAB:chckxy:NotEnoughPts', ...
    'fmri_detrend should error on NaN input (spline rejects non-finite points).');

% tempsmooth: propagates NaN within the affected voxel, isolated from others
s = fmri_tempsmooth(data, 4, 2);
verifyGreaterThan(tc, nnz(isnan(s(1, :))), 1, ...
    'fmri_tempsmooth (conv) should spread NaN over the kernel width.');
verifyFalse(tc, any(isnan(s(2, :))), ...
    'fmri_tempsmooth must not leak NaN into other voxels.');
end

% =========================================================================
% Format round-trip -- validates the "same format in, same format out" claim
% =========================================================================
function testFormatRoundTripCanonical(tc)
% The orientation contract is checked through a public function rather than by
% calling fmri_asvoxtime directly: that helper is in core/private/ and is not
% reachable from a test file outside core/. Testing at the public boundary is
% also closer to what a user can actually observe - whatever layout goes in,
% the same layout comes back.
data = randn(20, 150);                       % voxels x time
tc.verifyEqual(size(fmri_detrend(data)), size(data));
end

function testFormatRoundTripVolume(tc)
% A 4D volume must round-trip back to a 4D volume of the same size. This uses
% fmri_vol2vect/fmri_vect2vol, which need the standard brain mask
% (standard_brain_NZ.mat) on the path; skip cleanly if it is absent.
if isempty(which('standard_brain_NZ.mat')) && exist('standard_brain_NZ', 'file') == 0
    assumeFail(tc, 'standard_brain_NZ.mat not on path; skipping volume round-trip.');
end
vol = randn(91, 109, 91, 4);
[norm_data, fmt] = fmri_asvoxtime(vol, 'test');
verifySize(tc, norm_data, [228453 4], ...
    'A 4D volume must vectorise to 228453 x T.');
restored = fmri_restoreformat(norm_data, fmt);
verifySize(tc, restored, [91 109 91 4], ...
    'A 4D volume must be restored to its original shape.');
end

function testFormatRoundTripLegacy(tc)
% Legacy T x 228453 input must be returned in the layout the caller supplied.
ws = warning('off', 'fmri:deprecatedOrientation');
c  = onCleanup(@() warning(ws));

data = randn(20, 228453);                       % legacy layout
[norm_data, fmt] = fmri_asvoxtime(data, 'test');
verifySize(tc, norm_data, [228453 20], ...
    'Legacy input must be transposed to canonical internally.');
restored = fmri_restoreformat(norm_data, fmt);
verifyEqual(tc, restored, data, 'AbsTol', 0, ...
    'Legacy input must be restored to the caller''s original layout.');
end

% =========================================================================
% The orientation contract -- the architectural claim, made testable
% =========================================================================
function testCanonicalOrientationNeedsNoTranspose(tc)
% This is the composability property the toolbox is built on: the output of
% any temporal function must be a valid input to any other, with no transposes
% anywhere in user code. If this test passes, the pipeline in the paper is
% literally what a user types.
data = tc.TestData.data;                       % V x T
rp   = tc.TestData.rp;

out = fmri_correctmovement(data, rp);
out = fmri_detrend(out, 6);
out = fmri_tempsmooth(out, 4, 2);
out = fmri_bandpassfilter(out, 0.5, 0.01, 0.10);

verifySize(tc, out, [tc.TestData.V, tc.TestData.T], ...
    'A composed pipeline must preserve the canonical layout.');
verifyTrue(tc, all(isfinite(out(:))), 'Pipeline produced non-finite values.');
end

function testLegacyTransposedInputStillWorks(tc)
% Backwards compatibility: T x 228453 input is accepted, auto-transposed, and
% returned in the layout the caller supplied. A deprecation warning is issued.
% (Uses a full-length vector so the helper recognises the legacy layout.)
NVOX = 228453;
T    = 20;
d    = randn(T, NVOX);                          % legacy layout

ws = warning('off', 'fmri:deprecatedOrientation');
c  = onCleanup(@() warning(ws));

out = fmri_detrend(d, 4);
verifySize(tc, out, [T NVOX], ...
    'Legacy transposed input must be returned in the same layout.');
end

function testAcceptsVoxelSubsets(tc)
% ROI-masked, downsampled and simulated data are legitimate inputs and must not
% be rejected merely for having fewer than 228453 voxels.
roi = randn(500, 40);                           % 500 voxels, 40 scans
out = fmri_detrend(roi, 4);
verifySize(tc, out, [500 40]);
end

function testSubsetsAssumedCanonicalNotTransposed(tc)
% Design contract: a voxel subset is ALWAYS read as voxels x time and is never
% silently transposed on a shape guess. So a 40 x 500 input is treated as 40
% voxels x 500 scans -- NOT transposed to 500 x 40 -- even though it has more
% columns than rows. (Full-brain data is the only case oriented automatically.)
ws = warning('off', 'fmri:ambiguousOrientation');
c  = onCleanup(@() warning(ws));

roi = randn(40, 500);                           % 40 voxels, 500 scans
out = fmri_detrend(roi, 4);
verifySize(tc, out, [40 500], ...
    'A subset must be kept as voxels x time, not transposed on a shape guess.');
end

function testRejectsNon2DInput(tc)
verifyError(tc, @() fmri_detrend(randn(5,5,5), 4), 'fmri:badInput');
end
