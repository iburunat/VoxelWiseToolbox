function tests = test_simdata
% TEST_SIMDATA  Unit tests for fmri_simdata and its reconstruction by fmri_simget.
%
% Tests the main simulation contracts:
%
%   - W.BOLD is the z-scored HRF convolution of W.NEURAL.
%   - SIM.GRAM.LATENT contains the intended network correlations and
%     orthogonal non-network time courses.
%   - SIM.TRUTH follows the documented (S*G)/NORM calculation and remains
%     within the valid correlation range.
%   - Full-rank SVD reconstruction reproduces X_FULL.
%   - SVD_INFO contains only the documented metadata, not full SVD bases.
%
% SIZES. The fixture is deliberately small: 5 sources, 3 participants, T = 24.
% fmri_simdata allocates 91*109*91*T doubles per participant at several steps,
% so a default-sized run would put gigabytes in TestData for no extra coverage.
%
% Run with:
%   results = runtests('test_simdata')
%
% See also: fmri_simdata, fmri_simget, fmri_doublegamma

tests = functiontests(localfunctions);
end

% =========================================================================
% Setup: one simulation, shared by most tests
% =========================================================================
function setupOnce(tc)
here = fileparts(mfilename('fullpath'));
addpath(fileparts(here));                  % tests/ -> toolbox root

assumeTrue(tc, ~isempty(which('fmri_simdata')) && ~isempty(which('fmri_simget')), ...
    'Toolbox not on the path; run fmritoolbox_setup before this suite.');

tc.TestData.ns = 5;      % sources
tc.TestData.np = 3;      % participants
tc.TestData.T  = 24;     % time points
tc.TestData.TR = 2;
tc.TestData.nn = 3;      % network sources (the default)

rng(7);

% Pass empty values to exercise the documented defaults and disable X_FULL to
% reduce memory use. Capture console output and predeclare the outputs because
% assignments made inside EVALC are not visible to MATLAB's parser.
Xc = []; S_3D = []; W = []; svd_info = []; sim = [];

    evalc(['[Xc, S_3D, W, svd_info, ~, sim] = fmri_simdata(' ...
       'tc.TestData.ns, tc.TestData.np, tc.TestData.T, tc.TestData.TR, ' ...
       '[], [], [], [], 0, false);']);

tc.TestData.Xc       = Xc;
tc.TestData.S_3D     = S_3D;
tc.TestData.W        = W;
tc.TestData.svd_info = svd_info;
tc.TestData.sim      = sim;
end

% =========================================================================
% Output shapes
% =========================================================================
function testOutputShapes(tc)
d = tc.TestData;
verifyEqual(tc, numel(d.Xc), d.np);
verifySize(tc, d.S_3D, [91 109 91 d.ns]);
verifySize(tc, d.W.neural, [d.T d.ns d.np]);
verifySize(tc, d.W.bold,   [d.T d.ns d.np]);
verifyEqual(tc, numel(d.svd_info), d.np);
end

function testMaskConvention(tc)
% Every vectorised output is indexed by sim.mask, not by the full volume.
s = tc.TestData.sim;
verifyEqual(tc, s.mask.dims, [91 109 91]);
verifyEqual(tc, s.mask.n_voxels, nnz(s.mask.logical));
verifyEqual(tc, s.mask.n_voxels, 228453, ...
    'The brain mask is not the toolbox standard 228453 voxels.');
verifySize(tc, s.truth.latent,     [s.mask.n_voxels tc.TestData.ns]);
verifySize(tc, s.truth.population, [s.mask.n_voxels tc.TestData.ns]);
verifySize(tc, s.norm.latent,      [s.mask.n_voxels 1]);
end

function testDefaultsAreRecorded(tc)
% setupOnce passed [] for four arguments; sim.params must record the documented
% defaults rather than empties.
p = tc.TestData.sim.params;
verifyEqual(tc, p.sigma_ratio,    0.5);
verifyEqual(tc, p.n_comp,         0);
verifyEqual(tc, p.phase_strength, 0.2);
verifyEqual(tc, p.n_network,      3);
verifyEqual(tc, p.sig_amp,        20);
verifyEqual(tc, p.noise_sd,       2);
verifyEqual(tc, p.T,              tc.TestData.T);
end

% =========================================================================
% The neural-to-BOLD contract
% =========================================================================
function testBoldIsTheConvolvedNeuralSeries(tc)
% Verify that each BOLD time course is the z-scored HRF convolution of its
% corresponding neural time course, as documented.
d   = tc.TestData;
hrf = fmri_doublegamma(0:d.TR:30)';

for p = 1:d.np
    for s = 1:d.ns
        b = conv(d.W.neural(:, s, p), hrf);
        b = b(1:d.T);
        b = (b - mean(b)) / std(b);
        verifyEqual(tc, d.W.bold(:, s, p), b, 'AbsTol', 1e-10, ...
            sprintf('W.bold(:,%d,%d) is not conv(W.neural, hrf) z-scored.', s, p));
    end
