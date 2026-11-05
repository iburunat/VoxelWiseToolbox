function rsn_compare_demo(r_map, n_surr, atlas_path)
% RSN_COMPARE_DEMO  Compare a statistical map against canonical resting-state
% networks, as an add-on to the StudyForrest demos.
%
% Usage:
%   rsn_compare_demo(r_map)
%   rsn_compare_demo(r_map, n_surr)
%   rsn_compare_demo(r_map, n_surr, '/path/to/atlases/restingstatenets.mat')
%
% Inputs:
%   R_MAP      - Voxelwise correlation map (228453 x 1), unthresholded.
%   N_SURR     - Number of spatial surrogates for the optional permutation test.
%                0 (default) reports the descriptive ranking only; a few hundred
%                to 1000 adds an empirical, autocorrelation-aware p-value.
%   ATLAS_PATH - Optional path to restingstatenets.mat, containing NETS
%                (228453 x 10) and NETNAME (1 x 10 cell). Default:
%                'atlases/restingstatenets.mat'.
%
% The ten networks are the well-matched maps of Smith et al. (2009), PNAS
% 106:13040, distributed at https://www.fmrib.ox.ac.uk/datasets/brainmap+rsns
% Comparing a task/regressor map to these components is a standard descriptive
% analysis: the question is whether the spatial distribution of the response
% resembles that of a canonical network, which is exactly the comparison Smith
% et al. used to match task co-activation patterns to resting-state networks.
%
% EVERY CORRELATION IS COMPUTED WITH fmri_corrmat
%
% fmri_corrmat correlates every column of its first argument with every column
% of its second, so one call replaces a loop over the ten networks and returns
% the whole row at once. The toolbox function is used rather than corr() from
% the Statistics and Machine Learning Toolbox: the arithmetic is identical
% (centre each column, normalise to unit norm, take the inner product), and the
% point of these demos is that a complete published analysis runs on base
% MATLAB plus this toolbox and nothing else.
%
% POSITIVE AND NEGATIVE ARE RANKED SEPARATELY
%
% A map with effects of both signs cannot be compared to a network as a whole:
% the two directions partly cancel. The positive (increasing) and negative
% (decreasing) halves are therefore correlated with the networks separately, so
% the two questions -- which networks increase, which decrease with the
% regressor -- stay distinct.
%
% RANKING METRIC: |r|, WITH THE SIGNED r SHOWN
%
% Each half-map is correlated with the SIGNED network component, and the ranking
% uses the ABSOLUTE correlation. The absolute value is taken on the CORRELATION,
% never on the network map: an ICA component is a signed spatial pattern whose
% relative polarity (which regions are the positive vs negative lobe) is part of
% its structure, so abs(net) would create a different map. What is arbitrary is
% only the component's GLOBAL sign -- a component and its negation are the same
% decomposition -- and abs(r) removes exactly that global flip while leaving the
% component intact. The signed r is printed alongside so the reader can see which
% lobe the response aligned with.
%
% Note that ranking by |r| and plotting by signed r give different orders: a
% strongly negative correlation ranks high here but sits at the bottom of a
% signed bar chart. Any figure or text describing this output must say which
% ordering it is using.
%
% SIGNIFICANCE
%
% A parametric p-value is invalid here: brain maps are spatially smooth, so
% their correlation has a far wider null than the independent-samples formula
% assumes (two independent smoothed maps of this size reach |r| = 0.08 about 5%
% of the time, which a parametric test would call p < 1e-100). With N_SURR > 0
% the function instead builds a null that preserves spatial smoothness: it
% phase-randomises R_MAP in 3-D (fmri_scramblephases, which keeps the spatial
% power spectrum and hence the autocorrelation) and correlates each surrogate
% with the FIXED network. The RSN is never randomised -- the null must break the
% specific correspondence while preserving each map's smoothness, so only the
% analysed map is surrogated. The empirical p is the fraction of surrogate |r|
% at least as large as observed, and across the ten networks the p-values are
% FDR-corrected (Benjamini-Hochberg).
%
% This phase-randomisation null is an approximation: it preserves second-order
% spatial structure but assumes an approximately stationary, Gaussian field.
% Variogram-matching methods (e.g. BrainSMASH) model the autocorrelation more
% directly and are preferable for a publication result.
%
% See also: fmri_corrmat, fmri_scramblephases, fmri_vect2vol, fmri_vol2vect

