function tests = test_tomni152
% TEST_TOMNI152  Unit tests for fmri_tomni152.
%
% Covers every pre-release test listed in Section 12 of the handover document,
% run against synthetic NIfTI fixtures in tests/fixtures/.
%
% Run with:
%   results = runtests('test_tomni152')
%
% The fixtures are anatomical phantoms (nested ellipsoids plus a left-right
% intensity gradient) placed on known affines. The gradient matters: it makes a
% left-right flip visible, which a symmetric phantom would hide.
%
% See also: fmri_tomni152, fmri_readnii, fmri_vol2vect

tests = functiontests(localfunctions);
end

% =========================================================================
function setupOnce(tc)
here = fileparts(mfilename('fullpath'));

% Put the toolbox root on the path so fmri_tomni152, fmri_readnii and
% fmri_vol2vect are found regardless of the working directory.
addpath(fileparts(here));

tc.TestData.fix = fullfile(here, 'fixtures');
tc.TestData.tmp = tempname;
mkdir(tc.TestData.tmp);

if ~exist(tc.TestData.fix, 'dir')
    error('test_tomni152:noFixtures', ...
          'Fixture directory not found: %s', tc.TestData.fix);
end

% Skip the suite if the bundled NIfTI library is unavailable, rather than
% returning the same dependency error for every test.
tc.TestData.haveNifti = ~isempty(which('load_untouch_nii_hdr'));
end

function setup(tc)
% Runs before every test. Skip cleanly if the NIFTI toolbox is unavailable, so
% a missing dependency reports as "skipped".
assumeTrue(tc, tc.TestData.haveNifti, ...
    ['NIFTI_20130306 toolbox not on the MATLAB path (load_untouch_nii_hdr ' ...
     'not found). Add it before running: addpath(genpath(''.../NIFTI_20130306'')).']);
end

function teardownOnce(tc)
if exist(tc.TestData.tmp, 'dir')
    rmdir(tc.TestData.tmp, 's');
end
end

function out = outfile(tc, name)
out = fullfile(tc.TestData.tmp, [name '.nii']);
end

function in = infile(tc, name)
% Fixtures are stored as .nii.gz files to reduce repository size. Decompress
% them into the temporary folder when an uncompressed file is required.
gz = fullfile(tc.TestData.fix, [name '.gz']);
in = fullfile(tc.TestData.fix, name);

if exist(in, 'file')
    return
elseif exist(gz, 'file')
    plain = fullfile(tc.TestData.tmp, name);
    if ~exist(plain, 'file')
        gunzip(gz, tc.TestData.tmp);
    end
    in = plain;
else
    error('test_tomni152:missingFixture', 'Fixture not found: %s(.gz)', name);
end
end

% -------------------------------------------------------------------------
% Read fixture data and headers through load_untouch_nii, matching the
% NIfTI-loading path used by fmri_tomni152.
% -------------------------------------------------------------------------
function data = readvol(fn)
nii  = load_untouch_nii(fn);
data = nii.img;
end

function hdr = readhdr(fn)
nii = load_untouch_nii(fn);
hdr = nii.hdr;
end

% =========================================================================
% The canonical acceptance test -- the one the handover calls central
% =========================================================================
function testVectorisesTo228453(tc)
% Verify that the converted volume lies on the toolbox grid and vectorises to
% exactly 228453 brain voxels.
if isempty(which('fmri_vol2vect'))
    assumeFail(tc, 'fmri_vol2vect not on path; skipping vectorisation integration test.');
end
o = outfile(tc, 'acc');
fmri_tomni152(infile(tc, 'test_mni152_1mm.nii'), o, 'verbose', 0);

vol = readvol(o);
v   = fmri_vol2vect(vol);
verifyEqual(tc, numel(v), 228453, ...
    'Output does not vectorise to the toolbox''s fixed 228453-voxel length.');
end

