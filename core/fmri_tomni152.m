function fmri_tomni152(input_nii, output_nii, varargin)
% FMRI_TOMNI152  Resamples an MNI-space NIfTI onto the toolbox 2mm grid.
%
% Resamples a NIfTI image with valid spatial metadata onto the toolbox standard
% MNI152 2mm grid, 91 x 109 x 91 voxels, and writes it to disk. The result
% is the output file.
%
% This performs AFFINE-BASED resampling only. It does NOT perform nonlinear
% registration or spatial normalisation from native anatomical space. The input
% affine must already describe the image's location in MNI/world coordinates,
% i.e. SPM normalisation, FSL fnirt or ANTs registration has already been
% applied.
%
% Usage:
%   fmri_tomni152(input_nii, output_nii)
%   fmri_tomni152(input_nii, output_nii, 'param', value, ...)
%
% Inputs:
%   INPUT_NII  - Path to the input NIfTI (.nii). Support for .nii.gz depends on
%                the bundled NIFTI toolbox version; test before relying on it.
%   OUTPUT_NII - Path for the output NIfTI (.nii).
%
%   Optional name-value pairs:
%
%   'origin'     - World coordinates [x y z] in mm of input NIfTI voxel
%                  [0,0,0]. This is the affine translation, not the voxel
%                  index of the anterior commissure (AC). On the target grid,
%                  the AC is at NIfTI voxel [45 63 36], or MATLAB index
%                  [46 64 37]. If a valid header affine exists, this option
%                  changes only its translation and preserves its orientation.
%                  Default: read from the sform, or qform if unavailable.
%   'voxel_size' - Scalar or [sx sy sz] in mm, overriding the input voxel size.
%                  With a valid header affine this rescales the affine columns
%                  and preserves orientation. Default: read from the header.
%   'interp'     - Interpolation method, numeric or string:
%                    0 / 'nearest' - nearest neighbour. THE ONLY CORRECT METHOD
%                                    for integer label images (atlases,
%                                    parcellations, ROI masks); linear and
%                                    spline invent label values that do not
%                                    exist, at region boundaries.
%                    1 / 'linear'  - trilinear (default). Best balance for
%                                    functional and most anatomical images.
%                    2 / 'spline'  - smoother with better detail, but can
%                                    overshoot at sharp edges.
%                  The output datatype is float32 whichever is used, so with
%                  'nearest' integer labels are preserved numerically but
%                  stored as float32.
%   'verbose'    - 1 to print progress (default), 0 for silent.
%
% WHAT IS WRITTEN
%   Dimensions  : 91 x 109 x 91, or 91 x 109 x 91 x V for a 4D input
%   Voxel size  : 2 x 2 x 2 mm isotropic
%   Datatype    : float32 (NIfTI datatype 16)
%   Affine      : canonical MNI152 2mm sform (sform_code 1, qform_code 0)
%   Scaling     : scl_slope 1, scl_inter 0 - values are physical
%   pixdim(1)   : 1
%   cal_min/max : set from the output data range
%   Voxels falling outside the input field of view are set to 0.
%
%   The canonical target affine, RAS / SPM convention:
%       [-2   0   0    90 ]
%       [  0  2   0  -126 ]
%       [  0  0   2   -72 ]
%       [  0  0   0     1 ]
%   so that TARGET_AFFINE * [45; 63; 36; 1] = [0; 0; 0; 1].
%
% LIMITATION: MNI SPACE CANNOT BE VERIFIED
%   A valid affine does not prove that an image has been normalised to MNI
%   space. A native-space image may overlap the target grid and be resampled
%   without an error, despite being spatially incorrect. The coverage check
%   detects only gross misalignment. Always compare the output with an MNI152
%   template before use.
%
% METHOD: DIRECT TARGET-GRID SAMPLING
%   Each target voxel is mapped through MNI world coordinates to the
%   corresponding location in the input image:
%
%       target voxel -> MNI coordinates -> input voxel -> interpolated value
%
%   This creates the output directly on the canonical grid, without separate
%   reslicing, padding or cropping steps.
% 
% AFFINE PRIORITY
%   A valid header affine is always used when available. 'origin' and
%   'voxel_size' modify its translation and scale, respectively, while
%   preserving its orientation. If the header has no valid sform or qform,
%   a diagonal affine is constructed only when both options are supplied.
%   This fallback is suitable only for axis-aligned images.
%
% NIFTI INPUT AND OUTPUT
%   load_untouch_nii preserves the stored voxel orientation, allowing the
%   header affine to define the coordinate mapping. Because it returns stored
%   intensity values, scl_slope and scl_inter are applied manually before
%   interpolation. save_untouch_nii is used because this function constructs
%   the output affine and header explicitly.
%
%   Requires load_untouch_nii and save_untouch_nii from NIFTI_20130306
%   (Jimmy Shen). Resampling uses MATLAB's interpn.
%
% Examples:
%   % Recommended: take the full affine from the file header
%   fmri_tomni152('func.nii', 'func_mni.nii');
%
%   % An atlas or ROI mask: nearest neighbour, never linear
%   fmri_tomni152('atlas.nii', 'atlas_mni.nii', 'interp', 'nearest');
%
%   % Override the origin; header orientation still preserved
%   fmri_tomni152('func.nii', 'func_mni.nii', 'origin', [90 -126 -72]);
%
%   % Override both - the fallback path for a file with no sform or qform
%   fmri_tomni152('func.nii', 'func_mni.nii', 'origin', [90 -126 -72], ...
%                 'voxel_size', [3 3 4]);
%
%   % Silent, for batch use
%   fmri_tomni152('func.nii', 'func_mni.nii', 'verbose', 0);
%
%   % Check the result reaches the toolbox vector length
%   fmri_tomni152('input.nii', 'output.nii');
%   v = fmri_vol2vect(fmri_readnii('output.nii'));
%   assert(numel(v) == 228453, 'Vectorisation size mismatch');
%
% See also: fmri_readnii, fmri_checknifti, fmri_export, fmri_vol2vect

