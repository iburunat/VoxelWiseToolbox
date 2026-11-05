function tests = test_bwlabel3d
% TEST_BWLABEL3D  Unit tests for fmri_bwlabel3d.
%
% Validates the pure MATLAB connected-component labelling that replaced SPM's
% compiled spm_bwlabel. Run with:
%
%   results = runtests('test_bwlabel3d')
%
% The comparison against spm_bwlabel is skipped automatically if SPM is not on
% the path, so the suite passes on a clean, SPM-free installation. When SPM is
% available, the two implementations are required to agree exactly, including
% label ordering.
%
% See also: fmri_bwlabel3d, fmri_bwlabel

tests = functiontests(localfunctions);
end

% -------------------------------------------------------------------------
function testEmptyVolume(tc)
[L, num] = fmri_bwlabel3d(false(10, 10, 10), 18);
verifyEqual(tc, num, 0);
verifyEqual(tc, nnz(L), 0);
verifySize(tc, L, [10 10 10]);
end

% -------------------------------------------------------------------------
function testSingleVoxel(tc)
BW = false(10, 10, 10);
BW(5, 5, 5) = true;
for conn = [6 18 26]
    [L, num] = fmri_bwlabel3d(BW, conn);
    verifyEqual(tc, num, 1);
    verifyEqual(tc, L(5, 5, 5), 1);
    verifyEqual(tc, nnz(L), 1);
end
end

% -------------------------------------------------------------------------
function testConnectivityDistinguishes(tc)
% Two voxels touching only at a corner: one cluster under 26-connectivity,
% two clusters under 18- and 6-connectivity. This is the case that fails if
% the neighbour offsets are wrong.
BW = false(5, 5, 5);
BW(2, 2, 2) = true;
BW(3, 3, 3) = true;                      % corner-adjacent
[~, n6]  = fmri_bwlabel3d(BW, 6);
[~, n18] = fmri_bwlabel3d(BW, 18);
[~, n26] = fmri_bwlabel3d(BW, 26);
verifyEqual(tc, n6,  2);
verifyEqual(tc, n18, 2);
verifyEqual(tc, n26, 1);

% Two voxels touching along an edge: joined by 18 and 26, split by 6.
BW = false(5, 5, 5);
BW(2, 2, 2) = true;
BW(3, 3, 2) = true;                      % edge-adjacent
[~, n6]  = fmri_bwlabel3d(BW, 6);
[~, n18] = fmri_bwlabel3d(BW, 18);
[~, n26] = fmri_bwlabel3d(BW, 26);
verifyEqual(tc, n6,  2);
verifyEqual(tc, n18, 1);
verifyEqual(tc, n26, 1);
end

% -------------------------------------------------------------------------
function testLabelsAreContiguousAndScanOrdered(tc)
rng(0);
BW = rand(20, 22, 18) < 0.15;
[L, num] = fmri_bwlabel3d(BW, 18);

% labels form exactly 1..num, with no gaps
verifyEqual(tc, sort(unique(L(L > 0)))', 1:num);

% background is preserved exactly
verifyEqual(tc, L > 0, BW);

% spm_bwlabel convention: cluster k's first voxel (column-major scan order)
% precedes cluster k+1's first voxel
firsts = zeros(num, 1);
for k = 1:num
    firsts(k) = find(L(:) == k, 1, 'first');
end
verifyEqual(tc, firsts, sort(firsts), ...
    'Labels are not ordered by first voxel in scan order.');
end

% -------------------------------------------------------------------------
function testClusterSizesSumToForeground(tc)
rng(1);
BW = rand(20, 22, 18) < 0.2;
for conn = [6 18 26]
    [L, num] = fmri_bwlabel3d(BW, conn);
    sizes = accumarray(L(L > 0), 1);
    verifyEqual(tc, numel(sizes), num);
    verifyEqual(tc, sum(sizes), nnz(BW));
end
end

% -------------------------------------------------------------------------
function testAcceptsLogicalAndDouble(tc)
% spm_bwlabel errors on logical input; fmri_bwlabel3d must not.
rng(2);
BW = rand(12, 12, 12) < 0.2;
[L1, n1] = fmri_bwlabel3d(BW, 18);            % logical
[L2, n2] = fmri_bwlabel3d(double(BW), 18);    % double
verifyEqual(tc, n1, n2);
verifyEqual(tc, L1, L2);
verifyClass(tc, L1, 'double');
end

% -------------------------------------------------------------------------
function testRejectsBadConnectivity(tc)
verifyError(tc, @() fmri_bwlabel3d(true(5,5,5), 7),  'fmri_bwlabel3d:badConn');
verifyError(tc, @() fmri_bwlabel3d(true(5,5,5), 26.5), 'fmri_bwlabel3d:badConn');
end

% -------------------------------------------------------------------------
function testMatchesSpmBwlabel(tc)
% The reference test: exact agreement with the compiled implementation this
% function replaces. Skipped when SPM is absent.
if ~exist('spm_bwlabel', 'file')
    assumeFail(tc, 'SPM not on path; skipping spm_bwlabel comparison.');
end

rng(3);
for conn = [6 18 26]
    for trial = 1:5
        BW = rand(30, 32, 28) < (0.05 * trial);

        [Lspm, nspm] = spm_bwlabel(double(BW), conn);
        [Lnew, nnew] = fmri_bwlabel3d(BW, conn);

        verifyEqual(tc, nnew, nspm, ...
            sprintf('Cluster count differs (conn=%d, trial=%d).', conn, trial));

        % Require identical labelling, not merely an equivalent partition.
        % fmri_bwlabel3d reproduces spm_bwlabel's label ordering, so the two
        % label volumes should be element-wise identical.
        verifyEqual(tc, Lnew, Lspm, ...
            sprintf('Labelling differs (conn=%d, trial=%d).', conn, trial));
    end
end
end

% -------------------------------------------------------------------------
function testRealisticBrainMapPerformance(tc)
% A realistic thresholded map: confirms the vectorised implementation stays
% fast on the largest input the toolbox generates (the low-threshold maps
% inside fmri_csdist's permutation loop).
if exist('standard_brain_NZ.mat', 'file')
    S    = load('standard_brain_NZ.mat');
    mask = S.A > 0;
else
    mask = true(91, 109, 91);
end

rng(4);
vol = smooth3(randn(91, 109, 91), 'gaussian', 5, 2);
vol = (vol - mean(vol(:))) ./ std(vol(:));

t0 = tic;
[~, num] = fmri_bwlabel3d((abs(vol) > 1.5) & mask, 18);   % worst case: large foreground
elapsed  = toc(t0);

verifyGreaterThan(tc, num, 0);
verifyLessThan(tc, elapsed, 5, ...
    'fmri_bwlabel3d took over 5 s on a worst-case map; check vectorisation.');
fprintf('    [perf] worst-case map: %d clusters in %.3f s\n', num, elapsed);
end
