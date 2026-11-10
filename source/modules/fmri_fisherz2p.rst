fmri_fisherz2p
==============

Two-tailed p-value from a Fisher z-score.

Usage
-----

.. code-block:: matlab

   p = fmri_fisherz2p(z)

Inputs
------

- **Z** -- Standardised Fisher z-score(s), from fmri_fisherz. Any shape.

Outputs
-------

- **P** -- Two-tailed p-value(s), same shape as Z.

Examples
--------

.. code-block:: matlab

   z = fmri_fisherz(r_map, df);
   p = fmri_fisherz2p(z);

See Also
--------

:doc:`fmri_fisherz <fmri_fisherz>` · :doc:`fmri_r2p <fmri_r2p>` · :doc:`fmri_effdf <fmri_effdf>`

