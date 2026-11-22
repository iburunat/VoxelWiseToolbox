function [slices, scores] = fmri_juicyslices(data, plane, nslices, threshold, minsep)
% FMRI_JUICYSLICES  Finds the slices carrying most of a map's signal.
%
% Selects slices containing the strongest signal instead of using evenly
% spaced slices. This avoids devoting most panels to empty anatomy when the
% signal is spatially focal. The selected slices can then be displayed in
% fewer, larger panels, making the spatial pattern easier to see.
%
% Usage:
%   slices = fmri_juicyslices(data)                       % 6 axial slices
%   slices = fmri_juicyslices(data, 'coronal', 5)
%   [slices, scores] = fmri_juicyslices(data, 'all', 6, 4.14, 6)
%
% Inputs:
%   DATA      - Brain map, 228453 x 1 (vectorised) or 91 x 109 x 91.
%   PLANE     - 'axial' (default), 'coronal', 'sagittal', or 'all'. With 'all',
%               SLICES is a struct with one field per plane.
%   NSLICES   - How many slices to return. Default 6.
%   THRESHOLD - Only voxels with |value| >= THRESHOLD count towards a slice's
%               score. Default 0, meaning every finite non-zero voxel counts.
%               Pass the threshold the figure will actually use, so the slices
%               are chosen on what will be visible rather than on what is there.
%   MINSEP    - Minimum separation between selected slices, in voxels.
%               Default 4. Without it the top slices cluster around a single
%               blob and the set is nearly redundant: adjacent slices through
%               one cluster look almost identical, and the rest of the map is
%               never shown.
%
% Outputs:
%   SLICES    - Selected slice indices, ascending, suitable for passing to
%               fmri_showselectslices. For 'all', a struct with fields
%               .axial, .coronal, .sagittal.
%   SCORES    - Score of each selected slice, in the same order.
%
% HOW SLICES ARE SCORED
%   Each slice is scored by summing the absolute values of its suprathreshold
%   voxels, favouring slices with both strong and spatially extensive signal.
%
%   The highest-scoring slice is selected first, slices within MINSEP are
%   excluded, and the process is repeated. This avoids selecting closely
%   spaced slices that show largely overlapping signal.
% 
% Examples:
%   % Choose slices on the threshold the figure will use, then show them large
%   t_crit_disp = fmri_p2t(0.001, 14);            % 4.14 at df = 14
%   t_lim       = 2 * t_crit_disp;                % 8.28
%   sl          = fmri_juicyslices(t_map, 'axial', 6, t_crit_disp);
%   cmap        = fmri_divmap(256);
%   fmri_showselectslices(t_map, sl, [-t_lim t_lim], 1, 1, 1, cmap, t_crit_disp);
%
%   % All three planes at once
%   sl = fmri_juicyslices(t_map, 'all', 5, t_crit_disp);
%   disp(sl.axial); disp(sl.coronal); disp(sl.sagittal);
%
% See also: fmri_showselectslices, fmri_showselectslices_int, fmri_showslices,
%           fmri_showplanes, fmri_p2t, fmri_divmap

if nargin < 2 || isempty(plane),     plane     = 'axial'; end
if nargin < 3 || isempty(nslices),   nslices   = 6;       end
if nargin < 4 || isempty(threshold), threshold = 0;       end
if nargin < 5 || isempty(minsep),    minsep    = 4;       end

plane = lower(char(plane));
if ~ismember(plane, {'axial', 'coronal', 'sagittal', 'all'})
    error('fmri_juicyslices:badPlane', ...
        ['PLANE must be ''axial'', ''coronal'', ''sagittal'' or ''all''.\n' ...
         'Got ''%s''.'], plane);
end
if ~isscalar(nslices) || nslices < 1
    error('fmri_juicyslices:badCount', ...
        'NSLICES must be a positive scalar, got %s.', mat2str(nslices));
end

% Accept either representation.
if isvector(data) && numel(data) == 228453
    vol = fmri_vect2vol(double(data));
elseif isequal(size(data), [91 109 91])
    vol = double(data);
else
    error('fmri_juicyslices:badSize', ...
        ['DATA must be 228453 x 1 (vectorised) or 91 x 109 x 91.\n' ...
         'Got %s. Use fmri_vol2vect or fmri_vect2vol to convert.'], ...
        mat2str(size(data)));
end

vol(~isfinite(vol)) = 0;
mag = abs(vol);
mag(mag < threshold) = 0;

if ~any(mag(:))
    error('fmri_juicyslices:nothingAboveThreshold', ...
        ['No voxel reaches THRESHOLD = %g, so no slice can be chosen.\n' ...
         'The map''s maximum magnitude is %g.'], threshold, max(abs(vol(:))));
end

if strcmp(plane, 'all')
    slices = struct();
    scores = struct();
    for p = {'sagittal', 'coronal', 'axial'}
        [slices.(p{1}), scores.(p{1})] = ...
            local_pick(mag, p{1}, nslices, minsep);
    end
else
    [slices, scores] = local_pick(mag, plane, nslices, minsep);
end
end

% =========================================================================

function [sel, sc] = local_pick(mag, plane, nslices, minsep)
% Sum |value| within each slice of the requested plane.
switch plane
    case 'sagittal', prof = squeeze(sum(sum(mag, 2), 3));   % over x (dim 1)
    case 'coronal',  prof = squeeze(sum(sum(mag, 1), 3));   % over y (dim 2)
    case 'axial',    prof = squeeze(sum(sum(mag, 1), 2));   % over z (dim 3)
end
prof = prof(:);

sel = [];
avail = prof;
while numel(sel) < nslices && any(avail > 0)
    [~, k] = max(avail);
    sel(end+1) = k;                                          %#ok<AGROW>
    lo = max(1, k - minsep);  hi = min(numel(avail), k + minsep);
    avail(lo:hi) = 0;                                        % enforce spacing
end

if numel(sel) < nslices
    warning('fmri_juicyslices:tooFewSlices', ...
        ['Only %d slices could be selected in the %s plane with MINSEP = %d, ' ...
         '%d were requested.\nThe signal is confined to a narrow band; reduce ' ...
         'MINSEP or request fewer slices.'], numel(sel), plane, minsep, nslices);
end

sel = sort(sel);
sc  = prof(sel)';
end