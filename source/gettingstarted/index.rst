===============
Getting Started
===============

Installation
============

No compilation, no configuration files, no package manager.

.. code-block:: bash

   git clone https://github.com/iburunat/VoxelWise-Toolbox

Then, from MATLAB, run the setup script once per session — or add the call to
your ``startup.m``:

.. code-block:: matlab

   run('/path/to/VoxelWise-Toolbox/fmritoolbox_setup.m')

Requirements
------------

- **MATLAB R2019a or later.** R2019a is the release in which ``xcorr``, used by
  :doc:`../modules/fmri_effdf`, moved into base MATLAB from the Signal
  Processing Toolbox.
- **No MathWorks toolboxes.** No Statistics, Signal Processing or Image
  Processing Toolbox is required by any function.
- **No SPM.** Cluster labelling is :doc:`../modules/fmri_bwlabel`, a pure
  MATLAB implementation. If SPM happens to be on your path, the setup script
  says so and tells you it is not used.
- A patched NIfTI reader is bundled in ``external/``; nothing to install.

The setup script adds ``core/``, ``tools/``, ``masks/``, ``atlases/``,
``demo/`` and the bundled NIfTI library to the path. It deliberately does not
use ``genpath``: ``core/private/`` holds internal helpers that MATLAB makes
visible to ``core/`` automatically, and putting them on the path would defeat
that.

Quickstart
==========

The data representation
-----------------------

Every function takes and returns brain data in one of two forms:

- a **volume**, ``91 x 109 x 91 x T``
- a **vector**, ``228453 x T`` — the in-brain voxels of the MNI152 2 mm template

with ``T = 1`` for a single brain map and ``T > 1`` for a time series.
:doc:`../modules/fmri_vol2vect` and :doc:`../modules/fmri_vect2vol` convert
between them. Because there is no pipeline object, estimator or batch
structure, the output of any function is valid input to any other.

A first analysis
----------------

.. code-block:: matlab

   % Read a preprocessed NIfTI and vectorise it
   [vol, ~] = fmri_readnii('sub-01_bold.nii');
   data     = fmri_vol2vect(vol);               % 228453 x T

   % Condition the time series
   data = fmri_correctmovement(data, 'rp_sub-01.txt');
   data = fmri_detrend(data, 6);
   data = fmri_zscorevoldata(data);

   % Correlate a continuous regressor with every voxel
   r_map = fmri_corregressor(regressor, data);  % 228453 x 1

   % Display
   fmri_showslices(r_map, 1, 2, [-0.6 0.6]);

Browsing what is available
--------------------------

.. code-block:: matlab

   help fmri_corregressor     % full header for any function
   fmri_atlas                 % the 19 atlas maps and their region counts
   fmri_atlas(1)              % the 116 AAL / MarsBar region names

Where to go next
================

- :doc:`../demos/index` — worked examples that ship with the toolbox.
  ``demo_preprocessing`` is the guided walkthrough; ``demo_naturalistic`` is
  the full pipeline.
- :doc:`../modules/index` — all 83 functions, grouped as in ``Contents.m``.
