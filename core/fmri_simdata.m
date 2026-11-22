function [X_compressed, S_3D, W_participants, svd_info, X_full, sim] = fmri_simdata(...
    n_sources, n_participants, T, TR, sigma_ratio, n_comp, phase_strength, n_network, do_plot, ...
    want_full, noise_fwhm)
% FMRI_SIMDATA  Generates simulated 3D fMRI data for testing and demonstration.
%
% Generates synthetic fMRI data: spatially smooth activation sources with
% HRF-convolved time courses, plus additive noise. It returns each
% participant's data, the source maps and time courses used to generate them,
% and SIM, which contains the known ground truth for evaluating analysis results.
%
% Each source begins as a sparse train of neural events, which is convolved
% with a canonical HRF to give the BOLD time course written into the data.
% Participants differ because each one's event train is given a different
% random jitter of its Fourier phases before that convolution.
%
% The first N_NETWORK sources (3 by default) share one time course, so together
% they act as a distributed network: some follow it directly and the rest
% follow its inverse. Read sim.design.network.sign for which is which. Every
% other source has a time course of its own, and those are made uncorrelated
% with each other after HRF convolution, so no accidental resemblance between
% them can masquerade as signal in the ground truth.
%
% Participant data are compressed with a truncated SVD and reconstructed by
% fmri_simget, vectorised (228453 x T) by default or as a 4D volume.
%
% Usage:
%   [X_compressed, S_3D, W_participants, svd_info] = fmri_simdata()
%   [X_compressed, S_3D, W_participants, svd_info, X_full, sim] = fmri_simdata(...)
%
% Inputs:
%   N_SOURCES      - Number of spatial activation sources (blobs). Default: 10.
%   N_PARTICIPANTS - Number of simulated participants. Default: 2.
%   T              - Number of time points per participant. Default: 200.
%   TR             - Repetition time in seconds. Used for HRF generation.
%                    Default: 2.
%   SIGMA_RATIO    - Controls blob smoothness as a fraction of blob radius r.
%                    sigma = r * sigma_ratio. Default: 0.5 (moderately compact).
%                    Smaller values (e.g., 0.3) give sharper blobs; larger
%                    values (e.g., 0.8) give more diffuse, spread-out blobs.
%   N_COMP         - Number of SVD components to keep. Default 0 keeps enough
%                    for 95% of the variance - but the simulated noise is full
%                    rank and holds most of it, so that is nearly all of them
%                    (177 of 200 in one default run). Set a small number to
%                    compress harder, at the cost of a coarser reconstruction.
%   PHASE_STRENGTH - How much the Fourier phases are jittered to make
%                    participants differ. Range [0,1]: 0 leaves them identical,
%                    larger values differ more, but even 1 does not make them
%                    independent; the HRF smooths much of the jitter away.
%                    Default: 0.2.
%   N_NETWORK      - How many sources share time course 1. Default: 3, and at
%                    most N_SOURCES. The last floor(N_NETWORK/3) follow its
%                    inverse; sim.design.network.sign records which. To recover
%                    the network, convolve W_participants.neural(:,1,p) with
%                    the HRF and correlate; positive sources give positive r,
%                    negative ones negative r.
%   DO_PLOT        - Display diagnostic figures (1) or suppress (0). Default: 0.
%   WANT_FULL      - Assemble the full 4D volumes (X_FULL, the fifth output)?
%                    true forces it, false suppresses it, [] (default)
%                    assembles when nargout >= 5. They cost 91*109*91*T*8
%                    bytes, about 1.4 GB per participant at T = 200, so pass
%                    false when you need SIM but not the volumes.
%   NOISE_FWHM     - Spatial smoothing applied to the additive noise, in
%                    voxels (FWHM). Default 0, which gives spatially
%                    INDEPENDENT noise - unlike real fMRI, where acquisition
%                    and registration leave the noise smooth. Set it (3 is a
%                    realistic value) when the method under test depends on
%                    spatial autocorrelation, such as cluster-extent
%                    inference. The noise SD is preserved either way.
% 
% Outputs:
%   X_COMPRESSED   - Cell array {1 x N_PARTICIPANTS} of SVD-compressed data.
%                    Each cell contains a struct with fields U, S, V.
%                    Use fmri_simget to reconstruct the data, vectorised
%                    by default.
%   S_3D           - Spatial source maps (91 x 109 x 91 x N_SOURCES).
%                    S_3D(:,:,:,k) is the k-th source's spatial map.
%   W_PARTICIPANTS - Struct with two fields:
%                    .neural (T x N_SOURCES x N_PARTICIPANTS): sparse event
%                       sequences in neural/stimulus domain.
%                    .bold   (T x N_SOURCES x N_PARTICIPANTS): HRF-convolved
%                       BOLD-domain time courses used in volume assembly.
%                    Use .neural(:,1,p) as the stimulus regressor: after HRF
%                    convolution it recovers the N_NETWORK distributed sources.
%   SVD_INFO       - Struct array (1 x N_PARTICIPANTS). XDIM, YDIM and ZDIM are
%                    the volume dimensions fmri_simget needs; S is the full
%                    singular-value matrix, kept so the variance spectrum can
%                    be inspected when choosing N_COMP.
%   X_FULL         - Cell array {1 x N_PARTICIPANTS} of full 4D volumes
%                    (91 x 109 x 91 x T). Assembly is controlled by
%                    WANT_FULL; by default it happens when nargout >= 5.
%   SIM            - Struct recording what was generated. Fields:
%                    .params  the inputs used
%                    .mask    the voxel-indexing convention
%                    .design  network indices and polarities, source centres
%                             and radii
%                    .gram    correlations between source time courses
%                    .norm    per-voxel normalising denominator
%                    .truth   expected voxel-to-source correlations,
%                             .latent and .population
%                    SIM.truth.latent(:,k) and SIM.truth.population(:,k) are
%                    correlations with source k's time course, not maps of its
%                    spatial territory.
%
% Note:
%   Data reconstructed by fmri_simget spans only N_COMP temporal components,
%   not T, so its temporal covariance is not the simulated one - markedly so at
%   small N_COMP. Treat degrees of freedom taken from T with caution, or use
%   X_FULL.
%
% Examples:
%   % Default network: 10 sources, the first 3 sharing time course 1
%   [X_comp, S_3D, W, svd_info] = fmri_simdata(10, 8, 200, 2);
%   % W.neural(:,1,1) correlates with sources 1,2,3 after HRF convolution
%
%   % Custom network size: first 5 sources share time course 1
%   [X_comp, S_3D, W, svd_info] = fmri_simdata(10, 8, 200, 2, [], [], [], 5);
%
% See also: fmri_simget, fmri_doublegamma, fmri_vol2vect, fmri_corregressor

