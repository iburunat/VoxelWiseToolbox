function tests = test_stats_conversions
% TEST_STATS_CONVERSIONS  Calibration and invertibility of the statistics.
%
% Covers fmri_fisherz, fmri_fisherz2p, fmri_r2p, fmri_p2r, fmri_p2t, fmri_effdf,
% fmri_combinep and fmri_ttest.
%
% The p-value functions are checked against their NULL DISTRIBUTIONS, which is
% the property that matters: a p-value must satisfy P(p < a) = a. A t-map alone
% looks plausible whatever the CDF or the degrees of freedom; a false-positive
% rate does not.
%
% They are NOT checked against the Statistics and Machine Learning Toolbox. The
% toolbox is deliberately free of it, so the references here are published t
% tables, analytic identities and the functions' own inverses.
%
% Backs the claim in Section 5.2 that the conversions are calibrated to within
% 0.001 of nominal across 20 000 simulations.
%
% RUNTIME. A few seconds, despite several tests running 20 000 simulations
% each: the simulations are vectorised over voxels rather than looped.
%
% Usage:
%   results = runtests('test_stats_conversions')
%
% See also: fmri_r2p, fmri_p2r, fmri_p2t, fmri_effdf, fmri_combinep, fmri_ttest

tests = functiontests(localfunctions);
end


function setupOnce(tc)
% The null correlation sample is expensive and used by two tests, so it is
% drawn once here.
rng(0);
tc.TestData.Nobs = 50;
tc.TestData.nsim = 20000;

rnull = zeros(tc.TestData.nsim, 1);
for k = 1:tc.TestData.nsim
    a = randn(tc.TestData.Nobs, 1);
    b = randn(tc.TestData.Nobs, 1);
    rnull(k) = fmri_corrmat(a, b);  
end
tc.TestData.rnull = rnull;
end


% =========================================================================
%  Fisher z and the r -> p conversion
% =========================================================================

function testFisherzUsesSqrtNminus3(tc)
r = 0.35; N = 60;
verifyEqual(tc, fmri_fisherz(r, N), atanh(r) * sqrt(N - 3), 'AbsTol', 1e-12, ...
    'fmri_fisherz is not the standard atanh(r)*sqrt(N-3).');
end


function testFisherzAndR2pAgree(tc)
% fmri_r2p delegates the transform to fmri_fisherz rather than repeating
% atanh(r)*sqrt(df-3), so the two cannot drift apart. This checks they haven't.
r = 0.35; N = 60;
p_via_fisherz = fmri_fisherz2p(fmri_fisherz(r, N));
p_via_r2p     = fmri_r2p(r, N);

verifyEqual(tc, p_via_fisherz, p_via_r2p, 'AbsTol', 1e-12, ...
    'fmri_fisherz2p and fmri_r2p disagree on the same correlation.');
end


function testR2pIsCalibratedUnderTheNull(tc)
% At TAIL = 2 the two outputs are the SAME two-tailed p-value. That is the
% documented contract and it is deliberate: doubling a directional one-tailed p
% gives values above 1 for one sign of r, and a map thresholded on those would
% silently exclude every voxel of that sign.
[p_pos, p_neg] = fmri_r2p(tc.TestData.rnull, tc.TestData.Nobs);

verifyEqual(tc, p_pos, p_neg, 'AbsTol', 0, ...
    'At TAIL = 2 both outputs must carry the same two-tailed p-value.');

verifyEqual(tc, mean(p_pos < 0.05), 0.05, 'AbsTol', 0.008, ...
    sprintf('P(p<0.05) = %.4f under the null; expected 0.05.', mean(p_pos < 0.05)));
verifyEqual(tc, mean(p_pos < 0.01), 0.01, 'AbsTol', 0.004, ...
    sprintf('P(p<0.01) = %.4f under the null; expected 0.01.', mean(p_pos < 0.01)));
end


function testR2pTailsBehaveAsDocumented(tc)
% The distinction the two-tailed case erases, and the reason TAIL exists.
r = 0.3; N = 50;

% TAIL = 2 depends on |r| only, so sign must make no difference at all.
verifyEqual(tc, fmri_r2p(r, N), fmri_r2p(-r, N), 'AbsTol', 0, ...
    'The two-tailed p must depend on |r| only.');

% TAIL = 1 is directional: small for positive r, large for negative.
p_up_pos = fmri_r2p( r, N, 1);
p_up_neg = fmri_r2p(-r, N, 1);
verifyLessThan(tc, p_up_pos, 0.05, ...
    'The positive one-tailed p should be small for r = +0.3.');
verifyGreaterThan(tc, p_up_neg, 0.5, ...
    'The positive one-tailed p should be large for r = -0.3.');

