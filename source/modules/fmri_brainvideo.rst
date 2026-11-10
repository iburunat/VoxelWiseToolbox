fmri_brainvideo
===============

Creates a rotating 3D brain video from a brain map.

Description
-----------

Renders a 360-degree rotation of a brain map using fmri_show3d, capturing each frame. Optionally writes to an MP4 file. Supports multiple rotation trajectories.

Usage
-----

.. code-block:: matlab

   frames = fmri_brainvideo(data)
   frames = fmri_brainvideo(data, filename)
   frames = fmri_brainvideo(data, filename, 'param', value, ...)
   frames = fmri_brainvideo(data, filename, p)              % p from fmri_makevizpar
   frames = fmri_brainvideo(data, filename, p, 'fps', 30)   % struct, then overrides

Inputs
------

- **DATA** -- Brain map, 228453 x 1, passed straight through to fmri_show3d. Several maps may be given as columns, in which case COLOR needs one row per column.
- **FILENAME** -- Output video path. Default: '' - frames are rendered and returned, nothing is written. An extension other than .mp4 is replaced; see Outputs.

*name-value parameters*

- **'nframes'** -- Number of frames in a full rotation. More frames = smoother rotation. Default: 72 (5 degrees per frame, ~3 s at 25 fps)
- **'fps'** -- Frames per second for output video. Default: 25.
- **'el'** -- Elevation angle(s). Scalar, vector, or empty (gentle dip ~30 degrees). Default: [].
- **'climits'** -- Colour axis limits [min max]. Default: [] (auto-scale).
- **'maskalpha'** -- Brain shell transparency. Default: 0.05.
- **'color'** -- N x 3 RGB activation colour. Default: [1 0.2 0.2] (red).
- **'level'** -- Isosurface threshold. Default: 0.9.
- **'trajectory'** -- Rotation style. Default: 'cinematic'.

  - **'cinematic'** -- one turn, easing in and out, with a gentle elevation dip (~30 degrees)
  - **'constant'** -- one turn at constant speed
  - **'reverse'** -- one turn at constant speed, clockwise
  - **'fixed'** -- one turn with elevation held level (0 unless 'el' is given)
  - **'figure8'** -- the camera traces a figure of eight
  - **'spiral'** -- two turns, rising to a high angle and back
  - **'reveal'** -- one turn, lifting over the top at the rear
  - **'surgical'** -- descends from top-down to lateral and back
  - **'dualpass'** -- two turns, one high and one low

A parameter struct from fmri_makevizpar may be given as the first option, so that a video can carry the same display settings as the still figures it accompanies. Only the fields this function recognises are taken - level, color, maskalpha, climits, el - and an explicit name-value pair after the struct still wins over it.

Outputs
-------

- **FRAMES** -- 1 x NFRAMES cell array of getframe structs, in rotation order. Returned whether or not a file was written, so a sequence can be re-encoded at a different frame rate without re-rendering it.
- **FILENAME** -- The path ACTUALLY written, which is not always the one passed: a missing or wrong extension is replaced with .mp4, and where MPEG-4 is unavailable the file is written as .avi instead. Use this return value, not the argument, when a later step needs the real path.

Examples
--------

.. code-block:: matlab

   Cinematic rotation (default)
       fmri_brainvideo(data, 'brain.mp4', 'nframes', 300)

   Constant elevation but constant speed:
       fmri_brainvideo(data, 'brain.mp4', 'trajectory', 'constant', 'el', 30)

   Reverse rotation (clockwise)
       fmri_brainvideo(data, 'brain.mp4', 'trajectory', 'reverse')

   Level rotation (elevation held constant)
       fmri_brainvideo(data, 'brain.mp4', 'trajectory', 'fixed')

   Matching a figure's display settings
       p = fmri_makevizpar('level', 0.5, 'maskalpha', 0.1);
       fmri_brainvideo(data, 'brain.mp4', p, 'nframes', 120)

Notes
-----

- 'el' may be a scalar (constant) or a vector, interpolated across NFRAMES if the lengths differ.
- Total video duration = nframes / fps seconds. NFRAMES controls smoothness, FPS controls playback speed.
- Trajectory names changed: the former 'linear' is now 'constant' and the former 'flat' is now 'fixed'. The old names are NOT accepted and raise an error naming the valid options.

See Also
--------

:doc:`fmri_show3d <fmri_show3d>` · :doc:`fmri_showcortex <fmri_showcortex>` · :doc:`fmri_braincake <fmri_braincake>` · :doc:`fmri_show3dhalfbrains <fmri_show3dhalfbrains>` · :doc:`fmri_makevizpar <fmri_makevizpar>`