% =========================================================================
%  0.  PARSE INPUTS
% =========================================================================
p = inputParser();
addRequired(p,  'input_nii',  @(x) ischar(x) || isstring(x));
addRequired(p,  'output_nii', @(x) ischar(x) || isstring(x));
addParameter(p, 'origin',     [], @(x) isempty(x) || ...
    (isnumeric(x) && numel(x) == 3));
addParameter(p, 'voxel_size', [], @(x) isempty(x) || ...
    (isnumeric(x) && ismember(numel(x), [1 3]) && all(x > 0)));
addParameter(p, 'interp',     'linear', @(x) validate_interp(x));
addParameter(p, 'verbose',    1, @(x) ismember(x, [0 1]));
parse(p, input_nii, output_nii, varargin{:});

input_fn   = char(p.Results.input_nii);
output_fn  = char(p.Results.output_nii);
origin_xyz = p.Results.origin;
voxel_size = p.Results.voxel_size;
interp_str = resolve_interp(p.Results.interp);
verbose    = p.Results.verbose;

% =========================================================================
%  1.  VALIDATE FILE AND LOAD HEADER
% =========================================================================
if ~exist(input_fn, 'file')
    error('fmri_tomni152:fileNotFound', ...
          'Input file not found:\n  %s', input_fn);
end

% Load the NIfTI once and reuse both its image data and header.
% load_untouch_nii preserves the stored voxel orientation, allowing the
% header affine to define the coordinate mapping.
nii_in  = load_untouch_nii(input_fn);
hdr     = nii_in.hdr;

% =========================================================================
%  2.  READ HEADER AFFINE  (sform preferred over qform)
% =========================================================================
if hdr.hist.sform_code > 0
    HEADER_AFFINE = [ hdr.hist.srow_x;
                      hdr.hist.srow_y;
                      hdr.hist.srow_z;
                      0, 0, 0, 1      ];
    affine_source = 'sform';
elseif hdr.hist.qform_code > 0
    HEADER_AFFINE = qform_to_affine(hdr);
    affine_source = 'qform';
else
    HEADER_AFFINE = [];
    affine_source = 'none';
end