% --- defaults -------------------------------------------------------------
if nargin < 1 || isempty(n_sources),      n_sources      = 10;  end
if nargin < 2 || isempty(n_participants), n_participants = 2;   end
if nargin < 3 || isempty(T),              T              = 200; end
if nargin < 4 || isempty(TR),             TR             = 2;   end
if nargin < 5 || isempty(sigma_ratio),    sigma_ratio    = 0.5; end
if nargin < 6 || isempty(n_comp),         n_comp         = 0;   end
if nargin < 7 || isempty(phase_strength), phase_strength = 0.2; end
if nargin < 8 || isempty(n_network),      n_network      = 3;   end
if nargin < 9 || isempty(do_plot),        do_plot        = 0;   end
if nargin < 10 || isempty(want_full),     want_full      = [];  end
if nargin < 11 || isempty(noise_fwhm),    noise_fwhm     = 0;   end

if n_network > n_sources
    error('fmri_simdata:networkTooLarge', ...
        ['N_NETWORK (%d) cannot exceed N_SOURCES (%d).\n' ...
         'The network sources are a SUBSET of the sources, not additional ones.'], ...
        n_network, n_sources);
end

% --- signal and noise amplitude -------------------------------------------
sig_amp  = 20;   % BOLD signal amplitude (consistent across all branches)
noise_sd = 2;    % additive noise SD, preserved when NOISE_FWHM smooths it

% --- fixed volume dimensions (MNI152 2mm standard) -----------------------
xdim = 91; ydim = 109; zdim = 91;

% --- load standard brain mask --------------------------------------------
load standard_brain_NZ % supplies A, the 91x109x91 binary brain mask
brain_mask = A > 0;
[bx, by, bz] = ind2sub([xdim ydim zdim], find(brain_mask));
n_brain = length(bx);
fprintf('Brain mask: %d voxels (MNI152 2mm standard)\n', n_brain);

