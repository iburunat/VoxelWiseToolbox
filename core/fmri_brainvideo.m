function [frames, filename] = fmri_brainvideo(data, filename, varargin)
% FMRI_BRAINVIDEO  Creates a rotating 3D brain video from a brain map.
%
% Renders a 360-degree rotation of a brain map using fmri_show3d, capturing
% each frame. Optionally writes to an MP4 file. Supports multiple rotation
% trajectories.
%
% Usage:
%   frames = fmri_brainvideo(data)
%   frames = fmri_brainvideo(data, filename)
%   frames = fmri_brainvideo(data, filename, 'param', value, ...)
%   frames = fmri_brainvideo(data, filename, p)              % p from fmri_makevizpar
%   frames = fmri_brainvideo(data, filename, p, 'fps', 30)   % struct, then overrides
%
% Inputs:
%   DATA       - Brain map, 228453 x 1, passed straight through to
%                fmri_show3d. Several maps may be given as columns, in which
%                case COLOR needs one row per column.
%   FILENAME   - Output video path. Default: '' - frames are rendered and
%                returned, nothing is written. An extension other than .mp4
%                is replaced; see Outputs.
%
% Optional name-value parameters:
%   'nframes'    - Number of frames in a full rotation. More frames = smoother
%                  rotation. Default: 72 (5 degrees per frame, ~3 s at 25 fps)
%   'fps'        - Frames per second for output video. Default: 25.
%   'el'         - Elevation angle(s). Scalar, vector, or empty (gentle dip
%                  ~30 degrees). Default: [].
%   'climits'    - Colour axis limits [min max]. Default: [] (auto-scale).
%   'maskalpha'  - Brain shell transparency. Default: 0.05.
%   'color'      - N x 3 RGB activation colour. Default: [1 0.2 0.2] (red).
%   'level'      - Isosurface value, in the units of DATA (see fmri_show3d).
%                  Default: 0.1.
%   'trajectory' - Rotation style. Default: 'cinematic'.
%                  'cinematic' - one turn, easing in and out, with a gentle
%                                elevation dip (~30 degrees)
%                  'constant'  - one turn at constant speed
%                  'reverse'   - one turn at constant speed, clockwise
%                  'fixed'     - one turn with elevation held level (0 unless
%                                'el' is given)
%                  'figure8'   - the camera traces a figure of eight
%                  'spiral'    - two turns, rising to a high angle and back
%                  'reveal'    - one turn, lifting over the top at the rear
%                  'surgical'  - descends from top-down to lateral and back
%                  'dualpass'  - two turns, one high and one low
%
% Outputs:
%   FRAMES     - 1 x NFRAMES cell array of getframe structs, in rotation
%                order. Returned whether or not a file was written, so a
%                sequence can be re-encoded at a different frame rate without
%                re-rendering it.
%   FILENAME   - The path ACTUALLY written, which is not always the one
%                passed: a missing or wrong extension is replaced with .mp4,
%                and where MPEG-4 is unavailable the file is written as .avi
%                instead. Use this return value, not the argument, when a
%                later step needs the real path.
%
% Notes:
%   - 'el' may be a scalar (constant) or a vector, interpolated across NFRAMES
%     if the lengths differ.
%   - Total video duration = nframes / fps seconds. NFRAMES controls smoothness,
%     FPS controls playback speed.
%   - Trajectory names changed: the former 'linear' is now 'constant' and the
%     former 'flat' is now 'fixed'. The old names are NOT accepted and raise an
%     error naming the valid options.
%
% Examples:
%
%   Cinematic rotation (default)
%       fmri_brainvideo(data, 'brain.mp4', 'nframes', 300)
%
%   Constant elevation but constant speed:
%       fmri_brainvideo(data, 'brain.mp4', 'trajectory', 'constant', 'el', 30)
%
%   Reverse rotation (clockwise)
%       fmri_brainvideo(data, 'brain.mp4', 'trajectory', 'reverse')
%
%   Level rotation (elevation held constant)
%       fmri_brainvideo(data, 'brain.mp4', 'trajectory', 'fixed')
%
%   Matching a figure's display settings
%       p = fmri_makevizpar('level', 0.5, 'maskalpha', 0.1);
%       fmri_brainvideo(data, 'brain.mp4', p, 'nframes', 120)
%
% See also: fmri_show3d, fmri_showcortex, fmri_braincake, fmri_show3dhalfbrains,
%           fmri_makevizpar

% --- parse optional parameters ---
p.nframes    = 72;
p.fps        = 25;
p.el         = [];
p.climits    = [];
p.maskalpha  = 0.05;
p.color      = [1 0.2 0.2];
p.level      = 0.1;
p.trajectory = 'cinematic';


if ~isempty(varargin) && isstruct(varargin{1})
    pin         = varargin{1};
    varargin(1) = [];
    shared      = intersect(fieldnames(pin), fieldnames(p));
    for f = shared(:)'
        p.(f{1}) = pin.(f{1});
    end
end

