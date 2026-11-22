function tests = test_temporal
% TEST_TEMPORAL  Unit tests for the temporal preprocessing module.
%
% Verifies fmri_detrend, fmri_tempsmooth, fmri_correctmovement and
% fmri_bandpassfilter: their documented properties, their error handling, and
% the orientation contract.
%
% Run with:
%   results = runtests('test_temporal')

tests = functiontests(localfunctions);
end

% =========================================================================
% Setup
% =========================================================================
function setupOnce(tc)
% Small synthetic dataset: drift + signal + noise, voxels x time.
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

% Locate the toolbox root from this file. 
here = fileparts(mfilename('fullpath'));
root = fileparts(here);                  % tests/ -> toolbox root
addpath(root);
assumeTrue(tc, ~isempty(which('fmri_detrend')), ...
    'Toolbox not on the path; run fmritoolbox_setup before this suite.');
end

% =========================================================================
% fmri_detrend
% =========================================================================
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
% Detrending should strongly reduce slow drift but need not remove it exactly,
% particularly near the run boundaries. Test the reduction in variance and
% the interior residual, instead of requiring an all-zero result.
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
function testTempsmoothUnitGain(tc)
% A constant signal must survive smoothing unchanged. An earlier unnormalised
% kernel scaled the data by ~0.5, which is what this test guards against.
const = ones(300, 200) * 7;                % 300 voxels x 200 scans (V > T)
out   = fmri_tempsmooth(const, 4, 2);
mid   = out(:, 50:150);                    % away from the edges
verifyEqual(tc, mid, ones(300, 101) * 7, 'AbsTol', 1e-9, ...
    'Smoothing must not change the amplitude of a constant signal.');
end

function testTempsmoothIsTRAware(tc)
% The same SIGMA in seconds should produce comparable smoothing at different
% TRs. Verify this by comparing signal attenuation at TR = 1 s and TR = 2 s.
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
function testCorrectmovementRemovesMotionVariance(tc)
% Data built as pure motion should be almost entirely removed.
rp   = tc.TestData.rp;                           % 150 x 6
data = (((rp - mean(rp)) ./ std(rp)) * randn(6, 200)).'; % 200 voxels x 150 scans, pure motion
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
% V = 1 must be handled: a 1 x T row is one voxel across T scans.
ws   = warning('off', 'fmri:ambiguousOrientation');
c    = onCleanup(@() warning(ws));
data = randn(1, 150);
verifySize(tc, fmri_detrend(data, 6),       [1 150]);
verifySize(tc, fmri_tempsmooth(data, 4, 2), [1 150]);
end

function testNaNBehaviourIsDocumented(tc)
% Record the current NaN behaviour: fmri_detrend returns an error, while
% fmri_tempsmooth propagates NaNs within the affected voxel. Neither operation
% allows NaNs to spread between voxels.
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
% A 4D volume is vectorised internally and restored to its original size.
% Checked through fmri_detrend rather than fmri_asvoxtime, which is private
% to core/ and not reachable from here.
if isempty(which('standard_brain_NZ.mat'))
    assumeFail(tc, 'standard_brain_NZ.mat not on path; skipping volume round-trip.');
end

vol = randn(91, 109, 91, 4);
verifySize(tc, fmri_detrend(vol, 4), [91 109 91 4], ...
    'A 4D volume must come back in its original shape.');
end


% =========================================================================
% The orientation contract -- the architectural claim, made testable
% =========================================================================
function testCanonicalOrientationNeedsNoTranspose(tc)
% Verify that temporal functions can be chained directly while preserving
% the canonical voxels-by-time layout.
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
% Voxel subsets are treated as voxels x time and not transposed on a shape
% guess; only full-brain data is oriented automatically. The accompanying
% fmri:ambiguousOrientation notice is not asserted here: fmri_asvoxtime issues
% it once per session, so whether it is still available depends on which tests
% ran first.
ws  = warning('off', 'fmri:ambiguousOrientation');
c   = onCleanup(@() warning(ws));
roi = randn(40, 500);                           % 40 voxels, 500 scans
out = fmri_detrend(roi, 4);
verifySize(tc, out, [40 500], ...
    'A subset must be kept as voxels x time, not transposed on a shape guess.');
end

function testRejectsNon2DInput(tc)
verifyError(tc, @() fmri_detrend(randn(5,5,5), 4), 'fmri:badInput');
end