% --- initialise outputs --------------------------------------------------
X_compressed  = cell(1, n_participants);
S_3D          = zeros(xdim, ydim, zdim, n_sources);
svd_info      = struct([]);
X_full        = cell(1, n_participants);
W_neural      = zeros(T, n_sources, n_participants);
W_bold        = zeros(T, n_sources, n_participants);

% =========================================================================
%  1. SPATIAL SOURCES — angular-noise blobs within brain mask
% =========================================================================
fprintf('Generating %d spatial source blobs (%d share time course 1)...\n', ...
        n_sources, n_network);

[Xg, Yg, Zg] = ndgrid(1:xdim, 1:ydim, 1:zdim);

size_cat    = [2 4; 4 7; 7 10; 10 13];
cat_weights = [0.4 0.3 0.2 0.1];
centers     = [];
radii       = [];   % captured for sim.design.sources (Phase 1)

for s = 1:n_sources
    cat_cdf = cumsum(cat_weights / sum(cat_weights));
    cat     = find(rand() <= cat_cdf, 1, 'first');
    r_lo    = size_cat(cat,1);
    r_hi    = size_cat(cat,2);
    r       = r_lo + (r_hi - r_lo) * rand();

    min_sep = max(12, r * 2.5);
    placed  = false;
    for attempt = 1:500
        idx = randi(n_brain);
        cx = bx(idx); cy = by(idx); cz = bz(idx);
        if isempty(centers)
            placed = true; break;
        end
        dists = sqrt((centers(:,1)-cx).^2 + (centers(:,2)-cy).^2 + (centers(:,3)-cz).^2);
        if min(dists) > min_sep
            placed = true; break;
        end
    end
    if ~placed
        idx = randi(n_brain);
        cx = bx(idx); cy = by(idx); cz = bz(idx);
    end
    centers = [centers; cx cy cz];
    radii   = [radii; r];

    dist  = sqrt((Xg-cx).^2 + (Yg-cy).^2 + (Zg-cz).^2);
    theta = atan2(Yg-cy, Xg-cx);
    phi   = atan2(sqrt((Xg-cx).^2+(Yg-cy).^2), Zg-cz);

    noise_amp = 0.3 * r;
    dist_eff  = dist + noise_amp * (sin(3*theta).*cos(2*phi) + 0.5*randn(size(dist)));
    dist_eff  = max(0, dist_eff);

    sigma = r * sigma_ratio;
    blob  = exp(-(dist_eff.^2) / (2*sigma^2));
    blob(dist > r*1.8) = 0;
    blob(~brain_mask)  = 0;
    S_3D(:,:,:,s) = blob;

    if s <= n_network
        fprintf('  Source %2d [network]: radius=%.1f voxels, center=[%d %d %d]\n', s, r, cx, cy, cz);
    else
        fprintf('  Source %2d:           radius=%.1f voxels, center=[%d %d %d]\n', s, r, cx, cy, cz);
    end
end

% =========================================================================
%  2. BASE TIME COURSES — neural domain + HRF convolution
% =========================================================================
fprintf('Generating base time courses (neural + HRF convolution, TR=%ds)...\n', TR);

hrf           = fmri_doublegamma(0:TR:30)';
W_base_neural = zeros(T, n_sources);
W_base_bold   = zeros(T, n_sources);

% Generate one neural time course per independent source
% Sources 1..n_network all share time course 1
n_independent = n_sources - n_network + 1;   % time course 1 + one per remaining blob
TC_neural     = zeros(T, n_independent);
TC_bold       = zeros(T, n_independent);

for tc = 1:n_independent
    event_rate      = 0.04 + 0.02*rand();
    events          = double(rand(T,1) < event_rate);
    neural_tc       = events + 0.2*randn(T,1);
    TC_neural(:,tc) = local_z(neural_tc);
    bold_tc         = conv(TC_neural(:,tc), hrf);
    TC_bold(:,tc)   = local_z(bold_tc(1:T));
end

% --- ORTHOGONALISE INDEPENDENT TIME COURSES -------------------------------
% Separately generated time courses can be correlated by chance. Remove these
% correlations in the BOLD domain because the simulated data are assembled
% from the HRF-convolved signals. Apply the same residualisation coefficients
% to the neural time courses to keep the neural and BOLD representations
% consistent.
%
% Time course 1 is left unchanged to preserve the network regressor. The
% remaining neural time courses may become mixtures of the original event
% sequences after orthogonalisation.