for k = 1:2:length(varargin)
    field = lower(varargin{k});
    if isfield(p, field)
        p.(field) = varargin{k+1};
    else
        warning('fmri_brainvideo:unknownParam', 'Unknown parameter: %s', field);
    end
end

if nargin < 2, filename = ''; end

% --- rotation trajectory ---
nf = p.nframes;
t  = linspace(0,1,nf);

traj = lower(p.trajectory);


el_traj = [];      % set by trajectories that drive elevation themselves

switch traj

    case 'cinematic'   % one turn, easing in and out
        t_eased = interp1([0 0.1 0.4 0.6 0.9 1], ...
                          [0 0.065 0.475 0.525 0.935 1], ...
                          t, 'spline');
        az = 90 + 360*t_eased;

    case 'constant'    % one turn at constant speed
        az = linspace(90, 90+360, nf);

    case 'reverse'     % one turn at constant speed, opposite direction
        az = linspace(90, 90-360, nf);

    case 'fixed'       % one turn at constant speed, elevation held level
        az = linspace(90, 90+360, nf);
        if isempty(p.el), p.el = 0; end

    case 'figure8'     % camera traces a figure of eight
        az      = 90 + 120*sin(2*pi*t);
        el_traj = 25*sin(4*pi*t);

    case 'spiral'      % two turns while rising to a high angle and back
        az      = 90 + 720*t;
        el_traj = 45*sin(pi*t);

    case 'reveal'      % one turn, lifting over the top at the rear
        az      = 90 + 360*t;
        el_traj = 40*sin(pi*t).^2;

    case 'surgical'    % descends from a top-down view to the side and back
        az      = 90 + 360*t;
        % A constant near-top view shows essentially the same brain surface
        % throughout the rotation, making the motion look like a turntable spin.
        % Lowering the camera angle reveals different brain surfaces during the
        % rotation. The maximum elevation stays below 90 degrees so that the
        % rotation remains visible.
        el_traj = 20 + 58*cos(pi*t).^2;

    case 'dualpass'    % two turns, one high and one low
        az      = 90 + 720*t;
        el_traj = 35 + 25*cos(2*pi*t);

    otherwise
        error('fmri_brainvideo:unknownTrajectory', ...
              ['Unknown trajectory ''%s''. Options are: cinematic, constant, ' ...
               'reverse, fixed, figure8, spiral, reveal, surgical, dualpass.'], ...
              p.trajectory);
end

% --- elevation ---
% An explicit EL always wins; otherwise a trajectory that defines its own
% elevation path uses it, and anything else gets the default gentle dip.
if ~isempty(p.el)
    if isscalar(p.el)
        el = p.el*ones(1,nf);
    else
        el = interp1(linspace(0,1,numel(p.el)), p.el(:)', t, 'linear');
    end
elseif ~isempty(el_traj)
    el = el_traj;
else
    el = 30*sin(linspace(0,pi,nf));      % gentle dip
end


% --- render frames ---
frames = cell(1, nf);
hfig   = figure('Visible', 'on', 'Color', 'k');

% Hardware OpenGL can speed up video rendering. The function enables it when
% available and otherwise uses MATLAB's default renderer.
try
    opengl hardware                             %#ok<*OPENGL>
    set(hfig, 'Renderer', 'opengl');            %#ok<*FIGREN>
catch
    warning('fmri_brainvideo:noHardwareOpenGL', ...
            'Hardware OpenGL unavailable; rendering may be slow.');
end

for k = 1:nf
    clf(hfig);
    fmri_show3d(data, az(k), el(k), p.level, 1, p.color, p.maskalpha);
    % Reduce the default 10% margin to 5% for video frames, increasing usable
    % resolution while preventing clipping throughout the camera sweep.
    set(gca, 'Position', [0.05 0.05 0.9 0.9]);

    axis vis3d   % prevents camera rescaling jitter
    set(gca,'Projection','perspective')
    if ~isempty(p.climits)
        if exist('clim','builtin') == 5
            clim(p.climits);
        else
            caxis(p.climits);   %#ok<CAXIS>
        end
    end
    drawnow;
    frames{k} = getframe(hfig);
end

close(hfig);

% --- write MP4 video if filename given ---
if ~isempty(filename)
    if isstring(filename)
        filename = char(filename);  % convert string to char
    end
    [~,~,ext] = fileparts(filename);
    if ~strcmpi(ext, '.mp4')
        filename = [filename '.mp4'];
    end
    % MPEG-4 is unavailable on some Linux installations; fall back to AVI.
    try
        v = VideoWriter(filename, 'MPEG-4');
    catch
        filename = regexprep(filename, '\.mp4$', '.avi');
        v = VideoWriter(filename, 'Motion JPEG AVI');
        warning('fmri_brainvideo:noMPEG4', ...
                'MPEG-4 unavailable on this platform; writing %s instead.', filename);
    end
    v.FrameRate = p.fps;
    open(v);
    for k = 1:nf
        writeVideo(v, frames{k});
    end
    close(v);
    fprintf('Video written to: %s\n', filename);
end