% =========================================================================
%  3.  DETECT NON-AXIS-ALIGNED ORIENTATION
%
%   Off-diagonal direction cosines indicate that the image axes are not
%   aligned with the world axes, for example because the image is oblique,
%   axis-permuted or stored in a different orientation.
% =========================================================================
is_nonaligned = false;
if ~isempty(HEADER_AFFINE)
    R      = HEADER_AFFINE(1:3, 1:3);
    vox_sz = sqrt(sum(R.^2, 1));

    if any(vox_sz < eps)
        error('fmri_tomni152:badHeaderAffine', ...
              ['Header affine has one or more zero or near-zero voxel axes.\n' ...
               'The sform/qform may be corrupt or incomplete.\n'               ...
               'Please repair the NIfTI header or supply both ''origin'' and ' ...
               '''voxel_size'' explicitly.']);
    end

    dir_cos  = R ./ vox_sz;
    off_diag = dir_cos - diag(diag(dir_cos));
    is_nonaligned = any(abs(off_diag(:)) > 0.01);
end

% =========================================================================
%  4. BUILD INPUT AFFINE
%
%   Use the header sform or qform when available. 'origin' replaces only the
%   translation, and 'voxel_size' rescales the spatial axes while preserving
%   their orientation.
%
%   If no valid header affine exists, construct a diagonal affine only when
%   both 'origin' and 'voxel_size' are supplied. This fallback is suitable
%   only for axis-aligned images. Otherwise, return an error.
% =========================================================================
if ~isempty(HEADER_AFFINE)
    % --- Case (a): header affine available — always preferred ---
    INPUT_AFFINE = HEADER_AFFINE;

    if ~isempty(origin_xyz)
        % Override translation column only; rotation/orientation preserved
        origin_xyz = origin_xyz(:)';
        INPUT_AFFINE(1:3, 4) = origin_xyz(:);
        if verbose
            fprintf('NOTE: ''origin'' supplied — overriding header translation column.\n');
            fprintf('      Orientation from %s is preserved.\n', affine_source);
        end
    end

    if ~isempty(voxel_size)
        % Rescale rotation columns to new voxel size; orientation preserved
        voxel_size  = expand_voxel_size(voxel_size);
        current_vsz = sqrt(sum(INPUT_AFFINE(1:3,1:3).^2, 1));
        if any(current_vsz < eps)
            error('fmri_tomni152:badAffine', ...
                  ['Input affine has one or more zero or near-zero voxel axes.\n' ...
                   'The header affine may be corrupt or incomplete.\n'            ...
                   'Please repair the NIfTI header or supply both ''origin'' '   ...
                   'and ''voxel_size'' explicitly.']);
        end
        for i = 1:3
            INPUT_AFFINE(1:3,i) = INPUT_AFFINE(1:3,i) / current_vsz(i) * voxel_size(i);
        end
        if verbose
            fprintf('NOTE: ''voxel_size'' supplied — rescaling affine columns.\n');
            fprintf('      Orientation from %s is preserved.\n', affine_source);
        end
    end

elseif ~isempty(origin_xyz) && ~isempty(voxel_size)
    % --- Case (b): no header affine — diagonal fallback ---
    fprintf(['NOTE: No valid header affine found (sform_code=0, qform_code=0).\n' ...
             '      Constructing diagonal axis-aligned affine from supplied\n'     ...
             '      ''origin'' and ''voxel_size''. This is only appropriate for\n' ...
             '      axis-aligned images with no spatial metadata.\n']);
    voxel_size = expand_voxel_size(voxel_size);
    origin_xyz = origin_xyz(:)';
    sx = voxel_size(1); sy = voxel_size(2); sz = voxel_size(3);
    ox = origin_xyz(1); oy = origin_xyz(2); oz = origin_xyz(3);
    INPUT_AFFINE = [ -sx,  0,   0,  ox;
                       0,  sy,  0,  oy;
                       0,   0,  sz, oz;
                       0,   0,   0,  1 ];
    affine_source = 'diagonal (manual fallback)';

else
    % --- Case (c): insufficient information ---
    error('fmri_tomni152:noAffine', ...
          ['No valid affine in header (sform_code=0, qform_code=0)\n'       ...
           'and insufficient spatial metadata supplied.\n'                    ...
           'Please supply both ''origin'' and ''voxel_size'' explicitly,\n'  ...
           'or use an image with a valid sform or qform.']);
end

% Derive reporting values from the final INPUT_AFFINE
voxel_size_rep = sqrt(sum(INPUT_AFFINE(1:3,1:3).^2, 1));
origin_rep     = INPUT_AFFINE(1:3, 4)';

% =========================================================================
%  5.  TOOLBOX TARGET CONSTANTS
%
%   Verification: TARGET_AFFINE * [45; 63; 36; 1] = [0; 0; 0; 1]
%   (NIfTI 0-based AC voxel maps to world origin [0,0,0] mm)
% =========================================================================
TARGET_DIM    = [91, 109, 91];
TARGET_VOXEL  = [2, 2, 2];
TARGET_AFFINE = [ -2,  0,  0,  90;
                   0,  2,  0, -126;
                   0,  0,  2,  -72;
                   0,  0,  0,    1 ];

% =========================================================================
%  6.  REPORT
% =========================================================================
in_dim   = hdr.dime.dim(2:4);
n_vols_hdr = max(hdr.dime.dim(5), 1);   % provisional: confirmed from the array in Step 7
is_aniso = any(abs(voxel_size_rep - voxel_size_rep(1)) > 1e-4);

if verbose
    fprintf('\n=== fmri_tomni152 ===\n');
    fprintf('Input        : %s\n', input_fn);
    fprintf('Output       : %s\n', output_fn);
    fprintf('Input dims   : [%d %d %d]%s\n', in_dim(1), in_dim(2), in_dim(3), ...
            ifelse(n_vols_hdr > 1, sprintf('  x %d volumes (4D)', n_vols_hdr), ''));
    fprintf('Affine source: %s\n', affine_source);
    fprintf('Voxel size   : [%.4g %.4g %.4g] mm  (%s)\n', ...
            voxel_size_rep(1), voxel_size_rep(2), voxel_size_rep(3), ...
            ifelse(is_aniso, 'anisotropic', 'isotropic'));
    fprintf('Origin       : [%.4g %.4g %.4g] mm  (world coord of voxel [0,0,0])\n', ...
            origin_rep(1), origin_rep(2), origin_rep(3));
    fprintf('Interpolation: %s\n', interp_str);
    if is_nonaligned
        fprintf(['NOTE: The input direction-cosine matrix is not diagonal. This means\n' ...
                 '      an oblique acquisition, an axis permutation, or a non-RAS\n' ...
                 '      orientation convention -- all of which are valid. Direct grid\n' ...
                 '      sampling handles every one of them correctly.\n']);
    end
end

% =========================================================================
%  7. PREPARE IMAGE DATA AND INTENSITY SCALING
%
%   load_untouch_nii returns stored intensity values. Convert them to physical
%   values before interpolation using:
%
%       physical = stored * scl_slope + scl_inter
%
%   The output therefore uses scl_slope = 1 and scl_inter = 0.
% =========================================================================
if verbose, fprintf('\nStep 1/3 - Using image data (loaded via load_untouch_nii) ...\n'); end

% nii_in was loaded at the top of the function (single read). Reuse it here.
img_raw = nii_in.img;    % raw stored values, original datatype

% Resolve input intensity scaling
input_slope = 1;
input_inter = 0;
if isfield(nii_in.hdr.dime, 'scl_slope') && nii_in.hdr.dime.scl_slope ~= 0
    input_slope = double(nii_in.hdr.dime.scl_slope);
end
if isfield(nii_in.hdr.dime, 'scl_inter')
    input_inter = double(nii_in.hdr.dime.scl_inter);
end
has_scaling = (input_slope ~= 1) || (input_inter ~= 0);
if has_scaling && verbose
    fprintf('NOTE: Input scl_slope=%.6g, scl_inter=%.6g — applying manually.\n', ...
            input_slope, input_inter);
end

% Ensure 4D: [X Y Z V]
if ndims(img_raw) == 3
    img_raw = reshape(img_raw, [size(img_raw), 1]);
end
n_vols = size(img_raw, 4);   % authoritative: the array, not the header

if n_vols ~= n_vols_hdr
    warning('fmri_tomni152:volCountMismatch', ...
        ['The header reports %d volume(s) but the data array holds %d. ' ...
         'Using the array. The header may be malformed.'], n_vols_hdr, n_vols);
end

% =========================================================================
%  8.  BUILD TARGET COORDINATE GRID AND MAP TO INPUT VOXEL SPACE
%
%   NIfTI voxel indices are 0-based; MATLAB interpn expects 1-based.
%
%   target_vox0  : homogeneous target voxels [4 x N], 0-based NIfTI
%   target_world : MNI world coordinates [4 x N], mm
%   input_vox0   : input voxel coordinates [4 x N], 0-based NIfTI
%   xi, yi, zi   : input voxel coordinates, 1-based MATLAB, for interpn
% =========================================================================
if verbose, fprintf('Step 2/3 - Mapping target grid into input voxel space ...\n'); end

[I, J, K]    = ndgrid(0 : TARGET_DIM(1)-1, ...
                      0 : TARGET_DIM(2)-1, ...
                      0 : TARGET_DIM(3)-1);
target_vox0  = [I(:)'; J(:)'; K(:)'; ones(1, numel(I))];  % [4 x N]
target_world = TARGET_AFFINE * target_vox0;                  % [4 x N]
input_vox0   = INPUT_AFFINE  \ target_world;                 % [4 x N]

xi = reshape(input_vox0(1,:) + 1, TARGET_DIM);   % 0-based → 1-based
yi = reshape(input_vox0(2,:) + 1, TARGET_DIM);
zi = reshape(input_vox0(3,:) + 1, TARGET_DIM);

% =========================================================================
%  9.  INTERPOLATE — LOOP OVER VOLUMES
%
%   Each volume is converted to double individually to minimise peak memory.
%   Input intensity scaling is applied before interpolation.
%   Voxels outside the input FOV receive value 0 (extrapval).
% =========================================================================
if verbose
    fprintf('Step 3/3 - Interpolating %d volume(s) using ''%s'' ...\n', ...
            n_vols, interp_str);
end

% Label images require nearest-neighbour interpolation because other methods
% can create values that do not correspond to valid labels.
%
% Detect likely label images from their physical values after applying
% scl_slope and scl_inter. Checking the stored values instead could
% misclassify functional images saved as scaled integers.
if ~strcmp(interp_str, 'nearest')
    sample = double(img_raw(:,:,:,1)) * input_slope + input_inter;   % physical
    u = unique(sample(sample ~= 0));
    looks_like_labels = numel(u) >= 2 && numel(u) <= 256 && ...
                        all(u == round(u)) && all(u >= 0) && max(u) <= 1000;
    if looks_like_labels
        warning('fmri_tomni152:labelImageInterp', ...
            ['The input holds %d distinct non-negative integer values, so it looks\n' ...
             'like a label image (an atlas, parcellation or ROI mask), but ''%s''\n' ...
             'interpolation was requested. This will create label values that do\n' ...
             'not exist in the atlas at region boundaries.\n' ...
             'Use ''interp'', ''nearest'' for label images.'], ...
             numel(u), interp_str);
    end
end

img_out = zeros([TARGET_DIM, n_vols], 'single');

x_in = 1 : size(img_raw, 1);
y_in = 1 : size(img_raw, 2);
z_in = 1 : size(img_raw, 3);

for v = 1:n_vols
    vol = double(img_raw(:,:,:,v));          % one volume at a time (memory)
    vol = vol * input_slope + input_inter;    % apply NIfTI intensity scaling
    img_out(:,:,:,v) = single( ...
        interpn(x_in, y_in, z_in, vol, xi, yi, zi, interp_str, 0) );
end

% Squeeze back to 3D if input was 3D
if n_vols == 1
    img_out = squeeze(img_out);
end

% =========================================================================
%  10. VERIFY OUTPUT
%
%   Confirm the target dimensions and check how much of the target grid lies
%   within the input field of view. Low coverage may indicate gross spatial
%   misalignment and an almost empty output.
%
%   Coverage cannot confirm that the input was normalised to MNI space. A
%   native-space image with a plausible affine may still overlap the target
%   grid. Always compare the output visually with an MNI152 template.
% =========================================================================
out_dim = size(img_out);
if ~isequal(out_dim(1:3), TARGET_DIM)
    error('fmri_tomni152:badOutputSize', ...
          'Output size is %s, expected [91 109 91]. Check input affine.', ...
          mat2str(out_dim(1:3)));
end

% Measure geometric coverage as the fraction of the target grid that falls
% within the input field of view. This is more appropriate than counting
% non-zero output voxels because a correctly positioned ROI mask may contain
% mostly zeros.
in_fov = (input_vox0(1,:) >= 0) & (input_vox0(1,:) <= size(img_raw,1)-1) & ...
         (input_vox0(2,:) >= 0) & (input_vox0(2,:) <= size(img_raw,2)-1) & ...
         (input_vox0(3,:) >= 0) & (input_vox0(3,:) <= size(img_raw,3)-1);
coverage = mean(in_fov);

if coverage < 0.02
    error('fmri_tomni152:noOverlap', ...
        ['Only %.1f%% of the target grid falls within the input field of view.\n' ...
         'The input may not be normalised to MNI space, or its affine may be\n' ...
         'incorrect. fmri_tomni152 performs affine resampling only, so normalise\n' ...
         'native-space images with SPM, FSL or ANTs before using this function.\n' ...
         'If the image is already in MNI space, check that ''origin'' gives the\n' ...
         'world coordinates of voxel [0,0,0], not the voxel index of the AC.'], ...
         100 * coverage);

elseif coverage < 0.5
    warning('fmri_tomni152:partialCoverage', ...
        ['Only %.1f%% of the target grid falls within the input field of view;\n' ...
         'voxels outside it are set to zero. This may be expected for a\n' ...
         'partial-field-of-view image. Otherwise, check the input affine and\n' ...
         'compare the output with an MNI152 template.'], ...
         100 * coverage);
end

if nnz(img_out) == 0
    warning('fmri_tomni152:emptyOutput', ...
        'Every output voxel is zero. The input image may itself be empty.');
end

% =========================================================================
%  11. ASSEMBLE AND SAVE OUTPUT NIFTI
%
%   save_untouch_nii writes the affine and header created here without
%   applying additional orientation transforms.
% =========================================================================
out_nii = nii_in;
out_nii.img                   = img_out;
out_nii.hdr.dime.dim(1)      = ifelse(n_vols > 1, 4, 3);
out_nii.hdr.dime.dim(2:4)    = TARGET_DIM;
out_nii.hdr.dime.dim(5)      = max(n_vols, 1);
out_nii.hdr.dime.dim(6:8)    = 1;              % reset stale higher dims
out_nii.hdr.dime.pixdim(1)   = 1;              % qfac = 1 (qform disabled)
out_nii.hdr.dime.pixdim(2:4) = TARGET_VOXEL;
out_nii.hdr.dime.datatype    = 16;             % float32
out_nii.hdr.dime.bitpix      = 32;
out_nii.hdr.hist.sform_code  = 1;
out_nii.hdr.hist.qform_code  = 0;             % sform is authoritative
out_nii.hdr.hist.srow_x      = TARGET_AFFINE(1,:);
out_nii.hdr.hist.srow_y      = TARGET_AFFINE(2,:);
out_nii.hdr.hist.srow_z      = TARGET_AFFINE(3,:);

% Intensity scaling: output is already in physical units
if isfield(out_nii.hdr.dime, 'scl_slope'), out_nii.hdr.dime.scl_slope = 1; end
if isfield(out_nii.hdr.dime, 'scl_inter'), out_nii.hdr.dime.scl_inter = 0; end

% Display range (helpful for NIfTI viewers)
if isfield(out_nii.hdr.dime, 'cal_min'), out_nii.hdr.dime.cal_min = single(min(img_out(:))); end
if isfield(out_nii.hdr.dime, 'cal_max'), out_nii.hdr.dime.cal_max = single(max(img_out(:))); end

save_untouch_nii(out_nii, output_fn);

if verbose
    fprintf('\nDone.\n');
    fprintf('Output : %s\n', output_fn);
    fprintf('Dims   : [%d %d %d]  Voxels: [%.1f %.1f %.1f] mm  Origin: [%.1f %.1f %.1f] mm\n', ...
            TARGET_DIM(1),      TARGET_DIM(2),      TARGET_DIM(3),      ...
            TARGET_VOXEL(1),    TARGET_VOXEL(2),    TARGET_VOXEL(3),    ...
            TARGET_AFFINE(1,4), TARGET_AFFINE(2,4), TARGET_AFFINE(3,4));
    fprintf('=== fmri_tomni152 complete ===\n\n');
end

end  % main function


% =========================================================================
%  LOCAL HELPERS
% =========================================================================

function tf = validate_interp(x)
% VALIDATE_INTERP  Validates the 'interp' parameter.
%   Accepts numeric (0,1,2) or string ('nearest','linear','spline').
    valid_str = {'nearest', 'linear', 'spline'};
    if isnumeric(x)
        tf = ismember(x, [0 1 2]);
    elseif ischar(x) || isstring(x)
        tf = ismember(lower(char(x)), valid_str);
    else
        tf = false;
    end
end

function str = resolve_interp(x)
% RESOLVE_INTERP  Returns interpolation method as a string.
%   0 / 'nearest' → 'nearest'
%   1 / 'linear'  → 'linear'
%   2 / 'spline'  → 'spline'
    if isnumeric(x)
        methods = {'nearest', 'linear', 'spline'};
        str = methods{x + 1};
    else
        str = lower(char(x));
    end
end

function vs = expand_voxel_size(vs)
% EXPAND_VOXEL_SIZE  Expands scalar voxel size to [1x3] double row vector.
    if isscalar(vs)
        vs = repmat(double(vs), 1, 3);
    else
        vs = double(vs(:)');
    end
end

function M = qform_to_affine(hdr)
% QFORM_TO_AFFINE  Builds a 4x4 affine from NIfTI qform parameters.
%   Implements the quaternion formula from the NIfTI-1 specification:
%   https://nifti.nimh.nih.gov/nifti1/documentation
%
%   abs() is applied to pixdim(2:4) before scaling — the NIfTI spec
%   requires pixdim(2:4) to be positive; qfac in pixdim(1) encodes
%   the z-axis flip, not a negative pixdim(4).
%
%   Recommended tests before release:
%     - File with matching sform and qform (force qform path, compare)
%     - File with qform only
%     - File with qfac = -1
%     - Non-axis-aligned affine
    b = hdr.hist.quatern_b;
    c = hdr.hist.quatern_c;
    d = hdr.hist.quatern_d;
    a = sqrt(max(0, 1 - b^2 - c^2 - d^2));   % guaranteed non-negative

    qfac = hdr.dime.pixdim(1);
    if qfac == 0, qfac = 1; end               % default to +1 if unset

    dx = abs(hdr.dime.pixdim(2));             % abs: pixdim(2:4) must be > 0
    dy = abs(hdr.dime.pixdim(3));
    dz = abs(hdr.dime.pixdim(4)) * qfac;     % qfac encodes z-axis flip

    R = [ a^2+b^2-c^2-d^2,   2*(b*c-a*d),      2*(b*d+a*c);
          2*(b*c+a*d),         a^2-b^2+c^2-d^2,  2*(c*d-a*b);
          2*(b*d-a*c),         2*(c*d+a*b),       a^2-b^2-c^2+d^2 ];

    tx = hdr.hist.qoffset_x;
    ty = hdr.hist.qoffset_y;
    tz = hdr.hist.qoffset_z;

    M = [ R(1,1)*dx,  R(1,2)*dy,  R(1,3)*dz,  tx;
          R(2,1)*dx,  R(2,2)*dy,  R(2,3)*dz,  ty;
          R(3,1)*dx,  R(3,2)*dy,  R(3,3)*dz,  tz;
          0,           0,           0,           1  ];
end

function out = ifelse(cond, a, b)
% IFELSE  Inline ternary helper.
    if cond, out = a; else, out = b; end
end