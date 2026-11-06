<p align="center">
  <img src="source/_static/logo.png" alt="VoxelWise Toolbox" height="170"/>
</p>

<p align="center">
  <i>A lightweight, transparent MATLAB toolbox for human fMRI analysis.</i><br>
  Specially built for continuous-feature, naturalistic paradigms, where the
  discrete-event assumptions of conventional designs do not hold.
</p>

<p align="center">
  <a href="https://voxelwisetoolbox.readthedocs.io/en/latest/">
    <img src="https://readthedocs.org/projects/voxelwisetoolbox/badge/?version=latest" alt="Documentation status">
  </a>
  <a href="https://opensource.org/licenses/MIT">
    <img src="https://img.shields.io/badge/License-MIT-orange.svg" alt="MIT licence">
  </a>
  <a href="https://zenodo.org/badge/latestdoi/1188857124">
    <img src="https://zenodo.org/badge/1188857124.svg" alt="DOI">
  </a>
  <a href="https://github.com/iburunat/VoxelWiseToolbox/releases">
    <img src="https://img.shields.io/github/v/release/iburunat/VoxelWiseToolbox?include_prereleases" alt="Latest release">
  </a>
  <img src="https://img.shields.io/badge/platform-macOS%20%7C%20Linux%20%7C%20Windows-lightgrey.svg" alt="Platforms">
</p>

<hr>

📖 **Full documentation:** [voxelwisetoolbox.readthedocs.io](https://voxelwisetoolbox.readthedocs.io/en/latest/)

## Philosophy

The toolbox is designed to be **inspectable**. Every function is a single
readable `.m` file. There are no compiled binaries, no pipeline objects and no
hidden state. To understand what the toolbox does, you read the code.

All brain data is held in one fixed layout: the **228,453 in-brain voxels** of
the 91×109×91 MNI152 2 mm template, as a `228453 × T` matrix, with `T = 1` for
a single brain map. Because there is no wrapper object or batch structure, the
output of any function is valid input to any other. Conversion to and from
volume form is lossless, via `fmri_vol2vect` and `fmri_vect2vol`.

## Requirements

- **MATLAB R2019a or later.** R2019a is the release in which `xcorr`, used by
  `fmri_effdf`, moved into base MATLAB from the Signal Processing Toolbox.
- **No MathWorks toolboxes.** No Statistics, Signal Processing or Image
  Processing Toolbox is required by any function.
- **No SPM.** Cluster labelling is `fmri_bwlabel`, a pure MATLAB
  implementation. If SPM happens to be on your path, the setup script says so
  and tells you it is not used.
- A patched NIfTI reader is bundled in `external/`; nothing to install.

## Installation

```matlab
% Run the setup script once per session...
run('/path/to/VoxelWise-Toolbox/fmritoolbox_setup.m')

% ...or add that same line to ~/Documents/MATLAB/startup.m to load it
% automatically.
```

The script adds `core/`, `tools/`, `masks/`, `atlases/`, `demo/` and the
bundled NIfTI library to the path. It deliberately does not use `genpath`:
`core/private/` holds internal helpers that MATLAB makes visible to `core/`
automatically, and putting them on the path would defeat that.

## Quick start

```matlab
% Read a preprocessed NIfTI and vectorise it
[vol, ~] = fmri_readnii('sub-01_bold.nii');
data     = fmri_vol2vect(vol);               % 228453 x T

% Condition the time series
data = fmri_correctmovement(data, 'rp_sub-01.txt');
data = fmri_detrend(data, 6);
data = fmri_zscorevoldata(data);

% Correlate a continuous regressor with every voxel
r_map = fmri_corregressor(regressor, data);  % 228453 x 1

% Display, then label the peak voxel
fmri_showslices(r_map, 1, 2, [-0.6 0.6]);
[~, peak] = max(r_map);
disp(fmri_regionnumber(fmri_ind2sub(peak)))
```

## Toolbox modules

83 public functions in eight composable modules. The authoritative list is
`Contents.m` at the repository root, generated from the function headers
themselves; the same content is browsable as the
[function reference](https://voxelwisetoolbox.readthedocs.io/en/latest/modules/index.html).

| Module | Functions | |
|---|---:|---|
| I/O and NIfTI handling | 4 | Reading, writing and resampling onto the 2 mm grid |
| Space, coordinates and reshaping | 11 | Vector/volume conversion, MNI and Talairach coordinates, resampling |
| Temporal preprocessing | 7 | Detrending, band-pass, motion regression, smoothing, deconvolution |
| Atlases and regions of interest | 11 | ROI masks, region lookup, voxel/ROI aggregation, cluster tables |
| Analysis: effect estimation | 10 | Regressor and seed correlation, cross-correlation, PPI, RSA, ISC |
| Statistical inference | 16 | Parametric conversions, *t*-tests, TFCE, cluster-extent correction |
| Simulation and signal quality | 5 | Synthetic cohorts, SNR-i, tSNR, tCNR |
| Visualisation | 19 | Slice mosaics, three-plane views, surface and 3D rendering, colormaps |

## Atlases

Nineteen selectable atlas maps from ten published sources, behind one
interface. List them and their region counts with `fmri_atlas`, then load any
one by number:

```matlab
fmri_atlas          % the 19 maps and their region counts
fmri_atlas(1)       % the 116 AAL / MarsBar region names
```

Sources and region counts are documented in the
[atlas reference](https://voxelwisetoolbox.readthedocs.io/en/latest/modules/fmri_loadatlas.html).
`fmri_loadatlas` is the single source of truth for atlas metadata; its counts
are verified against the atlas files rather than quoted from the source papers.

## Demos

Ten worked examples ship in `demo/`. Each runs end to end, and those built on
simulated cohorts need no scanner data at all.

| Script | |
|---|---|
| `demo_preprocessing.m` | The preprocessing chain on one participant, with tSNR and tCNR reported |
| `demo_glm.m` | Two-level GLM on a simulated cohort |
| `demo_naturalistic.m` | The full naturalistic-stimulus pipeline, end to end |
| `demo_visualization.m` | Every display function in turn |

The remaining six cover temporal smoothing, cross-correlation, Wiener
deconvolution, voxel distance, cluster-size estimation and TFCE. Start with
`demo_naturalistic.m` for a complete demonstration requiring no external data.

## Citation

Please cite both the paper and the archived release.

> Burunat, I., Alluri, V. & Toiviainen, P. (in preparation, 2026). *VoxelWise
> Toolbox: transparent and composable fMRI analysis in base MATLAB.*

> Burunat, I., Alluri, V. & Toiviainen, P. (2026). *VoxelWise Toolbox* (v1.0.0).
> Zenodo. https://doi.org/10.5281/zenodo.19173637

A BibTeX entry is generated by GitHub from `CITATION.cff`.

## Licence

MIT — see [`LICENSE`](LICENSE). Bundled components keep their own licences:
the NIfTI I/O routines are Jimmy Shen's, under a BSD licence, and the atlases
are redistributed from their original authors under their respective terms
(`atlases/ATLAS_LICENSES.md`).

## Acknowledgements

Developed at the [University of Jyväskylä](https://www.jyu.fi/en).