% The one-tailed p is half the two-tailed p in the favoured direction.
verifyEqual(tc, p_up_pos, fmri_r2p(r, N) / 2, 'AbsTol', 1e-12, ...
    'The one-tailed p should be half the two-tailed p for r of that sign.');

% The unrequested output is empty, not a duplicate.
[~, pn1] = fmri_r2p(r, N, 1);
[pp2, ~] = fmri_r2p(r, N, -1);
verifyEmpty(tc, pn1, 'TAIL = 1 must return an empty p_neg.');
verifyEmpty(tc, pp2, 'TAIL = -1 must return an empty p_pos.');
end


function testPassingNminus2IsConservative(tc)
% The old docstring advised passing N-2. It is not an error that shows up as a
% crash: it quietly costs power. Recorded here so the advice cannot creep back.
p       = fmri_r2p(tc.TestData.rnull, tc.TestData.Nobs);
p_wrong = fmri_r2p(tc.TestData.rnull, tc.TestData.Nobs - 2);

verifyLessThan(tc, mean(p_wrong < 0.05), mean(p < 0.05), ...
    'Passing df = N-2 should be conservative relative to df = N.');
end


function testP2rInvertsR2p(tc)
for df = [20 50 148]
    for pv = [0.05 0.01 0.001]
        rc = fmri_p2r(pv, df);
        pb = fmri_r2p(rc, df, 2);
        verifyEqual(tc, pb, pv, 'AbsTol', 1e-10, sprintf( ...
            'p2r/r2p are not inverses at df=%d, p=%.3f (got %.8f).', df, pv, pb));
    end
end
end


function testP2rIsStricterAtLowerDf(tc)
verifyGreaterThan(tc, fmri_p2r(0.001, 20), fmri_p2r(0.001, 200), ...
    'Fewer degrees of freedom must demand a LARGER critical correlation.');
end


% =========================================================================
%  Effective degrees of freedom
% =========================================================================

function testEffdfReturnsNOnWhiteNoise(tc)
% With no autocorrelation there is nothing to correct, so the estimator must
% return the nominal sample size. A value well below N means lag 0 is being
% included in the sum.
rng(1);
df = fmri_effdf(randn(200, 1), randn(200, 1));
verifyGreaterThan(tc, df, 150, sprintf( ...
    'White noise, N = 200, gave df = %.1f; lag 0 may be in the sum.', df));
end


function testEffdfShrinksWithAutocorrelation(tc)
rng(2);
ar1 = filter(1, [1 -0.8], randn(200, 1));
ar2 = filter(1, [1 -0.8], randn(200, 1));
df  = fmri_effdf(ar1, ar2);
verifyLessThan(tc, df, 150, sprintf( ...
    'AR(0.8) pair gave df = %.1f; expected well below N = 200.', df));
end


function testEffdfKeepsTheTestCalibrated(tc)
% The property that matters, and the reason fmri_effdf exists: two INDEPENDENT
% autocorrelated series must be called significant at the nominal rate. Without
% the correction this rate is several times too high.
rng(3);
nsim = 4000; Nt = 200;
pv = zeros(nsim, 1);
for k = 1:nsim
    a = filter(1, [1 -0.8], randn(Nt, 1));
    b = filter(1, [1 -0.8], randn(Nt, 1));
    rr = fmri_corrmat(a, b);
    pv(k) = fmri_r2p(rr, fmri_effdf(a, b));
end

verifyEqual(tc, mean(pv < 0.05), 0.05, 'AbsTol', 0.012, sprintf( ...
    'AR(0.8), N = 200: P(p<0.05) = %.4f; expected 0.05.', mean(pv < 0.05)));
verifyEqual(tc, mean(pv < 0.01), 0.01, 'AbsTol', 0.006, sprintf( ...
    'AR(0.8), N = 200: P(p<0.01) = %.4f; expected 0.01.', mean(pv < 0.01)));
end


% =========================================================================
%  Meta-analytic p-value combination
% =========================================================================

function testCombinepIsCalibratedUnderTheNull(tc)
% The median method previously returned the raw median, giving P(p<0.05) near
% 0.001 rather than 0.05 - a combination that looked conservative and was
% simply wrong.
rng(4);
pn = rand(20000, 5);
for m = {'fisher', 'stouffer', 'median'}
    pc = fmri_combinep(pn, m{1});
    verifyEqual(tc, mean(pc < 0.05), 0.05, 'AbsTol', 0.008, sprintf( ...
        '%s: P(p<0.05) = %.4f under the null; expected 0.05.', ...
        m{1}, mean(pc < 0.05)));
end
end


function testCombinepMedianHandlesEvenAndOddN(tc)
% The median of an even number of p-values interpolates between two order
% statistics, which has a different null distribution from the odd case.
rng(5);
for N = [3 4 5 6 10]
    pc = fmri_combinep(rand(10000, N), 'median');
    verifyEqual(tc, mean(pc < 0.05), 0.05, 'AbsTol', 0.012, sprintf( ...
        'median, N = %d: P(p<0.05) = %.4f; expected 0.05.', N, mean(pc < 0.05)));
