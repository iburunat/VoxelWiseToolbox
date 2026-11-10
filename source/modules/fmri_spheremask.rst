fmri_spheremask
===============

Spherical ROI mask centred on a given voxel.

Description
-----------

Creates a vectorized binary brain mask (228453 x 1) where all voxels within a sphere of the specified radius around the centre voxel are set to 1. Useful for creating seed regions for connectivity analyses.

Usage
-----

.. code-block:: matlab

   s = fmri_spheremask(center, radius)

Inputs
------

- **CENTER** -- Centre of the sphere as voxel subscripts [x y z] (1 x 3), or as a linear brain index (scalar). For MNI coordinates, first convert: center = fmri_mni2sub([x y z]).
- **RADIUS** -- Sphere radius in voxels (1 voxel = 2mm). Default: 2 (= 4mm).

Outputs
-------

- **S** -- Binary brain mask (228453 x 1). 1 = inside sphere.

Examples
--------

.. code-block:: matlab

   % 10mm sphere at MNI [20 -58 18]
   mask = fmri_spheremask(fmri_mni2sub([20 -58 18]), 5);

   % Seed time series for FC
   seed_ts = mean(data(logical(mask), :), 1);
   r = fmri_corregressor(seed_ts', data);

See Also
--------

:doc:`fmri_regionmask <fmri_regionmask>` · :doc:`fmri_mni2sub <fmri_mni2sub>` · :doc:`fmri_corregressor <fmri_corregressor>`

