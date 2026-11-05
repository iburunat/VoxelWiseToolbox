% TEST_PPI  Smoke test for fmri_ppi.
%
% Builds voxels with KNOWN coefficients and checks that fmri_ppi recovers them.
%
% The test that matters most is the SPECIFICITY one (voxel B below). Background
% voxels are pure noise, so a near-zero interaction beta there is unsurprising
% and proves little. The failure mode worth catching is a voxel with strong
% seed and psychological main effects but NO interaction: if the design matrix
% were wrong - main effects omitted, or regressors not demeaned before forming
% the product - the interaction term would absorb those main effects and return
% a large beta_ppi. That is a broken PPI producing confident nonsense, and only
% voxel B detects it.
%
% See also: fmri_ppi, fmri_ttest

fmritoolbox_setup;
fprintf('=== fmri_ppi smoke test ===\n\n');

rng(1);
T = 200;
N = 228453;

%% --- construct the seed ---------------------------------------------------
seed_mask = false(N, 1);
seed_mask(1:10) = true;
seed_ts_true = randn(T, 1);

data = 0.2 * randn(N, T);
data(seed_mask, :) = seed_ts_true' + 0.05 * randn(nnz(seed_mask), T);

%% --- psychological regressor ----------------------------------------------
% Deliberately NOT demeaned and with a non-zero offset. A real caller passes a
% raw HRF-convolved regressor, and fmri_ppi is responsible for centring it. The
% supplied version of this test demeaned psych before the call, so the
% function's own demeaning was never exercised.
psych_raw = zeros(T, 1);
psych_raw(51:100)  = 1;
psych_raw(151:180) = 1;
psych_raw = psych_raw + 0.05 * randn(T, 1) + 3;      % offset of 3

%% --- ground truth ---------------------------------------------------------
seed_c  = seed_ts_true - mean(seed_ts_true);
psych_c = psych_raw    - mean(psych_raw);
ppi_c   = seed_c .* psych_c;
ppi_c   = ppi_c - mean(ppi_c);

vA = 1000;    % A: genuine interaction, plus main effects
vB = 2000;    % B: main effects ONLY, no interaction   <- the specificity test
vC = 3000;    % C: contains NaNs, exercises the omitnan path

data(vA, :) = 2.0*ppi_c' + 0.5*seed_c' + 1.0*psych_c' + 0.2*randn(1, T);
data(vB, :) =              3.0*seed_c' + 2.0*psych_c' + 0.2*randn(1, T);
data(vC, :) = 1.0*ppi_c' + 0.2*randn(1, T);
data(vC, [7 42 99]) = NaN;

% NaNs inside the SEED itself, to exercise mean(..., 'omitnan')
data(3, [15 60]) = NaN;

%% --- run -------------------------------------------------------------------
[beta_ppi, beta_seed, beta_psych] = fmri_ppi(data, seed_mask, psych_raw);

%% --- A: recovery of known coefficients ------------------------------------
fprintf('--- voxel A: interaction 2.0, seed 0.5, psych 1.0 ---\n');
fprintf('  beta_ppi   = %+.3f  (expect  2.000)\n', beta_ppi(vA));
fprintf('  beta_seed  = %+.3f  (expect  0.500)\n', beta_seed(vA));
fprintf('  beta_psych = %+.3f  (expect  1.000)\n', beta_psych(vA));
assert(abs(beta_ppi(vA)   - 2.0) < 0.2, ...
    'beta_ppi not recovered: got %.3f, expected 2.0', beta_ppi(vA));
assert(abs(beta_seed(vA)  - 0.5) < 0.3, ...
    'beta_seed not recovered: got %.3f, expected 0.5', beta_seed(vA));
assert(abs(beta_psych(vA) - 1.0) < 0.3, ...
    'beta_psych not recovered: got %.3f, expected 1.0', beta_psych(vA));
fprintf('  recovered\n\n');