for tc = 2:n_independent
    prev_bold   = TC_bold(:, 1:tc-1);
    beta        = prev_bold \ TC_bold(:, tc);            % least squares
    TC_bold(:, tc)   = TC_bold(:, tc)   - prev_bold * beta;
    TC_neural(:, tc) = TC_neural(:, tc) - TC_neural(:, 1:tc-1) * beta;
    % The neural and BOLD time courses are z-scored separately, so their
    % convolution relationship is preserved up to a scaling factor. This does
    % not affect correlation-based analyses, which are invariant to scale.
    TC_bold(:, tc)   = local_z(TC_bold(:, tc));
    TC_neural(:, tc) = local_z(TC_neural(:, tc));
end

if n_independent > 1
    G_check = local_gram(TC_bold);
    off_max = max(abs(G_check(~eye(n_independent))));
    fprintf('  Orthogonalised: max |r| between independent time courses = %.2e\n', ...
            off_max);
end

% Assign time courses to blobs:
% blobs 1..n_network -> time course 1
% blob n_network+1   -> time course 2
% blob n_network+2   -> time course 3  ... etc.
% network blobs: assign TC1, last third negated
n_neg_network = floor(n_network/3);
n_pos_network = n_network - n_neg_network;

for s = 1:n_sources
    if s <= n_network
        if s > n_pos_network
            W_base_neural(:,s) = -TC_neural(:,1);
            W_base_bold(:,s)   = -TC_bold(:,1);
        else
            W_base_neural(:,s) =  TC_neural(:,1);
            W_base_bold(:,s)   =  TC_bold(:,1);
        end
    else
        tc_idx             = s - n_network + 1;
        W_base_neural(:,s) = TC_neural(:,tc_idx);
        W_base_bold(:,s)   = TC_bold(:,tc_idx);
    end
end

fprintf('  Network: %d positive blob%s (+TC1), %d negative blob%s (-TC1)\n', ...
        n_pos_network, repmat('s', 1, n_pos_network ~= 1), ...
        n_neg_network, repmat('s', 1, n_neg_network ~= 1));

% =========================================================================
%  3. PARTICIPANT VARIATIONS — FFT phase perturbation
% =========================================================================
fprintf('Generating %d participant variations (phase_strength=%.2f)...\n', ...
        n_participants, phase_strength);

% Perturb each participant's neural time courses independently, then convolve
% them with the HRF to generate the corresponding BOLD signals. The phase
% perturbation is not strictly spectrum preserving; use fmri_scramblephases
% when exact phase scrambling is required.
for p = 1:n_participants
    for s = 1:n_sources
        Yf  = fft(W_base_neural(:,s));
        mag = abs(Yf);
        ph  = angle(Yf) + phase_strength * randn(size(Yf));
        amp = mag * (1 + 0.1*randn());
        ts  = real(ifft(amp .* exp(1i*ph)));
        W_neural(:,s,p) = local_z(ts);

        % BOLD follows from the neural series through the same HRF used to build
        % the base, so conv(W_neural, hrf) = W_bold holds for every participant.
        bold_p        = conv(W_neural(:,s,p), hrf);
        W_bold(:,s,p) = local_z(bold_p(1:T));
    end
end


% --------- Participant similarity diagnostics  -------------------------------- %
if n_participants > 1
    fprintf('Inter-participant correlations, source 1 (BOLD domain):\n');
    r_isc = zeros(n_participants, n_participants);
    for p1 = 1:n_participants
        for p2 = 1:n_participants
            r_isc(p1,p2) = local_r(W_bold(:,1,p1), W_bold(:,1,p2));
        end
    end
    % extract upper triangle (unique pairs)
    upper = r_isc(triu(true(n_participants), 1));
    fprintf('  All pairwise: mean=%.3f, min=%.3f, max=%.3f (%d pairs)\n', ...
            mean(upper), min(upper), max(upper), length(upper));

    % print matrix
    fprintf('     ');
    for p = 1:n_participants, fprintf('  P%d  ', p); end
    fprintf('\n');
    for p1 = 1:n_participants
        fprintf('  P%d ', p1);
        for p2 = 1:n_participants
            fprintf(' %.2f ', r_isc(p1,p2));
        end
        fprintf('\n');
    end

    % plot matrix if do_plot
    if do_plot
        figure('Name', 'fmri_simdata: Inter-participant ISC');
        imagesc(r_isc, [0 1]);
        colormap(hot); colorbar;
        axis square;
        xlabel('Participant'); ylabel('Participant');
        title('Inter-participant correlations (source 1, BOLD domain)');
        xticks(1:n_participants); yticks(1:n_participants);
    end