if nargin < 2 || isempty(n_surr),    n_surr = 0;                                    end
if nargin < 3 || isempty(atlas_path), atlas_path = fullfile(fileparts(which('fmritoolbox_setup')), 'atlases', 'restingstatenets.mat'); end

S = load(atlas_path);
if ~isfield(S, 'nets') || ~isfield(S, 'netname')
    error('rsn_compare_demo:badAtlas', ...
          ['%s must contain NETS (228453 x 10) and NETNAME (1 x 10 cell).\n' ...
           'Check the atlases folder.'], atlas_path);
end
nets    = S.nets;
netname = S.netname;

if size(nets, 1) ~= numel(r_map)
    error('rsn_compare_demo:sizeMismatch', ...
          'NETS has %d voxels but R_MAP has %d; both must be on the 228453 grid.', ...
          size(nets, 1), numel(r_map));
end

valid = isfinite(r_map) & r_map ~= 0;

r_pos = r_map;  r_pos(r_pos < 0) = 0;
r_neg = -r_map; r_neg(r_neg < 0) = 0;

fprintf('\nCorrespondence with canonical resting-state networks\n');
fprintf('(Smith et al. 2009; %d networks, %d usable voxels)\n', ...
        size(nets, 2), sum(valid));
if n_surr > 0
    fprintf('Empirical p from %d spatial surrogates, FDR-corrected.\n', n_surr);
end

report_ranking('Networks INCREASING with the regressor', r_pos, nets, netname, ...
               valid, n_surr);
report_ranking('Networks DECREASING with the regressor', r_neg, nets, netname, ...
               valid, n_surr);

if n_surr == 0
    fprintf(['\nRankings are descriptive (no p-value) and are sorted by |r|.\n' ...
             'Pass N_SURR > 0 for an empirical, autocorrelation-aware test;\n' ...
             'see the header.\n']);
end
end


function report_ranking(heading, half_map, nets, netname, valid, n_surr)
% Rank networks by |spatial correlation| with one signed half of the map.
nNet = size(nets, 2);

% One fmri_corrmat call, not a loop over networks: it correlates the single
% column of the half-map against every column of NETS and returns a 1 x nNet
% row directly.
sr = fmri_corrmat(half_map(valid), nets(valid, :))';

pval = nan(nNet, 1);
if n_surr > 0
    % Null: surrogate the analysed half-map in 3-D, keep each network fixed.
    % One fmri_corrmat call per surrogate fills a whole row of r_null.
    r_null = zeros(n_surr, nNet);
    for s = 1:n_surr
        surr_vol    = fmri_scramblephases(fmri_vect2vol(half_map));
        surr        = fmri_vol2vect(surr_vol);
        r_null(s,:) = fmri_corrmat(surr(valid), nets(valid, :));
    end
    for k = 1:nNet
        pval(k) = mean(abs(r_null(:, k)) >= abs(sr(k)));
    end
    pval = bh_fdr(pval);
end

[~, order] = sort(abs(sr), 'descend');

fprintf('\n%s:\n', heading);
if n_surr > 0
    fprintf('  %-28s %8s %10s\n', 'network', 'r', 'p (FDR)');
    fprintf('  %s\n', repmat('-', 1, 50));
    for rank = 1:nNet
        k = order(rank);
        fprintf('  %-28s %+8.3f %10.3f\n', netname{k}, sr(k), pval(k));
    end
else
    fprintf('%s\n', repmat('-', 1, 46));
    for rank = 1:nNet
        k = order(rank);
        fprintf('  %2d. %-28s r = %+6.3f\n', rank, netname{k}, sr(k));
    end
end
end


function q = bh_fdr(p)
% Benjamini-Hochberg FDR-adjusted p-values.
p = p(:);
m = numel(p);
[ps, ix] = sort(p);
q_sorted = ps .* m ./ (1:m)';
q_sorted = min(1, flipud(cummin(flipud(q_sorted))));   % enforce monotonicity
q = zeros(m, 1);
q(ix) = q_sorted;
end
