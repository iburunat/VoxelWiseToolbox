function [cmap, ends] = fmri_divmap(n, hidden, style, midcolor)
% FMRI_DIVMAP  Diverging blue-white-red colormap for thresholded statistical maps.
%
% Builds a symmetric blue-to-red colormap in which the gradient is concentrated
% where the data will actually be visible, rather than spread evenly across a
% range half of which a display threshold hides.
%
% Usage:
%   cmap = fmri_divmap                       % 256 colours, gradient throughout
%   cmap = fmri_divmap(256, 0.5)             % middle 50% compressed (hidden band)
%   cmap = fmri_divmap(256, 0.15) % wide CLIMITS only; see the warning below.
%   cmap = fmri_divmap(256, 0.5, 'dark')     % strong values dark, not bright
%   cmap = fmri_divmap(256, 0, 'bright', [0.7 0.7 0.7])   % grey centre
%   [cmap, ends] = fmri_divmap(256)          % also return the endpoint colours
%
% Inputs:
%   N      - Number of colours. Default 256. More than 64 matters here: the
%            visible band may be a quarter of the map, so 64 colours leaves only
%            16 steps and the result bands visibly.
%   HIDDEN - Fraction of the colour range to hold flat white in the middle.
%            DEFAULT 0, AND 0 IS USUALLY RIGHT - see the warning below before
%            setting it to anything else.
%   STYLE  - 'bright' (default) or 'dark'. See the note below.
%   MIDCOLOR - RGB triple for the centre of the map. Default [1 1 1], white.
%
%            The centre colour is particularly important for surface
%            renderings. In slice views, values near zero are usually hidden
%            by the display threshold. On cortical surfaces, however, most
%            of the cortex is unactivated and therefore takes the centre
%            colour. White produces a bright surface, while [0.7 0.7 0.7]
%            gives a neutral grey that blends better with the anatomical
%            background, often making it preferable for fmri_showcortex
%            and fmri_braincake.
% 
% Outputs:
%   CMAP   - N x 3 colormap.
%   ENDS   - 2 x 3 matrix, [positive_extreme; negative_extreme]. Useful for
%            flat-colour renderers such as fmri_show3d, which take one RGB per
%            data column rather than a colormap: passing ENDS keeps a 3D panel
%            consistent with the slice panels beside it.
%
% Examples:
%   t_crit_disp = fmri_p2t(0.001, 14);       % 4.14 at df = 14
%   t_lim       = 2 * t_crit_disp;           % 8.28
%   cmap        = fmri_divmap(256);          % HIDDEN = 0, the usual choice
%   fmri_showslices(t_map, 1, 2, [-t_lim t_lim], [], [], 1, cmap, t_crit_disp);
%
%   % a 3D panel in the same colours: ENDS(1,:) is the red end, matching
%   % column 1 of [t_map -t_map]
%   [cmap, ends] = fmri_divmap(256);
%   fmri_show3d([t_map -t_map], 40, 15, t_crit_disp, [], ends);
%
% Notes:
%   Leave HIDDEN at zero in most cases. With the usual CLIMITS of
%   [-2*THRESHOLD, 2*THRESHOLD], the visible colour range already provides
%   a good gradient. Setting HIDDEN too high can make weak suprathreshold
%   voxels white and therefore difficult to see against the anatomical
%   background. Use HIDDEN only when CLIMITS is much wider than the
%   threshold, and keep it below THRESHOLD/CLIMITS(2).
%
%   The default 'bright' style keeps strong effects visible against both
%   dark backgrounds and greyscale anatomy. The alternative 'dark' style
%   has darker endpoints, similar to jet, but can make strong effects
%   harder to see on dark backgrounds.
%
%   Unlike jet, this map avoids abrupt perceptual transitions and the
%   green-yellow range, which can create misleading visual boundaries
%   and be difficult to interpret for people with red-green colour
%   blindness.
%
% See also: fmri_makecmap, fmri_showslices, fmri_showselectslices, fmri_p2t,
%           fmri_juicyslices, fmri_colorbar

if nargin < 1 || isempty(n),      n      = 256;      end
if nargin < 2 || isempty(hidden), hidden = 0;        end
if nargin < 3 || isempty(style),  style  = 'bright'; end
if nargin < 4 || isempty(midcolor), midcolor = [1 1 1]; end
if ~isnumeric(midcolor) || numel(midcolor) ~= 3 || any(midcolor < 0) || any(midcolor > 1)
    error('fmri_divmap:badMidColor', ...
        'MIDCOLOR must be an RGB triple in [0, 1], got %s.', mat2str(midcolor));
end
midcolor = midcolor(:)';

if ~isscalar(n) || n < 8
    error('fmri_divmap:badN', 'N must be a scalar of at least 8, got %s.', mat2str(n));
end
if ~isscalar(hidden) || hidden < 0 || hidden >= 1
    error('fmri_divmap:badHidden', ...
        ['HIDDEN must be in [0, 1), got %s.\n' ...
         'It is THRESHOLD / CLIMITS(2) - the fraction of the colour range that ' ...
         'the display\nthreshold suppresses.'], mat2str(hidden));
end
style = lower(char(style));
if ~ismember(style, {'bright', 'dark'})
    error('fmri_divmap:badStyle', ...
        'STYLE must be ''bright'' or ''dark'', got ''%s''.', style);
end

n = round(n);

% Anchor colours, from the negative extreme to the positive extreme.
switch style
    case 'bright'
        neg_end = [0.00 0.15 0.75];    % saturated blue
        neg_mid = [0.45 0.70 1.00];    % light blue
        pos_mid = [1.00 0.60 0.45];    % light red
        pos_end = [0.80 0.05 0.05];    % saturated red
    case 'dark'
        neg_end = [0.00 0.00 0.50];    % jet's dark blue
        neg_mid = [0.00 0.55 1.00];
        pos_mid = [1.00 0.40 0.00];
        pos_end = [0.50 0.00 0.00];    % jet's dark red
end
mid = midcolor;     % centre of the map; see MIDCOLOR above

% Anchor positions along [0, 1].
%
% The point of HIDDEN is to give the VISIBLE bands the full colour ramp. The
% band the threshold suppresses runs from (1-hidden)/2 to (1+hidden)/2, so the
% visible bands are [0, (1-hidden)/2] and [(1+hidden)/2, 1]. Each of those must
% carry the whole ramp from a saturated endpoint through to white.
%
% An earlier version placed the light anchors AT the edges of the hidden band,
% so the visible band ramped only from saturated to light - half the available
% range - and at hidden = 0.5 the anchor positions coincided exactly with even
% spacing, making the parameter appear to do nothing. It held the light colours
% where they could be seen and the white where it could not; the correct
% arrangement is the reverse.
edge = (1 - hidden) / 2;

if hidden <= 0
    pos     = [0, 0.25, 0.5, 0.75, 1];
    anchors = [neg_end; neg_mid; mid; pos_mid; pos_end];
else
    % Saturated at the extremes, light at mid-band, white by the edge of the
    % suppressed region, then flat white across it.
    pos     = [0, edge/2, edge, 1-edge, 1-edge/2, 1];
    anchors = [neg_end; neg_mid; mid; mid; pos_mid; pos_end];
end

% Delegates the interpolation to fmri_makecmap, so anchors-to-colormap is
% implemented once in the toolbox rather than here and in fmri_braincake.
cmap = fmri_makecmap(anchors, pos, n);
ends = [pos_end; neg_end];
end