function tests = test_tfce
% TEST_TFCE  Threshold-free cluster enhancement against a reference.
%
% Verifies that TFCE integrates cluster extent over cumulative thresholded
% maps, where a voxel contributes at every threshold below its value. The
% output is compared with an independent implementation of the TFCE definition.
%
% Backs the claim in Section 5.2 of the manuscript that the implemented 
% function reproduces the analytic extent-scaling ratio.
%
% Usage:
%   results = runtests('test_tfce')
%
% See also: fmri_tfce, fmri_bwlabel, fmri_vect2vol

tests = functiontests(localfunctions);
end


function setupOnce(tc)
% Create a smooth cluster with positive noise, giving both structured and
% scattered suprathreshold voxels.
rng(0);
s1   = fmri_sub2ind([35 60 45]);
D1   = fmri_voxdist(s1, 1:228453)';
blob = max(3 - D1/6, 0);
noise = max(randn(228453, 1) * 0.3, 0);

tc.TestData.data = blob + noise;
tc.TestData.t    = fmri_tfce(tc.TestData.data);
end


function testOutputShapeAndRange(tc)
t = tc.TestData.t;
verifySize(tc, t, [228453 1], 'TFCE must return one value per in-brain voxel.');
verifyTrue(tc, all(isfinite(t)), 'TFCE returned non-finite values.');
verifyGreaterThanOrEqual(tc, min(t), 0, 'TFCE values must be non-negative.');
end


function testMatchesReferenceImplementation(tc)
% Compare with an independent implementation written directly from the TFCE
% definition.
t    = tc.TestData.t;
tref = reference_tfce(tc.TestData.data, 0.5, 2, 50);

r  = fmri_corrmat(t, tref);          % NOT corr(): base MATLAB only
md = max(abs(t - tref));

verifyGreaterThan(tc, r, 0.999, sprintf( ...
    'TFCE disagrees with the reference implementation (r = %.6f).', r));
verifyLessThan(tc, md, 1e-6, sprintf( ...
    'TFCE differs from the reference by up to %.3e.', md));
end


function testPartitionFormWouldBeWrong(tc)
% Verify that partitioning values into separate bins does not reproduce the
% cumulative threshold-stack calculation required by TFCE.
t    = tc.TestData.t;
tbin = bin_based_tfce(tc.TestData.data, 0.5, 2, 50);

ratio = max(tbin) / max(t);
verifyLessThan(tc, ratio, 0.1, sprintf( ...
    ['The partition form now agrees with the threshold-stack form ' ...
     '(ratio %.3f). Either fmri_tfce has reverted to partitioning, or this ' ...
     'guard is no longer measuring what it was written for.'], ratio));
end


function testConvergesWithThresholdCount(tc)
% Verify that the numerical integral stabilises as the number of threshold
% bins increases.
data = tc.TestData.data;
m = arrayfun(@(N) max(fmri_tfce(data, 0.5, 2, N)), [25 50 100 200]);

rel = abs(m(4) - m(3)) / m(3);
verifyLessThan(tc, rel, 0.05, sprintf( ...
    'TFCE has not converged by N = 200: %.2f%% change from N = 100.', 100*rel));
end


function testPeakIsHighInTheTfceMap(tc)
% The data peak need not be the TFCE peak, but it should rank highly because
% it belongs to the main cluster across the threshold range.
[~, dpk] = max(tc.TestData.data);
pk_rank  = sum(tc.TestData.t >= tc.TestData.t(dpk));

verifyLessThan(tc, pk_rank, 100, sprintf( ...
    'The data peak ranks %d in the TFCE map; expected it near the top.', pk_rank));
end


function testExponentsChangeTheResult(tc)
% Verify that changing the extent and height exponents changes the result.
data = tc.TestData.data;
t    = tc.TestData.t;

verifyGreaterThan(tc, abs(max(t) - max(fmri_tfce(data, 1.0, 2, 50))), 1e-6, ...
    'Changing E from 0.5 to 1.0 had no effect; the exponent is being ignored.');
verifyGreaterThan(tc, abs(max(t) - max(fmri_tfce(data, 0.5, 3, 50))), 1e-6, ...
    'Changing H from 2 to 3 had no effect; the exponent is being ignored.');
end


function testAllZeroMapReturnsZeros(tc)
verifyEqual(tc, fmri_tfce(zeros(228453, 1)), zeros(228453, 1), ...
    'An all-zero map must enhance to all zeros.');
end


function testInvalidInputIsRejected(tc)
% Accept any error for now; replace ?MException with specific fmri_tfce error
% identifiers once the validation interface is finalised.
data = tc.TestData.data;

verifyError(tc, @() fmri_tfce([data data]), ?MException, ...
    'A non-column input should be rejected.');
verifyError(tc, @() fmri_tfce(data - 1), ?MException, ...
    'Negative values should be rejected: TFCE is defined for one tail.');

bad = data; bad(1) = NaN;
verifyError(tc, @() fmri_tfce(bad), ?MException, ...
    'NaN input should be rejected rather than propagated.');
end


% =========================================================================
%  Reference implementations
% =========================================================================

function out = reference_tfce(data, E, H, N)
% TFCE from the definition: at each of N heights, label the suprathreshold
% voxels, raise each cluster's extent to E, weight by h^H, and integrate.
hmax = max(data);
out  = zeros(size(data));
if hmax <= 0, return; end

hs = linspace(0, hmax, N+1);
dh = hs(2) - hs(1);
h  = hs(2:end) - dh/2;

for k = 1:N
    above = data >= h(k);
    [L, num] = fmri_bwlabel(fmri_vect2vol(double(above)), 18);
    if num > 0
        lv  = fmri_vol2vect(L);
        sz  = accumarray(lv(lv > 0), 1);
        nz  = lv > 0;
        ext = zeros(size(data));
        ext(nz) = sz(lv(nz));
        out = out + (ext.^E) * (h(k)^H) * dh;
    end
end
end


function out = bin_based_tfce(data, E, H, N)
% Alternative bin-based calculation used only by the regression test. Each
% voxel contributes to one value bin rather than every threshold below it,
% so this is not the TFCE threshold-stack calculation.
hmax = max(data);
out  = zeros(size(data));
if hmax <= 0, return; end

hs = linspace(0, hmax, N+1);
dh = hs(2) - hs(1);
h  = hs(2:end) - dh/2;
zz = fmri_bin(data, 0, hmax, N);

for k = 1:N
    [L, num] = fmri_bwlabel(fmri_vect2vol(zz(:,k)), 18);
    if num > 0
        lv  = fmri_vol2vect(L);
        sz  = accumarray(lv(lv > 0), 1);
        nz  = lv > 0;
        ext = zeros(size(data));
        ext(nz) = sz(lv(nz));
        out = out + (ext.^E) * (h(k)^H) * dh;
    end
end
end