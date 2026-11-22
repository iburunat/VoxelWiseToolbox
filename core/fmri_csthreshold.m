function [CSIZE, report, CS_table] = fmri_csthreshold(D, si_alpha, cs_alpha)
% FMRI_CSTHRESHOLD  Extracts critical cluster sizes from a CS distribution.
%
% Given a cluster-size (CS) null distribution (from fmri_csdist), extracts
% the critical cluster size at one or more family-wise error rate (FWER) levels.
% This is the third and final step of the Ledberg et al. (1998) procedure.
%
% Usage:
%   [CSIZE, report] = fmri_csthreshold(D, si_alpha, cs_alpha)
%
% Inputs:
%   D         - CS distribution cell array {1 x R}, as returned by fmri_csdist.
%   SI_ALPHA  - Statistical image alpha levels used to generate D (per tail;
%               see fmri_csdist). Default: [0.01 0.001 0.0001]
%   CS_ALPHA  - FWER alpha level(s) for cluster-size thresholding.
%               Default: [0.05 0.01 0.001]
%
% Outputs:
%   CSIZE     - Cell array {1 x R}. Each cell is a
%               (length(SI_ALPHA) x length(CS_ALPHA)) matrix of MINIMUM
%               SURVIVING cluster sizes: a cluster of at least the returned
%               size survives correction, which is the convention
%               fmri_cleanclusters and fmri_findclusters compare with >=.
%   REPORT    - Formatted string summarising the critical cluster sizes,
%               suitable for printing (disp(report)) or saving to a file.
%   CS_TABLE  - Cell array {1 x R}, one table per regressor. Rows are SI alpha
%               levels and columns are FWER alpha levels, named CS_FWER_0_05,
%               CS_FWER_0_01 and so on, with a leading SI_alpha column giving
%               the statistical-image thresholds. CS_TABLE{1} is the table for
%               regressor #1. Built only when a third output is requested.
%
% Examples:
%   % Full pipeline
%   acf   = fmri_acfestimate(datapath, regressor, 10);
%   D     = fmri_csdist(acf, [0.001 0.0001], 1000);
%   [CS, report] = fmri_csthreshold(D, [0.001 0.0001], [0.05 0.01]);
%   disp(report)
%
%   % Apply the threshold to a z-map. 0.001 is the per-tail alpha and both
%   % tails are taken, matching how fmri_csdist formed the null clusters.
%   z_thresh = abs(zmap) > fmri_p2t(0.001, 1e6, 1);
%   clean    = fmri_cleanclusters(z_thresh, CS{1}(1,1), 0);
%
% References:
%   Ledberg, A., Akerman, S., & Roland, P.E. (1998). NeuroImage, 8, 113-128.
%
% See also: fmri_acfestimate, fmri_csdist, fmri_cleanclusters, fmri_tfce

if nargin < 3 || isempty(cs_alpha), cs_alpha = [0.05 0.01 0.001];     end
if nargin < 2 || isempty(si_alpha), si_alpha = [0.01 0.001 0.0001];   end

% D's columns are in the SI_ALPHA order given to fmri_csdist. If the two
% disagree, the thresholds below would be read from the wrong columns and
% labelled with the wrong alpha, with no error.
ncol = cellfun(@(d) size(d, 2), D);
if any(ncol ~= numel(si_alpha))
    error('fmri_csthreshold:alphaMismatch', ...
        ['D has %s columns but SI_ALPHA has %d entries.\n' ...
         'Pass the same SI_ALPHA that generated D with fmri_csdist.'], ...
        mat2str(ncol), numel(si_alpha));
end

R     = numel(D);
CSIZE    = cell(1, R);
CS_table = cell(1, R);

for r = 1:R
    nrows  = size(D{r}, 1);
    csizes = zeros(length(si_alpha), length(cs_alpha));
    for zi = 1:length(si_alpha)
        col = D{r}(:, zi);
        for ci = 1:length(cs_alpha)
            % CSIZE is the MINIMUM SURVIVING cluster size: a cluster of this size or
            % larger is significant at CS_ALPHA. D(k) = P(max null cluster > k), so the
            % smallest s with P(max >= s) = D(s-1) < CS_ALPHA is sum(D >= CS_ALPHA) + 2.
            n_at_or_above = sum(col >= cs_alpha(ci));
            csizes(zi,ci) = n_at_or_above + 2;

            if n_at_or_above >= nrows
                warning('fmri_csthreshold:saturated', ...
                    ['Regressor %d, SI alpha %g, FWER %g: the null ' ...
                    'distribution never falls below the FWER level ' ...
                    'within its %d tabulated sizes.\n' ...
                    'The returned minimum surviving size is a lower bound, not ' ...
                    'the true critical size. Use a stricter SI alpha.'], ...
                    r, si_alpha(zi), cs_alpha(ci), nrows);
            end
        end
    end
    CSIZE{r} = csizes;
end

% --- readable table per regressor, only if requested ------------------
% Names are built with sprintf rather than string(), because MATLAB renders
% small values in exponential form (string(0.00001) is "1e-05") and the
% resulting name would contain a hyphen, which array2table rejects.
if nargout >= 3
    names = arrayfun(@(a) matlab.lang.makeValidName(sprintf('CS_FWER_%g', a)), ...
                     cs_alpha, 'UniformOutput', false);
    names = matlab.lang.makeUniqueStrings(names);
    for r = 1:R
        T = array2table(CSIZE{r}, 'VariableNames', names);
        T.SI_alpha = si_alpha(:);
        CS_table{r} = movevars(T, 'SI_alpha', 'Before', 1);
    end
end

% --- build report string ----------------------------------------------
report = sprintf('=== CRITICAL CLUSTER SIZES ===\n');
report = [report sprintf('CS FWER alpha: %s\n\n', num2str(cs_alpha))];
for r = 1:R
    report = [report sprintf('Regressor #%d\n', r)]; %#ok<AGROW>
    report = [report sprintf('  SI alpha\t%s\n', strjoin(arrayfun(@num2str,cs_alpha,'uni',0),'\t'))];
    for zi = 1:length(si_alpha)
        report = [report sprintf('  %.4f  \t%s\n', si_alpha(zi), ...
            strjoin(arrayfun(@num2str, CSIZE{r}(zi,:),'uni',0), '\t'))]; %#ok<AGROW>
    end
    report = [report sprintf('\n')]; %#ok<AGROW>
end