% =========================================================================
% Identity: an image already on the MNI152 2mm grid must come back unchanged
% =========================================================================
function testIdentityIsLossless(tc)
% An image already on the target grid should remain unchanged. This detects
% errors in the mapping between zero-based NIfTI and one-based MATLAB indices.
o = outfile(tc, 'ident');
in = infile(tc, 'test_mni152_2mm.nii');
fmri_tomni152(in, o, 'verbose', 0);

a = readvol(in);
b = readvol(o);

verifySize(tc, b, [91 109 91]);
verifyEqual(tc, b, a, 'AbsTol', 1e-4, ...
    ['Identity resampling changed the data. The coordinate mapping is wrong ' ...
     '(check the 0-based/1-based conversion).']);
end

function testIdentityPreservesLeftRightOrientation(tc)
% The phantom carries a left-right intensity gradient, so a flipped x axis is
% visible as a sign change. A symmetric phantom would pass even if flipped.
o = outfile(tc, 'lr');
in = infile(tc, 'test_mni152_2mm.nii');
fmri_tomni152(in, o, 'verbose', 0);

b = readvol(o);
% MNI x decreases with increasing voxel index (the affine's -2), so the mean
% of the low-index half must exceed that of the high-index half.
lo = mean(b(1:45,  :, :), 'all');
hi = mean(b(47:91, :, :), 'all');
verifyGreaterThan(tc, lo, hi, ...
    'Left-right orientation appears flipped.');
end

% =========================================================================
% Resolution and anisotropy
% =========================================================================
function testMni1mmDownsamples(tc)
o = outfile(tc, 'd1mm');
fmri_tomni152(infile(tc, 'test_mni152_1mm.nii'), o, 'verbose', 0);
b = readvol(o);
verifySize(tc, b, [91 109 91]);
verifyTrue(tc, any(b(:) > 0), 'Downsampled 1mm image is empty.');
end

function testAnisotropicResamples(tc)
% 3x3x4 mm input on the MNI grid.
o = outfile(tc, 'aniso');
fmri_tomni152(infile(tc, 'test_aniso_3x3x4.nii'), o, 'verbose', 0);
b = readvol(o);
verifySize(tc, b, [91 109 91]);
verifyTrue(tc, any(b(:) > 0), 'Anisotropic image resampled to empty.');
end

function testObliqueResamples(tc)
% A rotated (oblique) affine. Direct grid sampling must handle it.
o = outfile(tc, 'obl');
fmri_tomni152(infile(tc, 'test_oblique.nii'), o, 'verbose', 0);
b = readvol(o);
verifySize(tc, b, [91 109 91]);
verifyTrue(tc, any(b(:) > 0), 'Oblique image resampled to empty.');
end

% =========================================================================
% Label images -- nearest neighbour must not invent labels
% =========================================================================
function testAtlasLabelsArePreserved(tc)
% Nearest-neighbour resampling must preserve the original atlas labels and
% must not create new values at region boundaries.
o = outfile(tc, 'atlas');
in = infile(tc, 'test_atlas_labels.nii');
fmri_tomni152(in, o, 'interp', 'nearest', 'verbose', 0);

a = readvol(in);
b = readvol(o);

% Convert both label sets to double because the input and output may use
% different numeric classes.
in_labels  = double(unique(a(:)));
out_labels = double(unique(b(:)));

verifyTrue(tc, all(ismember(out_labels, in_labels)), ...
    'Nearest-neighbour resampling produced labels absent from the input atlas.');
verifyEqual(tc, out_labels, round(out_labels), 'AbsTol', 1e-6, ...
    'Atlas labels are no longer integers after resampling.');
end

function testLinearInterpOnLabelsWarns(tc)
% Requesting linear interpolation for something that looks like a label image
% must warn: it is almost always a mistake.
o = outfile(tc, 'atlaslin');
verifyWarning(tc, ...
    @() fmri_tomni152(infile(tc, 'test_atlas_labels.nii'), o, ...
                      'interp', 'linear', 'verbose', 0), ...
    'fmri_tomni152:labelImageInterp');
end

% =========================================================================
% Header paths: qform, qfac
% =========================================================================
function testQformOnlyMatchesSform(tc)
% Equivalent qform and sform affines must produce the same resampled image,
% verifying the qform-to-affine conversion.
o1 = outfile(tc, 'qf');
o2 = outfile(tc, 'sf');
fmri_tomni152(infile(tc, 'test_qform_only.nii'), o1, 'verbose', 0);
fmri_tomni152(infile(tc, 'test_mni152_2mm.nii'), o2, 'verbose', 0);

verifyEqual(tc, readvol(o1), readvol(o2), 'AbsTol', 1e-3, ...
    'The qform path disagrees with the sform path for identical geometry.');
end

function testQfacMinusOne(tc)
% qfac = -1 encodes a z-axis flip. Mishandling it flips the brain
% superior-inferior, which is a serious and easily-missed error.
o = outfile(tc, 'qfac');
fmri_tomni152(infile(tc, 'test_qfac_minus1.nii'), o, 'verbose', 0);
b = readvol(o);
verifySize(tc, b, [91 109 91]);
verifyTrue(tc, any(b(:) > 0), 'qfac = -1 image resampled to empty.');
end

% =========================================================================
% 4D
% =========================================================================
function test4dPreservesVolumes(tc)
o = outfile(tc, 'ts');
fmri_tomni152(infile(tc, 'test_4d_timeseries.nii'), o, 'verbose', 0);

b = readvol(o);
verifySize(tc, b, [91 109 91 5], ...
    'The temporal dimension was not preserved.');

% the fixture scales each volume by (1 + 0.1*t), so volume means must increase
m = squeeze(mean(reshape(b, [], 5), 1));
verifyTrue(tc, all(diff(m) > 0), ...
    'Volume order or content was not preserved through resampling.');
end

function test4dIntegratesWithVol2vect(tc)
% A 4D conversion must feed straight into the canonical representation.
if isempty(which('fmri_vol2vect'))
    assumeFail(tc, 'fmri_vol2vect not on path; skipping 4D vectorisation test.');
end
o = outfile(tc, 'ts2');
fmri_tomni152(infile(tc, 'test_4d_timeseries.nii'), o, 'verbose', 0);

v = fmri_vol2vect(readvol(o));
verifySize(tc, v, [228453 5], ...
    'A converted 4D file must vectorise to 228453 x T.');
end

% =========================================================================
% Intensity scaling
% =========================================================================
function testSclSlopeInterApplied(tc)
% Verify that stored intensities are converted to physical values using:
%
%     physical = stored * scl_slope + scl_inter
o = outfile(tc, 'scl');
fmri_tomni152(infile(tc, 'test_scl_scaling.nii'), o, 'verbose', 0);

b = readvol(o);
% The fixture: phantom values up to ~320, stored with slope 0.5 and inter 10.
% So the physical maximum is ~320, NOT the stored maximum of ~620.
verifyLessThan(tc, max(b(:)), 400, ...
    ['Output intensities are too large: scl_slope/scl_inter were probably ' ...
     'not applied, or were applied twice.']);
verifyGreaterThan(tc, max(b(:)), 250, ...
    'Output intensities are too small: scaling may have been misapplied.');
end

% =========================================================================
% The guard that matters most: native-space input
% =========================================================================
function testFarOutOfSpaceInputIsRejected(tc)
% Reject an input with negligible overlap with the MNI152 target grid, which
% would otherwise produce an almost empty output.
o = outfile(tc, 'faraway');
verifyError(tc, ...
    @() fmri_tomni152(infile(tc, 'test_far_out_of_space.nii'), o, 'verbose', 0), ...
    'fmri_tomni152:noOverlap');
end

function testNativeSpaceIsNotReliablyDetectable(tc)
% A deliberately honest test, documenting a real limitation rather than hiding it.
%
% Document the limitation that a plausible affine cannot prove MNI
% normalisation. A native-space image may overlap the target grid and be
% resampled successfully despite being spatially incorrect.
o = outfile(tc, 'native');
fmri_tomni152(infile(tc, 'test_native_space.nii'), o, 'verbose', 0);
verifySize(tc, readvol(o), [91 109 91], ...
    'A native-space image is resampled without error. This is a known limitation.');
end

function testSmallRoiMaskIsNotRejected(tc)
% Verify that a correctly positioned sparse ROI is not rejected. Spatial
% coverage, and not the proportion of non-zero voxels, determines overlap.
o = outfile(tc, 'roi');
fmri_tomni152(infile(tc, 'test_small_roi.nii'), o, 'interp', 'nearest', 'verbose', 0);
b = readvol(o);
verifySize(tc, b, [91 109 91]);
verifyTrue(tc, nnz(b) > 0 && nnz(b) < 0.01 * numel(b), ...
    'The small ROI should survive conversion, sparse but non-empty.');
end

% =========================================================================
% Input handling
% =========================================================================
function testGzippedInput(tc)
% .nii.gz support depends on the bundled NIFTI toolbox. The handover flags this
% as untested; this test settles it either way.
o  = outfile(tc, 'gz');
gz = fullfile(tc.TestData.fix, 'test_gzipped.nii.gz');
fmri_tomni152(gz, o, 'verbose', 0);
verifySize(tc, readvol(o), [91 109 91]);
end

function testMissingFileErrors(tc)
verifyError(tc, ...
    @() fmri_tomni152('no_such_file.nii', outfile(tc, 'x'), 'verbose', 0), ...
    'fmri_tomni152:fileNotFound');
end

function testBadInterpRejected(tc)
verifyError(tc, ...
    @() fmri_tomni152(infile(tc, 'test_mni152_2mm.nii'), outfile(tc, 'x'), ...
                      'interp', 'cubic'), ...
    'MATLAB:InputParser:ArgumentFailedValidation');
end

% =========================================================================
% Output header contract
% =========================================================================
function testOutputHeaderIsCanonical(tc)
% Downstream tools trust the header. It must say exactly what the data are.
o = outfile(tc, 'hdr');
fmri_tomni152(infile(tc, 'test_mni152_1mm.nii'), o, 'verbose', 0);

h = readhdr(o);

verifyEqual(tc, double(h.dime.dim(2:4)), [91 109 91]);
verifyEqual(tc, double(h.dime.pixdim(2:4)), [2 2 2], 'AbsTol', 1e-6);
verifyEqual(tc, double(h.dime.datatype), 16, 'Output should be float32.');
verifyEqual(tc, double(h.hist.sform_code), 1, 'sform should be authoritative.');
verifyEqual(tc, double(h.hist.qform_code), 0, 'qform should be disabled.');

% the canonical affine, exactly
verifyEqual(tc, double(h.hist.srow_x), [-2 0 0   90], 'AbsTol', 1e-6);
verifyEqual(tc, double(h.hist.srow_y), [ 0 2 0 -126], 'AbsTol', 1e-6);
verifyEqual(tc, double(h.hist.srow_z), [ 0 0 2  -72], 'AbsTol', 1e-6);

% output is already in physical units, so no further scaling may be applied
verifyEqual(tc, double(h.dime.scl_slope), 1, 'AbsTol', 1e-6);
verifyEqual(tc, double(h.dime.scl_inter), 0, 'AbsTol', 1e-6);
end

function testAnteriorCommissureMapsToOrigin(tc)
% Verify that the canonical affine maps NIfTI voxel [45 63 36], equivalent to
% MATLAB index [46 64 37], to the world origin [0 0 0] mm.
o = outfile(tc, 'ac');
fmri_tomni152(infile(tc, 'test_mni152_2mm.nii'), o, 'verbose', 0);

h = readhdr(o);
A = [double(h.hist.srow_x); double(h.hist.srow_y); double(h.hist.srow_z); 0 0 0 1];

world = A * [45; 63; 36; 1];
verifyEqual(tc, world(1:3), [0; 0; 0], 'AbsTol', 1e-6, ...
    'The AC voxel does not map to the world origin.');
end