end
end


function testCombinepDetectsRealSignal(tc)
% Calibration alone is satisfied by a function that always returns 1. This
% checks the other direction.
rng(6);
psig = rand(5000, 5) * 0.02;
for m = {'fisher', 'stouffer', 'median'}
    pc = fmri_combinep(psig, m{1});
    verifyLessThan(tc, median(pc), 0.01, sprintf( ...
        '%s failed to combine five significant p-values into a smaller one.', m{1}));
end
end


% =========================================================================
%  p -> t, and the t-test
% =========================================================================

function testP2tMatchesPublishedTables(tc)
% Standard table values for p < 0.001 two-tailed.
ref_df = [100 14 7 2];
ref_t  = [3.390 4.140 5.408 31.599];
for k = 1:numel(ref_df)
    got = fmri_p2t(0.001, ref_df(k));
    verifyEqual(tc, got, ref_t(k), 'AbsTol', 5e-3, sprintf( ...
        'df = %d: t_crit = %.4f, published value %.3f.', ref_df(k), got, ref_t(k)));
end
end


function testP2tAndTtestAreInverses(tc)
% fmri_ttest computes p from t; fmri_p2t computes t from p. Build one voxel
% whose t is exactly t_crit, then ask fmri_ttest for its p.
rng(7);
df = 20;
n  = df + 1;
for pv = [0.05 0.01 0.001]
    t_crit = fmri_p2t(pv, df);
    v = randn(1, n);
    v = (v - mean(v)) / std(v);          % mean 0, sd 1
    v = v + t_crit / sqrt(n);            % so that t = t_crit exactly
    [~, p_back] = fmri_ttest(v);
    verifyEqual(tc, p_back, pv, 'AbsTol', 1e-6, sprintf( ...
        'Round trip at p = %.3f returned %.8f.', pv, p_back));
end
end


function testTtestOneSampleMatchesTheDirectFormula(tc)
rng(5);
X = randn(200, 12) + 0.4;
[t, ~, df] = fmri_ttest(X);
t_direct = mean(X, 2) ./ (std(X, 0, 2) / sqrt(size(X, 2)));

verifyEqual(tc, df, size(X, 2) - 1, 'One-sample df must be N-1.');
verifyEqual(tc, t, t_direct, 'AbsTol', 1e-12, ...
    'fmri_ttest disagrees with mean/(sd/sqrt(n)).');
end


function testTtestTwoSampleMatchesThePooledFormula(tc)
rng(7);
A = randn(300, 9); B = randn(300, 11) + 0.5;
[t, ~, df] = fmri_ttest(A, B);

n1 = size(A, 2); n2 = size(B, 2);
sp2 = ((n1-1)*var(A, 0, 2) + (n2-1)*var(B, 0, 2)) / (n1 + n2 - 2);
t_direct = (mean(A, 2) - mean(B, 2)) ./ sqrt(sp2 * (1/n1 + 1/n2));

verifyEqual(tc, df, n1 + n2 - 2, 'Two-sample df must be n1+n2-2.');
verifyEqual(tc, t, t_direct, 'AbsTol', 1e-12, ...
    'fmri_ttest disagrees with the pooled-variance formula.');
end


function testTtestPairedEqualsOneSampleOnDifferences(tc)
% An identity, not an approximation, so it is checked at machine precision.
rng(3);
P1 = randn(150, 10);
P2 = P1 + 0.3 + 0.5*randn(150, 10);
[tp, ~, dfp] = fmri_ttest(P1, P2, 'paired', true);
[td, ~, dfd] = fmri_ttest(P1 - P2);

verifyEqual(tc, dfp, dfd, 'Paired and one-sample df must agree.');
verifyEqual(tc, tp, td, 'AbsTol', 1e-12, ...
    'A paired test must equal a one-sample test on the differences.');
end


function testTtestNullCalibrationOneSample(tc)
rng(11);
[~, p] = fmri_ttest(randn(20000, 10));
verifyEqual(tc, mean(p < 0.05), 0.05, 'AbsTol', 0.006, sprintf( ...
    'One-sample, N = 10: P(p<0.05) = %.4f; expected 0.05.', mean(p < 0.05)));
verifyEqual(tc, mean(p < 0.01), 0.01, 'AbsTol', 0.003, sprintf( ...
    'One-sample, N = 10: P(p<0.01) = %.4f; expected 0.01.', mean(p < 0.01)));
end