end
end

% =========================================================================
% Network design and the orthogonalisation
% =========================================================================
function testNetworkDesignMatchesThePolarityRule(tc)
d   = tc.TestData;
dsg = d.sim.design;

verifyEqual(tc, dsg.network.idx, (1:d.nn)');
verifyEqual(tc, numel(dsg.network.sign), d.nn);
verifyEqual(tc, nnz(dsg.network.sign < 0), floor(d.nn/3), ...
    'The last floor(N_NETWORK/3) sources should carry -TC1.');
verifyEqual(tc, dsg.network.sign(1), 1, 'Source 1 must be positive.');

verifySize(tc, dsg.sources.centre, [d.ns 3]);
verifySize(tc, dsg.sources.radius, [d.ns 1]);
verifyEqual(tc, dsg.sources.isnetwork, (1:d.ns)' <= d.nn);
end

function testNetworkPolarityIsPresentInTheData(tc)
% design.network.sign must describe the data, not merely be recorded beside it.
d  = tc.TestData;
zz = @(x) (x - mean(x)) ./ std(x);
rr = @(a, b) (zz(a)' * zz(b)) / (numel(a) - 1);

for p = 1:d.np
    for s = 1:d.nn
        r = rr(d.W.bold(:, s, p), d.W.bold(:, 1, p));
        verifyEqual(tc, sign(r), d.sim.design.network.sign(s), ...
            sprintf('Source %d, participant %d: sign disagrees with design.', s, p));
        verifyGreaterThan(tc, abs(r), 0.5, ...
            'Network sources should remain strongly correlated after perturbation.');
    end
end
end

function testLatentGramIsBlockStructured(tc)
% Verify the intended latent correlation structure: network sources have
% correlations determined by their signs, while all other source pairs are
% orthogonal.
d   = tc.TestData;
G   = d.sim.gram.latent;
sgn = d.sim.design.network.sign;

verifySize(tc, G, [d.ns d.ns]);
verifyEqual(tc, diag(G), ones(d.ns, 1), 'AbsTol', 0, ...
    'The Gram diagonal must be exactly 1.');
verifyEqual(tc, G, G', 'AbsTol', 0, 'The Gram must be exactly symmetric.');

for j = 1:d.nn
    for k = 1:d.nn
        verifyEqual(tc, G(j,k), sgn(j)*sgn(k), 'AbsTol', 1e-10, ...
            sprintf('Network pair (%d,%d) should be %+d.', j, k, sgn(j)*sgn(k)));
    end
end

off = G;
off(1:d.nn, 1:d.nn)      = 0;      % the network block, checked above
off(1:d.ns+1:end)        = 0;      % the diagonal
verifyLessThan(tc, max(abs(off(:))), 1e-10, ...
    'Non-network time courses are not orthogonal in the BOLD domain.');
end

function testParticipantGramsAreValidCorrelationMatrices(tc)
d = tc.TestData;
verifySize(tc, d.sim.gram.participant, [d.ns d.ns d.np]);
for p = 1:d.np
    Gp = d.sim.gram.participant(:,:,p);
    verifyEqual(tc, diag(Gp), ones(d.ns,1), 'AbsTol', 0);
    verifyEqual(tc, Gp, Gp', 'AbsTol', 0);
    verifyLessThanOrEqual(tc, max(abs(Gp(:))), 1 + 1e-12);
end
end

% =========================================================================
% Ground truth
% =========================================================================
function testTruthFollowsTheDocumentedFormula(tc)
% truth(v,k) = (S*G)(v,k) / norm(v), with norm = sqrt(S*G*S' + (sigma/a)^2).
% Recomputed here from the published outputs alone, which is what a consumer
% would have to be able to do.
d  = tc.TestData;
s  = d.sim;
Sb = reshape(d.S_3D, [], d.ns);
Sb = Sb(s.mask.logical(:), :);
na = s.params.noise_sd / s.params.sig_amp;

nrm = sqrt(sum((Sb * s.gram.latent) .* Sb, 2) + na^2);
verifyEqual(tc, s.norm.latent, nrm, 'AbsTol', 1e-12);
verifyEqual(tc, s.truth.latent, (Sb * s.gram.latent) ./ nrm, 'AbsTol', 1e-12);

for p = 1:d.np
    Gp = s.gram.participant(:,:,p);
    verifyEqual(tc, s.norm.participant(:,p), ...
        sqrt(sum((Sb * Gp) .* Sb, 2) + na^2), 'AbsTol', 1e-12);
end
end

function testPopulationTruthIsPooledInAtanhSpace(tc)
% Pooled per participant and THEN combined, never by pooling the Gram first.
d  = tc.TestData;
s  = d.sim;
Sb = reshape(d.S_3D, [], d.ns);
Sb = Sb(s.mask.logical(:), :);

z = zeros(size(Sb,1), d.ns);
for p = 1:d.np
    z = z + atanh((Sb * s.gram.participant(:,:,p)) ./ s.norm.participant(:,p));
end
verifyEqual(tc, s.truth.population, tanh(z / d.np), 'AbsTol', 1e-12);
end

function testTruthStaysInsideTheUnitInterval(tc)
% The noise floor (sigma/a)^2 > 0 keeps the denominator above the numerator, so
% |r| < 1 strictly and the defensive clamp before atanh never binds.
s = tc.TestData.sim;
verifyLessThan(tc, max(abs(s.truth.latent(:))),     1);
verifyLessThan(tc, max(abs(s.truth.population(:))), 1);
verifyTrue(tc, all(isfinite(s.truth.latent(:))));
verifyTrue(tc, all(isfinite(s.truth.population(:))));

% And the signal is actually there: source 1 should dominate somewhere.
verifyGreaterThan(tc, max(abs(s.truth.latent(:,1))), 0.5, ...
    'No voxel correlates strongly with the task time course.');
end

% =========================================================================
% Compression and reconstruction
% =========================================================================
function testSvdInfoCarriesNoFullBases(tc)
% Verify that SVD_INFO contains only the singular values and volume dimensions,
% without redundant full SVD bases.
f = fieldnames(tc.TestData.svd_info);
verifyEqual(tc, sort(f), sort({'S'; 'xdim'; 'ydim'; 'zdim'}), ...
    'svd_info should carry only the singular values and the dimensions.');
end

function testDefaultCompressionRetainsMostComponents(tc)
% Verify that the default 95%-variance rule retains most components because
% the simulated noise is full rank.
d  = tc.TestData;
nc = size(d.Xc{1}.U, 2);
verifyLessThanOrEqual(tc, nc, d.T);
verifyGreaterThan(tc, nc / d.T, 0.5, ...
    'The default no longer retains most components; check the N_COMP help.');
end

function testFullRankReconstructionIsExact(tc)
% With N_COMP >= T, no components are discarded, so fmri_simget must
% reconstruct X_FULL to floating-point precision.
Xc = []; info = []; Xf = [];
evalc('[Xc, ~, ~, info, Xf] = fmri_simdata(4, 1, 24, 2, [], 24, [], 3, 0, true);');

rec = fmri_simget(Xc, info, 1);              % 228453 x T, the default
ref = fmri_vol2vect(Xf{1});
verifyEqual(tc, rec, ref, 'AbsTol', 1e-6, ...
    'A full-rank SVD did not reconstruct X_FULL.');

rec4 = fmri_simget(Xc, info, 1, 0);          % 4D form
verifySize(tc, rec4, [91 109 91 24]);
verifyEqual(tc, fmri_vol2vect(rec4), rec, 'AbsTol', 1e-12, ...
    'The vectorised and volumetric forms disagree.');
end

function testTruncatedReconstructionIsCloseButNotExact(tc)
% The documented behaviour: a low-rank approximation, not the exact data.
Xc = []; info = []; Xf = [];
evalc('[Xc, ~, ~, info, Xf] = fmri_simdata(4, 1, 24, 2, [], 5, [], 3, 0, true);');

rec = fmri_simget(Xc, info, 1);
ref = fmri_vol2vect(Xf{1});
err = norm(rec(:) - ref(:)) / norm(ref(:));
verifyGreaterThan(tc, err, 1e-6, ...
    'A 5-component reconstruction should not be exact.');
verifyLessThan(tc, err, 1, ...
    'A 5-component reconstruction should still resemble the data.');
end

% =========================================================================
% WANT_FULL and input validation
% =========================================================================
function testWantFullControlsAssembly(tc)
Xf_off = [];
evalc('[~, ~, ~, ~, Xf_off] = fmri_simdata(3, 2, 24, 2, [], 3, [], 3, 0, false);');
verifyTrue(tc, all(cellfun(@isempty, Xf_off)), ...
    'WANT_FULL = false must not assemble the volumes.');
Xf_on = [];
evalc('[~, ~, ~, ~, Xf_on] = fmri_simdata(3, 1, 24, 2, [], 3, [], 3, 0, true);');
verifySize(tc, Xf_on{1}, [91 109 91 24], ...
    'WANT_FULL = true must assemble the volumes.');
end

function testNetworkLargerThanSourcesIsRejected(tc)
% Checked before any heavy work, so this test is cheap.
verifyError(tc, @() fmri_simdata(3, 1, 24, 2, [], 3, [], 5, 0, false), ...
    'fmri_simdata:networkTooLarge');
end