end
% --------- Participant similarity diagnostics (end) ---------------------------- %

W_participants.neural = W_neural;
W_participants.bold   = W_bold;

% =========================================================================
%  4. ASSEMBLE VOLUMES — BOLD-domain time courses
% =======================================================================
% Control whether full 4D volumes are retained in X_FULL:
%
%   WANT_FULL = true   always retain them
%   WANT_FULL = false  do not retain them
%   WANT_FULL = []     retain them when X_FULL is requested (nargout >= 5)
%
% Pass false when requesting SIM without X_FULL, as the full volumes can
% require substantial memory. A tilde suppresses output assignment but does
% not prevent its computation.

if isempty(want_full)
    compute_full = (nargout >= 5);
else
    compute_full = logical(want_full);
end

S_2D         = reshape(S_3D, xdim*ydim*zdim, n_sources);

if compute_full
    fprintf('Assembling full 4D volumes...\n');
    for p = 1:n_participants
        X_full{p} = local_assemble(S_2D, W_bold(:,:,p), sig_amp, brain_mask(:), ...
                                  [xdim ydim zdim], noise_sd, noise_fwhm);
        fprintf('  Participant %d/%d assembled.\n', p, n_participants);
    end
else
    fprintf('Assembling volumes for compression (X_full not stored)...\n');
end

% =========================================================================
%  5. SVD COMPRESSION
% =========================================================================
if n_comp == 0
    fprintf('Compressing via SVD (auto components, 95%% variance)...\n');
else
    fprintf('Compressing via SVD (%d components)...\n', n_comp);
end

for p = 1:n_participants
    if compute_full
        Xp = X_full{p};
    else
        Xp = local_assemble(S_2D, W_bold(:,:,p), sig_amp, brain_mask(:), ...
                            [xdim ydim zdim], noise_sd, noise_fwhm);
    end

    X2D        = reshape(Xp, xdim*ydim*zdim, T);
    [U, Sv, V] = svd(X2D, 'econ');

    if n_comp == 0
        sv      = diag(Sv);
        var_exp = cumsum(sv.^2) / sum(sv.^2);
        nc      = find(var_exp >= 0.95, 1);
        fprintf('  P%d: %d components explain 95%% variance.\n', p, nc);
    else
        nc = min(n_comp, size(Sv,1));
    end

    X_compressed{p} = struct('U', U(:,1:nc), 'S', Sv(1:nc,1:nc), 'V', V(:,1:nc));

    svd_info(p).S      = Sv;
    svd_info(p).xdim   = xdim;
    svd_info(p).ydim   = ydim;
    svd_info(p).zdim   = zdim;

    fprintf('  Participant %d/%d compressed.\n', p, n_participants);
end

