function tests = test_regiontable
% TEST_REGIONTABLE  Unit tests for fmri_regiontable.
%
% All outputs must use the same filtered cluster order: CLUST(k) corresponds
% to Cluster k in S and T, and to ROI{k}, LIST{k}, ROI_IDX{k} and CLUS(:,k).
%
% The fixture interleaves left- and right-hemisphere clusters by size, ensuring
% the tests detect any mismatch between global size order and the left-then-right
% order used for reporting.
%
% Run with:
%   results = runtests('test_regiontable')
%
% See also: fmri_regiontable, fmri_regionnumber, fmri_bwlabel

tests = functiontests(localfunctions);
end

% =========================================================================
% Setup
% =========================================================================
function setupOnce(tc)
here = fileparts(mfilename('fullpath'));
addpath(fileparts(here));                  % tests/ -> toolbox root

% Check the toolbox path here because the shared fixture requires
% fmri_mni2sub and fmri_vol2vect.
assumeTrue(tc, ~isempty(which('fmri_mni2sub')) && ~isempty(which('fmri_vol2vect')), ...
    'Toolbox not on the path; run fmritoolbox_setup before this suite.');

% Create three well-separated cubes on the MNI152 2 mm grid. Their sizes and
% locations produce clusters that interleave the hemispheres by size.
% Columns specify MNI [x y z] followed by cube side length in voxels.
spec = [ 50 -20   4   7      % right, largest
        -50 -20   4   5      % left,  middle
         40 -70  20   3];    % right, smallest

vol = zeros(91, 109, 91);
for b = 1:size(spec, 1)
    c = round(fmri_mni2sub(spec(b, 1:3)));
    h = floor(spec(b, 4) / 2);
    vol(c(1)-h:c(1)+h, c(2)-h:c(2)+h, c(3)-h:c(3)+h) = 1;
end

mask = fmri_vol2vect(vol) > 0;
assert(nnz(mask) > 0, 'Fixture blobs fell outside the brain mask.');

% A statistic with a distinct peak in each blob. Values are all positive here;
% the signed-map behaviour is the subject of its own test below.
rng(0);
stat        = zeros(numel(mask), 1);
stat(mask)  = 3 + rand(nnz(mask), 1);

tc.TestData.mask = mask;
tc.TestData.stat = stat;
tc.TestData.nvox = numel(mask);
end


% =========================================================================
% The fixture must exercise the bug it was written for
% =========================================================================
function testFixtureActuallyInterleaves(tc)
% Verify that sorting clusters by size interleaves the hemispheres. Otherwise,
% the fixture cannot detect a mismatch between size order and reporting order.
clust = fmri_regiontable(tc.TestData.mask, tc.TestData.stat, 0, 0, 1);

verifyGreaterThanOrEqual(tc, numel(clust), 2, ...
    'Fixture must produce at least two clusters.');

x = arrayfun(@(c) c.centroid(1), clust);
verifyTrue(tc, any(x < 0) && any(x >= 0), ...
    'Fixture must produce clusters in both hemispheres.');

[~, bysize] = sort(-[clust.n]);
isleft      = x(bysize) < 0;
verifyFalse(tc, isequal(isleft, sort(isleft, 'descend')), ...
    ['Fixture no longer interleaves the hemispheres by size, so it cannot ' ...
     'detect a CLUST ordering regression. Move or resize the blobs.']);
end

% =========================================================================
% The ordering invariant
% =========================================================================
function testClustOrderMatchesTableNumbering(tc)
[clust, s, ~, ~, ~, ~, T] = ...
    fmri_regiontable(tc.TestData.mask, tc.TestData.stat, 0, 0, 1);

verifyEqual(tc, numel(clust), numel(unique(T.Cluster)), ...
    'CLUST and T disagree on how many clusters there are.');

% Within a hemisphere both are size-descending, so the hemisphere sequences
% agree if and only if CLUST is in T's left-then-right order.
x  = arrayfun(@(c) c.centroid(1), clust);
hC = repmat("Right", numel(clust), 1);
hC(x < 0) = "Left";
[~, ia] = unique(T.Cluster, 'stable');
verifyEqual(tc, T.Hemisphere(ia), hC, ...
    'CLUST is not in the order T numbers the clusters.');

% The extents printed in S must be [clust.n], element for element. This is the
% exact pairing a caller makes when it reads cluster sizes out of CLUST.
tok = regexp(s, 'Cluster #\d+: N = (\d+)', 'tokens');
verifyEqual(tc, cellfun(@(c) str2double(c{1}), tok), [clust.n], ...
    'The extents printed in S do not match [clust.n] element for element.');
end

% =========================================================================
% Every output indexed the same way
% =========================================================================
function testRegionsAgreeAcrossOutputs(tc)
[clust, ~, ROI, list, roi_idx, clus, T] = ...
    fmri_regiontable(tc.TestData.mask, tc.TestData.stat, 0, 0, 1);

verifyEqual(tc, numel(ROI),     numel(clust), 'ROI has the wrong length.');
verifyEqual(tc, numel(list),    numel(clust), 'LIST has the wrong length.');
verifyEqual(tc, numel(roi_idx), numel(clust), 'ROI_IDX has the wrong length.');
verifyEqual(tc, size(clus, 2),  numel(clust), 'CLUS has the wrong width.');