%% --- B: specificity, the decisive test ------------------------------------
fprintf('--- voxel B: strong main effects, NO interaction ---\n');
fprintf('  beta_ppi   = %+.3f  (expect ~0 - THIS IS THE KEY TEST)\n', beta_ppi(vB));
fprintf('  beta_seed  = %+.3f  (expect  3.000)\n', beta_seed(vB));
fprintf('  beta_psych = %+.3f  (expect  2.000)\n', beta_psych(vB));
assert(abs(beta_ppi(vB)) < 0.2, ...
    ['SPECIFICITY FAILURE: beta_ppi = %.3f at a voxel with no interaction.\n' ...
     'The interaction term is absorbing the main effects. Check that the design\n' ...
     'matrix includes seed and psych as nuisance regressors, and that both are\n' ...
     'demeaned BEFORE the product is formed.'], beta_ppi(vB));
assert(abs(beta_seed(vB)  - 3.0) < 0.3, 'beta_seed wrong at voxel B: %.3f', beta_seed(vB));
assert(abs(beta_psych(vB) - 2.0) < 0.3, 'beta_psych wrong at voxel B: %.3f', beta_psych(vB));
fprintf('  main effects did NOT leak into the interaction\n\n');

%% --- demeaning of a non-centred regressor ---------------------------------
% psych_raw carries an offset of 3. If the function did not demean it, the
% interaction would be dominated by 3*seed - i.e. a main effect - and voxel B
% above would already have failed. This restates the same guarantee explicitly.
fprintf('--- non-centred psych (offset 3) handled ---\n');
fprintf('  mean(psych_raw) = %.3f, and voxel B still clean\n\n', mean(psych_raw));

%% --- C: NaN handling -------------------------------------------------------
fprintf('--- voxel C and seed NaNs ---\n');
fprintf('  beta_ppi at C = %+.3f\n', beta_ppi(vC));
assert(isnan(beta_ppi(vC)), ...
    ['Voxel C contains NaN timepoints, so its betas must be NaN; got %.3f.\n' ...
     'If this returns a number, the GLM solve has started dropping or imputing\n' ...
     'missing timepoints, which changes the documented contract.'], beta_ppi(vC));

% The seed carries NaNs too (voxel 3). Those must NOT propagate, because the
% seed time course is averaged with 'omitnan'.
assert(isfinite(beta_ppi(vA)), ...
    'NaNs in the seed propagated into the betas; the omitnan averaging failed.');
fprintf('  NaN confined to the affected voxel; seed NaNs did not propagate\n\n');

%% --- background specificity ------------------------------------------------
bg = setdiff(4:5000, [vA vB vC]);
fprintf('--- background (pure noise) ---\n');
fprintf('  mean |beta_ppi|   = %.4f\n', mean(abs(beta_ppi(bg))));
fprintf('  mean |beta_seed|  = %.4f\n', mean(abs(beta_seed(bg))));
fprintf('  mean |beta_psych| = %.4f\n', mean(abs(beta_psych(bg))));
assert(mean(abs(beta_ppi(bg)))   < 0.1, 'background beta_ppi too large');
assert(mean(abs(beta_seed(bg)))  < 0.1, 'background beta_seed too large');
assert(mean(abs(beta_psych(bg))) < 0.1, 'background beta_psych too large');
fprintf('  all near zero\n\n');

%% --- error paths -----------------------------------------------------------
fprintf('--- validation ---\n');
check(@() fmri_ppi(randn(100, T), seed_mask, psych_raw),      'wrong voxel count');
check(@() fmri_ppi(data, false(100, 1), psych_raw),           'wrong seed size');
check(@() fmri_ppi(data, false(N, 1), psych_raw),             'empty seed');
check(@() fmri_ppi(data, seed_mask, psych_raw(1:50)),         'psych length');
check(@() fmri_ppi(data, seed_mask, ones(T, 1)),              'constant psych (rank deficient)');

fprintf('\nfmri_ppi smoke test passed.\n');

function check(fn, label)
raised = true;
try
    fn();
    raised = false;
catch ME
    assert(startsWith(ME.identifier, 'fmri_ppi:'), ...
        '%s: wrong error identifier, got %s', label, ME.identifier);
    fprintf('  %-34s caught (%s)\n', label, ME.identifier);
end
assert(raised, '%s: no error was raised', label);
end