% =========================================================================
%  6. DIAGNOSTIC PLOTS (optional)
% =========================================================================
if do_plot
    all_blobs = max(S_3D, [], 4);
    t_vec     = (1:T)';

    figure('Name', 'fmri_simdata: Spatial Sources');
    subplot(1,3,1); imagesc(max(all_blobs,[],3));
    colormap(hot); colorbar; axis image;
    title(sprintf('Axial (max proj.) — blobs 1-%d share TC1', n_network));
    subplot(1,3,2); imagesc(squeeze(max(all_blobs,[],2))');
    colormap(hot); colorbar; axis image; title('Coronal (max projection)');
    subplot(1,3,3); imagesc(squeeze(max(all_blobs,[],1)));
    colormap(hot); colorbar; axis image; title('Sagittal (max projection)');
    sgtitle(sprintf('fmri\\_simdata: %d sources, %d share TC1', n_sources, n_network));

    figure('Name', 'fmri_simdata: Time Courses (source 1)');
    subplot(3,1,1);
    stem(t_vec, double(W_base_neural(:,1) > 0.3), 'k', 'MarkerSize', 3);
    title(sprintf('Neural TC1 (sparse events, shared by blobs 1-%d)', n_network));
    xlabel('Volume'); ylabel('Amplitude'); axis tight;

    subplot(3,1,2);
    plot(t_vec, W_base_bold(:,1), 'r', 'LineWidth', 1.5);
    title('BOLD TC1: HRF-convolved');
    xlabel('Volume'); ylabel('Amplitude'); axis tight;

    subplot(3,1,3);
    n_show = min(4, n_participants);
    cols   = lines(n_show);
    hold on;
    for p = 1:n_show
        plot(t_vec, W_bold(:,1,p), 'Color', cols(p,:), 'LineWidth', 1.2);
    end
    title('BOLD TC1 across participants');
    xlabel('Volume'); ylabel('Amplitude'); axis tight;
    legend(arrayfun(@(p) sprintf('P%d',p), 1:n_show, 'UniformOutput', false), ...
           'Location', 'best', 'FontSize', 7);
    hold off;
end

fprintf('fmri_simdata: done.\n');

% ==== SIMULATION METADATA ==================================================
% SIM records the simulation parameters, voxel convention, design and derived
% ground-truth quantities. See DESIGN_NOTE_ground_truth.md for the full
% definition of its fields.

sim = struct();

% --- simulation parameters -----------------------------------------------
% Record the input settings together with the signal and noise amplitudes,
% making each simulation self-describing. Their combined effect on expected
% correlations is represented in SIM.NORM.

sim.params = struct( ...
    'n_sources',      n_sources, ...
    'n_participants', n_participants, ...
    'T',              T, ...
    'TR',             TR, ...
    'sigma_ratio',    sigma_ratio, ...
    'n_comp',         n_comp, ...
    'phase_strength', phase_strength, ...
    'n_network',      n_network, ...
    'sig_amp',        sig_amp, ...
    'noise_sd',       noise_sd, ...
    'noise_fwhm',     noise_fwhm);

% --- brain mask and voxel indexing ---------------------------------------
% Store the brain mask that defines the row order of all vectorised maps in
% SIM, so each row can be mapped back to its voxel location.
sim.mask = struct( ...
    'dims',     [xdim ydim zdim], ...
    'logical',  brain_mask, ...
    'n_voxels', nnz(brain_mask));

% --- simulation design ---------------------------------------------------
% Store the network membership and polarity of each source so downstream
% analyses can use the simulated design without reproducing its construction.
n_neg_network = floor(n_network/3);
n_pos_network = n_network - n_neg_network;

net_sign = ones(n_network, 1);
net_sign(n_pos_network+1:n_network) = -1;

sim.design = struct();
sim.design.network = struct( ...
    'idx',  (1:n_network)', ...
    'sign', net_sign);

sim.design.sources = struct( ...
    'centre',    centers, ...
    'radius',    radii, ...
    'isnetwork', (1:n_sources)' <= n_network);

% --- source time-course correlations -------------------------------------
% G(j,k) is the correlation between the BOLD time courses of sources j and k.
% It is used to calculate how each source contributes to the expected
% voxel-to-source correlations.
%
% SIM.GRAM.LATENT contains the correlations between the unperturbed base time
% courses. SIM.GRAM.PARTICIPANT contains one correlation matrix per participant.
%
% A single participant-averaged matrix is not returned because expected
% correlations depend nonlinearly on G. They must be calculated separately
% for each participant and combined afterwards:
%
%     f(mean(G)) ~= mean(f(G))
%
% Each matrix is symmetric with ones on the diagonal.
sim.gram = struct();
sim.gram.latent = local_gram(W_base_bold);

sim.gram.participant = zeros(n_sources, n_sources, n_participants);
for p = 1:n_participants
    Gp = local_gram(W_bold(:,:,p));
    Gp = (Gp + Gp')/2;                    % enforce exact symmetry
    Gp(1:n_sources+1:end) = 1;            % exact unit diagonal
    sim.gram.participant(:,:,p) = Gp;
end

% --- voxelwise normalisation ----------------------------------------------
% SIM.NORM contains the denominator used to convert source contributions into
% expected voxel-to-source correlations:
%
%     norm(v) = sqrt(S(v,:)*G*S(v,:)' + (noise_sd/sig_amp)^2)
%     r(v,k)  = (S*G)(v,k) / norm(v)
%
% Separate values are stored for the latent design and each participant
% because the denominator depends on their respective source-correlation
% matrix. Rows follow the vectorised brain-voxel order defined by SIM.MASK.
S_brain   = S_2D(brain_mask(:), :);            % n_vox x n_sources
noise_amp = sim.params.noise_sd / sig_amp;     % sigma / a

sim.norm = struct();
sim.norm.latent = sqrt( sum((S_brain * sim.gram.latent) .* S_brain, 2) ...
                        + noise_amp^2 );

sim.norm.participant = zeros(size(S_brain,1), n_participants);
for p = 1:n_participants
    Gp = sim.gram.participant(:,:,p);
    sim.norm.participant(:,p) = sqrt( sum((S_brain * Gp) .* S_brain, 2) ...
                                      + noise_amp^2 );
end

% --- expected voxel-to-source correlations -------------------------------
% SIM.TRUTH(v,k) is the expected correlation between voxel v and source k's
% BOLD time course, accounting for source mixing and noise:
%
%     truth(v,k) = (S*G)(v,k) / norm(v)
%
% LATENT uses the base design; POPULATION pools participant-specific
% correlations in Fisher-z space. TRUTH(:,k) represents correlation with the
% source's time course, not its spatial extent; use S_3D for the latter.
sim.truth = struct();
sim.truth.latent = (S_brain * sim.gram.latent) ./ sim.norm.latent;

zacc = zeros(size(S_brain,1), n_sources);
for p = 1:n_participants
    r_p  = (S_brain * sim.gram.participant(:,:,p)) ./ sim.norm.participant(:,p);
    r_p  = min(max(r_p, -1+eps), 1-eps);     % defensive; should never bind
    zacc = zacc + atanh(r_p);
end
sim.truth.population = tanh(zacc / n_participants);
% ==== end sim (Phases 1-4) ===================================================

end

% ==== local helpers: base-MATLAB replacements for Statistics Toolbox calls ===
% zscore and corr live in the Statistics and Machine Learning Toolbox. These
% one-line equivalents are exact, not approximations, and keep fmri_simdata
% runnable on a base MATLAB installation.

function z = local_z(x)
% zscore(x) for a vector or column-wise for a matrix.
z = (x - mean(x)) ./ std(x);
end

function r = local_r(x, y)
% corr(x, y) for two vectors.
x = local_z(x(:));  y = local_z(y(:));
r = (x' * y) / (numel(x) - 1);
end

function G = local_gram(X)
% corr(X): correlation between the COLUMNS of X.
Xz = local_z(X);
G  = (Xz' * Xz) / (size(X, 1) - 1);
G  = (G + G') / 2;                      % kill floating-point asymmetry
G(1:size(G,1)+1:end) = 1;               % exact unit diagonal
end

function Xp = local_assemble(S_2D, Wp, sig_amp, mask_col, dims, noise_sd, noise_fwhm)
% One participant's 4D volume: sources x time courses, plus additive noise.
T = size(Wp, 1);
N = randn(prod(dims), T);
if noise_fwhm > 0
    N = local_smoothvol(N, dims, noise_fwhm);
    % Smoothing shrinks the variance by a large factor. Restore it, so that
    % NOISE_SD keeps its meaning and SIM.NORM's (noise_sd/sig_amp) term, which
    % defines the ground truth, stays correct.
    N = N / std(N(:));
end
X2D = (S_2D * Wp' * sig_amp + noise_sd * N) .* mask_col;
Xp  = reshape(X2D, dims(1), dims(2), dims(3), T);
end

function N = local_smoothvol(N, dims, fwhm)
% Separable 3D Gaussian smoothing of each time point, as three 1D convolutions.
sig = fwhm / sqrt(8*log(2));
kw  = ceil(3*sig);
k1  = exp(-((-kw:kw).^2) / (2*sig^2));
k1  = k1 / sum(k1);
for t = 1:size(N, 2)
    v = reshape(N(:,t), dims);
    v = convn(v, reshape(k1, [], 1, 1), 'same');
    v = convn(v, reshape(k1, 1, [], 1), 'same');
    v = convn(v, reshape(k1, 1, 1, []), 'same');
    N(:,t) = v(:);
end
end