for k = 1:numel(clust)
    names = {clust(k).region.name};

    verifyEqual(tc, list{k}, names, ...
        sprintf('LIST{%d} does not match CLUST(%d).region.', k, k));
    verifyEqual(tc, size(ROI{k}, 2), numel(names), ...
        sprintf('ROI{%d} has the wrong number of columns.', k));

    for m = 1:numel(names)
        verifyEqual(tc, nnz(ROI{k}(:, m)), clust(k).region(m).n, ...
            sprintf('ROI{%d}(:,%d) has the wrong voxel count.', k, m));
        verifyEqual(tc, sort(roi_idx{k}{m}(:)), sort(find(ROI{k}(:, m))), ...
            sprintf('ROI_IDX{%d}{%d} and ROI{%d}(:,%d) disagree.', k, m, k, m));
    end

    rows = T(T.Cluster == k, :);
    verifyEqual(tc, cellstr(rows.Region), names(:), ...
        sprintf('T rows for cluster %d do not match CLUST(%d).region.', k, k));

    % CLUS(:,k) is the union of the REPORTED regions, so it can be smaller than
    % the original cluster once ROISIZE has removed regions. With ROISIZE = 0
    % nothing is removed, so here the two must agree exactly.
    verifyEqual(tc, nnz(clus(:, k)), clust(k).n, ...
        sprintf('CLUS(:,%d) does not hold the whole cluster at ROISIZE = 0.', k));
end
end

% =========================================================================
% Thresholds
% =========================================================================
function testClsizeDropsSmallClusters(tc)
all_c = fmri_regiontable(tc.TestData.mask, tc.TestData.stat, 0, 0, 1);
cut   = min([all_c.n]) + 1;

kept = fmri_regiontable(tc.TestData.mask, tc.TestData.stat, cut, 0, 1);
verifyEqual(tc, numel(kept), nnz([all_c.n] >= cut), ...
    'CLSIZE did not retain exactly the clusters at or above the threshold.');
verifyTrue(tc, all([kept.n] >= cut), ...
    'A cluster below CLSIZE survived.');
end

function testRoisizeMayExceedClsize(tc)
% CLSIZE and ROISIZE are independent. Retain only clusters meeting CLSIZE and
% regions meeting ROISIZE; omit clusters with no remaining regions.
[clust, ~, ~, ~, ~, ~, T] = ...
    fmri_regiontable(tc.TestData.mask, tc.TestData.stat, 10, 60, 1);

for k = 1:numel(clust)
    verifyGreaterThanOrEqual(tc, [clust(k).region.n], 60, ...
        'A region below ROISIZE was reported.');
    verifyGreaterThanOrEqual(tc, clust(k).n, 10, ...
        'A cluster below CLSIZE was reported.');
end
verifyEqual(tc, numel(clust), numel(unique(T.Cluster)), ...
    'CLUST and T disagree after filtering.');
end

function testRoisizeShrinksClusMaps(tc)
% After ROISIZE filtering, CLUS(:,k) contains only the reported regions, while
% CLUST(k).n retains the size of the original cluster.
[clust, ~, ~, ~, ~, clus] = ...
    fmri_regiontable(tc.TestData.mask, tc.TestData.stat, 0, 20, 1);
for k = 1:numel(clust)
    verifyLessThanOrEqual(tc, nnz(clus(:, k)), clust(k).n);
    verifyEqual(tc, nnz(clus(:, k)), sum([clust(k).region.n]), ...
        'CLUS(:,k) is not the union of the reported regions.');
end
end

% =========================================================================
% Empty results
% =========================================================================
function testEmptyMapReturnsEmptyOutputs(tc)
n = tc.TestData.nvox;
[clust, s, ROI, list, roi_idx, clus, T] = ...
    fmri_regiontable(false(n, 1), zeros(n, 1), 0, 0, 1);

verifyTrue(tc, isempty(clust),   'CLUST must be empty.');
verifyTrue(tc, isempty(s),       'S must be empty.');
verifyTrue(tc, isempty(roi_idx), 'ROI_IDX must be empty.');
verifyEqual(tc, size(clus), [n 1]);
verifyEqual(tc, numel(ROI),  1);
verifyEqual(tc, numel(list), 1);
verifyEqual(tc, height(T),   0);
end

function testNothingSurvivesMatchesEmptyShape(tc)
% When no cluster survives the threshold, all outputs must match those
% returned for an empty input map.
n = tc.TestData.nvox;
[a1, b1, c1, d1, e1, f1, g1] = ...
    fmri_regiontable(false(n, 1), zeros(n, 1), 0, 0, 1);
[a2, b2, c2, d2, e2, f2, g2] = ...
    fmri_regiontable(tc.TestData.mask, tc.TestData.stat, 1e6, 0, 1);

verifyEqual(tc, a2, a1, 'CLUST differs between the two empty paths.');
verifyEqual(tc, b2, b1, 'S differs between the two empty paths.');
verifyEqual(tc, e2, e1, 'ROI_IDX differs between the two empty paths.');
verifyEqual(tc, size(f2),  size(f1),  'CLUS differs between the two empty paths.');
verifyEqual(tc, numel(c2), numel(c1), 'ROI differs between the two empty paths.');
verifyEqual(tc, numel(d2), numel(d1), 'LIST differs between the two empty paths.');
verifyEqual(tc, height(g2), height(g1), 'T differs between the two empty paths.');
end

% =========================================================================
% Signed maps
% =========================================================================
function testSignedPeakIsReportedWithItsSign(tc)
% The peak is located by abs(DATA) and reported signed, so a strongly negative
% voxel must win over a weaker positive one and come back negative.
mask = tc.TestData.mask;
stat = tc.TestData.stat;
idx  = find(mask);
stat(idx(1)) = -99;

clust = fmri_regiontable(mask, stat, 0, 0, 1);
peaks = [];
for k = 1:numel(clust)
    peaks = [peaks [clust(k).region.z]]; %#ok<AGROW>
end
verifyTrue(tc, any(peaks == -99), ...
    'The largest-magnitude voxel was not reported, or lost its sign.');
end
