function [rho, p, stats] = fmri_rsa(data, model_rdm, varargin)
% FMRI_RSA  Representational similarity analysis of a set of condition maps.
%
% Compares the dissimilarity structure of a set of brain maps with the
% structure a model predicts. A neural RDM is built from the condition maps, or
% supplied ready-made, and the upper triangles of the two RDMs are correlated
% to give a single scalar for the whole set, not a voxelwise map. Set 'nperm'
% above zero for the calibrated permutation test.
%
% Usage:
%   rho                  = fmri_rsa(data, model_rdm)
%   [rho, p]             = fmri_rsa(data, model_rdm)
%   [rho, p, stats]      = fmri_rsa(data, model_rdm, 'nperm', 5000)
%   [rho, p, stats]      = fmri_rsa(data, model_rdm, 'method', 'spearman')
%
% Inputs:
%   DATA      - 228453 x N matrix (one map per condition/stimulus), from which
%               the neural RDM is computed as 1 - fmri_corrmat(data), OR a
%               pre-computed N x N neural RDM. A square input that is not
%               228453 rows is treated as a pre-computed RDM; if you have an
%               ROI dataset that happens to be square (n_voxels equals
%               n_conditions), compute the RDM yourself and pass it, to avoid
%               the ambiguity.
%   MODEL_RDM - N x N model RDM (dissimilarity matrix)
%               Values should be dissimilarities (larger = more dissimilar)
%
% Optional (name-value pairs):
%   'method'  - 'spearman' (default) or 'pearson'
%   'nperm'   - number of permutations for p-value (default: 0)
%   'tail'    - 'right' (default), 'left', or 'both'
%
% Outputs:
%   RHO       - scalar correlation between the neural and model RDMs (Spearman
%               or Pearson). This compares whole RDMs; it is not a voxelwise or
%               searchlight map.
%   P         - p-value. Permutation-based if NPERM > 0 (recommended), else an
%               analytic t-test that is ONLY valid as a rough guide (see note).
%   STATS     - struct with fields:
%                 .z        : Fisher z-score
%                 .null     : null distribution (if nperm > 0)
%                 .method   : method used
%                 .nperm    : number of permutations run
%                 .df       : N*(N-1)/2 - 2, the degrees of freedom of the
%                             analytic t-test. Reported for transparency; it
%                             is the quantity the independence assumption
%                             above overstates, so it is not a usable error
%                             estimate for the permutation result.
%
% Description:
%   If DATA contains condition maps (228453 x N), the neural RDM is computed
%   as correlation distance: 1 - fmri_corrmat(data). An N x N input is treated
%   as a pre-computed neural RDM.
%
%   The neural and model RDMs are compared using their upper triangles,
%   excluding the diagonal. Spearman correlation is used by default.
%
%   For significance testing, use NPERM > 0. RDM entries are not independent
%   because each condition contributes to several dissimilarities, making the
%   analytic p-value potentially too small. The permutation test preserves the
%   RDM structure by shuffling condition labels in the model RDM. The analytic
%   p-value is retained only as a quick approximation and produces a warning.
%
% Examples:
%   % Basic RSA from condition maps
%   model_rdm  = 1 - fmri_corrmat(feature_matrix');   % N x N model dissimilarity
%   [rho, p]   = fmri_rsa(data, model_rdm)
%
%   % RSA with permutation testing
%   [rho, p, stats] = fmri_rsa(data, model_rdm, 'nperm', 5000)
%
%   % Using pre-computed neural RDM
%   neural_rdm = 1 - fmri_corrmat(data);
%   [rho, p]   = fmri_rsa(neural_rdm, model_rdm)
%
% References:
%   Kriegeskorte, N., Mur, M. & Bandettini, P. (2008). Representational
%   similarity analysis - connecting the branches of systems neuroscience.
%   Frontiers in Systems Neuroscience, 2, 4.
%   Nili, H., Wingfield, C., Walther, A., Su, L., Marslen-Wilson, W. &
%   Kriegeskorte, N. (2014). A toolbox for representational similarity analysis.
%   PLoS Computational Biology, 10(4), e1003553.
%
% See also: fmri_corrmat, fmri_corregressor, fmri_isc

persistent warned_analytic

%% parse optional arguments
p_args   = inputParser;
addParameter(p_args, 'method', 'spearman');
addParameter(p_args, 'nperm',  0);
addParameter(p_args, 'tail',   'right');
parse(p_args, varargin{:});
method = p_args.Results.method;
nperm  = p_args.Results.nperm;
tail   = p_args.Results.tail;

%% build neural RDM if raw data provided
[nr, nc] = size(data);
if nr == nc && nr > 1 && nc > 1 && nr ~= 228453
    % assume pre-computed N x N RDM
    neural_rdm = data;
else
    % compute correlation-distance RDM from 228453 x N data
    neural_rdm = 1 - fmri_corrmat(data);   % N x N
end

% validate model RDM
if ~isequal(size(model_rdm), size(neural_rdm))
    error('fmri_rsa:rdmSizeMismatch', ...
        ['MODEL_RDM and the neural RDM must be the same size.\n' ...
         'Got %s and %s. Both must be nConditions x nConditions.'], ...
        mat2str(size(model_rdm)), mat2str(size(neural_rdm)));
end

N = size(neural_rdm, 1);

%% extract upper triangle (excluding diagonal)
mask          = logical(triu(ones(N), 1));
neural_vec    = neural_rdm(mask);
model_vec     = model_rdm(mask);

%% compute observed correlation
rho = rdm_corr(neural_vec, model_vec, method);

%% analytic p-value
df    = length(neural_vec) - 2;
t_obs = rho * sqrt(df) / sqrt(1 - rho^2 + eps);
switch tail
    case 'right', p_analytic = 1 - local_tcdf(t_obs, df);
    case 'left',  p_analytic = local_tcdf(t_obs, df);
    case 'both',  p_analytic = 2 * (1 - local_tcdf(abs(t_obs), df));
end

%% permutation testing
if nperm > 0
    null = zeros(nperm, 1);
    for k = 1:nperm
        idx          = randperm(N);
        rdm_perm     = model_rdm(idx, idx);
        null(k)      = rdm_corr(neural_vec, rdm_perm(mask), method);
    end
    % +1 correction so a permutation p-value is never exactly 0.
    switch tail
        case 'right', p = (1 + sum(null >= rho))      / (1 + nperm);
        case 'left',  p = (1 + sum(null <= rho))      / (1 + nperm);
        case 'both',  p = (1 + sum(abs(null) >= abs(rho))) / (1 + nperm);
    end
else
    if isempty(warned_analytic)
        warning('fmri_rsa:analyticP', ...
                ['Returning the analytic t-test p-value. It treats the ' ...
                 'N*(N-1)/2 RDM entries as independent, but each condition ' ...
                 'appears in N-2 of them, so they are not.\n' ...
                 'The returned p is therefore too small, and the ' ...
                 'false-positive rate exceeds the nominal error rate, ' ...
                 'increasingly so for smooth or strongly structured RDMs ' ...
                 '(single digits to low-teens percent at nominal 5%% in ' ...
                 'simulation). Set ''nperm'' > 0 for the calibrated ' ...
                 'permutation test (Nili et al. 2014).\n' ...
                 '(This warning is shown once per session.)']);
        warned_analytic = true;
    end
    p    = p_analytic;
    null = [];
end

%% output stats struct
stats.z       = atanh(rho);
stats.null    = null;
stats.method  = method;
stats.nperm   = nperm;
stats.df      = df;

end % main

%% helper
function r = rdm_corr(x, y, method)
switch lower(method)
    case 'spearman'
        % Spearman is Pearson on ranks. corr(...,'Spearman') and tiedrank are
        % both Statistics Toolbox, so ranks are computed using
        % tiedrank_local.
        r = local_pearson(tiedrank_local(x(:)), tiedrank_local(y(:)));
    case 'pearson'
        r = local_pearson(x(:), y(:));
    otherwise
        error('fmri_rsa:badMethod', ...
            'METHOD must be ''spearman'' or ''pearson''. Got ''%s''.', method);
end
end

% ==== local helpers: base-MATLAB replacements for Statistics Toolbox calls ===
% corr, tiedrank and tcdf all live in the Statistics and Machine Learning
% Toolbox. The replacements below are exact: Spearman is Pearson on ranks, and
% the t CDF follows from the regularised incomplete beta function, which is
% base MATLAB.

function r = local_pearson(x, y)
% corr(x, y) for two vectors.
x = x(:) - mean(x);  y = y(:) - mean(y);
r = (x' * y) / sqrt((x' * x) * (y' * y));
end

function p = local_tcdf(t, df)
% tcdf(t, df): Student's t CDF via the regularised incomplete beta function.
%   For t >= 0 : 1 - 0.5*I_{df/(df+t^2)}(df/2, 1/2)
%   For t <  0 :     0.5*I_{df/(df+t^2)}(df/2, 1/2)
% betainc is base MATLAB. The split by sign is required because the identity
% is written for the upper tail; applying it unsigned would return the wrong
% tail for negative t.
t = double(t);
x = df ./ (df + t.^2);
ib = betainc(x, df/2, 0.5);
p = zeros(size(t));
pos = t >= 0;
p(pos)  = 1 - 0.5 * ib(pos);
p(~pos) =     0.5 * ib(~pos);
end