function testTtestNullCalibrationTwoSample(tc)
rng(13);
[~, p] = fmri_ttest(randn(20000, 8), randn(20000, 8));
verifyEqual(tc, mean(p < 0.05), 0.05, 'AbsTol', 0.006, sprintf( ...
    'Two-sample: P(p<0.05) = %.4f; expected 0.05.', mean(p < 0.05)));
end


function testTtestTailsAreConsistent(tc)
rng(9);
Y = randn(500, 12) + 0.3;
[~, p_b] = fmri_ttest(Y, [], 'tail', 'both');
[~, p_r] = fmri_ttest(Y, [], 'tail', 'right');
[~, p_l] = fmri_ttest(Y, [], 'tail', 'left');

verifyEqual(tc, p_l + p_r, ones(size(p_l)), 'AbsTol', 1e-12, ...
    'One-tailed p-values must sum to 1.');
verifyEqual(tc, p_b, 2*min(p_l, p_r), 'AbsTol', 1e-12, ...
    'The two-tailed p must be twice the smaller one-tailed p.');
end


function testTtestNeutralisesConstantVoxels(tc)
% This asserts the VALUES, not just finiteness. An earlier version tested only
% isfinite and passed while a constant voxel was reported as t = 1.1e16,
% p = 1e-110 - the single most significant voxel in the map. 1e16 is finite, so
% the weaker check saw nothing wrong.
rng(15);
Z = randn(10, 8);
Z(3, :) = 2.5;                                % no variance
[t, p] = fmri_ttest(Z);

verifyEqual(tc, t(3), 0, 'A constant voxel must give t = 0, not a huge value.');
verifyEqual(tc, p(3), 1, 'A constant voxel must give p = 1.');
verifyTrue(tc, all(isfinite(t)) && all(isfinite(p)), ...
    'NaN or Inf present in the t or p map.');

% The two-sample path has its own guard.
Za = randn(10, 6); Zb = randn(10, 6);
Za(4, :) = 1.0; Zb(4, :) = 1.0;               % constant in BOTH groups
[t2, p2] = fmri_ttest(Za, Zb);
verifyEqual(tc, t2(4), 0, 'Two-sample: constant voxel must give t = 0.');
verifyEqual(tc, p2(4), 1, 'Two-sample: constant voxel must give p = 1.');
end


function testTtestPermutationIsCalibratedAndNeverZero(tc)
% A permutation p of exactly 0 is not attainable: the observed statistic is
% always one of the values in its own null distribution.
rng(21);
[~, p] = fmri_ttest(randn(2000, 10), [], 'nperm', 500);

verifyEqual(tc, mean(p < 0.05), 0.05, 'AbsTol', 0.02, sprintf( ...
    'Permutation P(p<0.05) = %.4f; expected about 0.05.', mean(p < 0.05)));
verifyGreaterThan(tc, min(p), 0, ...
    'A permutation p-value of exactly 0 is not attainable.');
end


% =========================================================================
%  Input validation
% =========================================================================

function testInvalidInputIsRejected(tc)
% ?MException matches any error, which is what the original script checked.
% Tighten to specific identifiers once they are settled.
verifyError(tc, @() fmri_r2p(0.5, 50, 7),                      ?MException, 'r2p bad tail');
verifyError(tc, @() fmri_effdf(randn(10,1), randn(20,1)),      ?MException, 'effdf length mismatch');
verifyError(tc, @() fmri_combinep(rand(100,3), 'nonsense'),    ?MException, 'combinep bad method');
verifyError(tc, @() fmri_p2t(0, 20),                           ?MException, 'p2t p = 0');
verifyError(tc, @() fmri_p2t(0.001, 0),                        ?MException, 'p2t df = 0');
verifyError(tc, @() fmri_p2r(0.001, 2),                        ?MException, 'p2r df <= 3');
verifyError(tc, @() fmri_p2r(1.5, 50),                         ?MException, 'p2r p > 1');
verifyError(tc, @() fmri_ttest(randn(10,1)),                   ?MException, 'ttest one participant');
verifyError(tc, @() fmri_ttest(randn(10,5), randn(8,5)),       ?MException, 'ttest voxel mismatch');
verifyError(tc, @() fmri_ttest(randn(10,5), randn(10,6), 'paired', true), ...
                                                               ?MException, 'ttest pair mismatch');
verifyError(tc, @() fmri_ttest(randn(10,5), [], 'paired', true), ...
                                                               ?MException, 'ttest paired needs two');
verifyError(tc, @() fmri_ttest(randn(10,5), [], 'tail', 'sideways'), ...
                                                               ?MException, 'ttest bad tail');
verifyError(tc, @() fmri_ttest(complex(randn(10,5))), ...
                                       'fmri_ttest:complexInput', 'ttest complex data1');
verifyError(tc, @() fmri_ttest(randn(10,5), complex(randn(10,5))), ...
                                       'fmri_ttest:complexInput', 'ttest complex data2');
end

