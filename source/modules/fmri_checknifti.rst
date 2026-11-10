fmri_checknifti
===============

Warns if the bundled NIFTI toolbox is missing or unpatched.

Description
-----------

This does NOT modify any files. It is a read-only sanity check, intended to be called once from fmritoolbox_setup.m. Its only job is to catch the situation where someone has replaced the bundled, patched external/NIFTI_20130306 with a fresh unpatched download -- which would silently corrupt header reads on MATLAB R2023b and later (see patch_nifti_version_check for the details).

The actual fix is applied ONCE by the maintainer with patch_nifti_version_check and committed to the repository. This function never patches anything at runtime; it only warns.

Usage
-----

.. code-block:: matlab

   fmri_checknifti

Examples
--------

.. code-block:: matlab

   fmri_checknifti     % run the check; silent when the bundled copy is fine

   % It is called for you by the setup script, so in normal use this is
   % the only place it needs to appear:
   fmritoolbox_setup

See Also
--------

``patch_nifti_version_check`` · ``fmritoolbox_setup``

