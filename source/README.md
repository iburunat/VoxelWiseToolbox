# Building the VoxelWise Toolbox documentation

## Layout

    .readthedocs.yaml          Read the Docs build config — MUST have the
                               leading dot, and MUST sit at the repo root
    source/conf.py             Sphinx configuration
    source/requirements.txt    pinned doc dependencies
    source/index.rst           landing page
    source/gettingstarted/     installation + quickstart (hand written)
    source/modules/            GENERATED — one page per function, do not edit
    source/demos/              GENERATED — one page per demo, do not edit
    source/_static/            logo, stylesheet and landing-page figures
    tools/generate_rst.m       one .m header -> one .rst page
    tools/batch_generate.m     regenerate everything, grouped from Contents.m

`source/modules/` and `source/demos/` are rebuilt from the .m files every time,
so edits there are lost. Fix the help header in the .m file instead. Both
folders must nonetheless be COMMITTED: Read the Docs runs only Sphinx, has no
MATLAB, and can never run `batch_generate` itself. Without them the published
site has an empty function reference.

`source/_static/` holds:

    jyu.css                           theme overrides; all colour lives here
    voxelwise-toolbox_compact_light.svg   sidebar logo (reversed, for the dark panel)
    voxelwise-toolbox_mark.svg        favicon (square; a wide logo cannot be one)
    toolbox_schematic.svg + .png      landing-page figure, referenced as ".*"
    braincake.png                     landing-page figure

The schematic is referenced as `toolbox_schematic.*` on purpose. Sphinx then
picks the SVG for HTML and the PNG for the PDF build, which cannot embed SVG.
For the same reason, never add a figure as WebP.

**There are four index.rst files and they are not interchangeable.**

| file | contains | toctrees |
|---|---|---|
| `source/index.rst` | landing page | 3 |
| `source/gettingstarted/index.rst` | install + quickstart | 0 |
| `source/modules/index.rst` | function library (generated) | 1 per module |
| `source/demos/index.rst` | tutorials (generated) | 1 |

If the first two are swapped, the build reports `toctree contains reference to
nonexisting document 'gettingstarted/...'` plus `document isn't included in any
toctree`. That is the symptom; the cause is always the swap.

## Nothing but live pages may live under source/

Sphinx builds EVERY `.rst` it finds under `source/`. An old draft parked in
`source/anything/` is built as a page: its relative toctree targets resolve
against its own folder, so they all fail, and the page itself is in no
toctree. One stashed folder produced ten warnings and a failed build.

Keep drafts outside `source/`. The same applies to Dropbox conflicted copies,
which `conf.py` excludes — but an exclusion only helps for patterns someone
remembered to add.

## Regenerate, then build

From MATLAB, at the toolbox root — needed whenever a function header, a
function name or the generator changes:

    batch_generate

Then locally:

    pip install -r source/requirements.txt
    sphinx-build -nW -b html source _build/html

After changing `conf.py`, `jyu.css` or anything in `_static/`, force a full
rebuild — Sphinx does not track those well:

    sphinx-build -nW -a -E -b html source _build/html

`-nW` turns warnings into errors, matching `fail_on_warning: true` in
`.readthedocs.yaml`. A broken cross-reference or a page missing from a toctree
fails the build rather than publishing a site with silent gaps. A failed build
does not replace the live site: Read the Docs keeps serving the last good one.

There is no Makefile. Read the Docs would ignore one anyway; these two commands
are the whole build.

## One-time Read the Docs setup

1. GitHub repo renamed to `VoxelWise-Toolbox`. Renaming keeps the repository's
   numeric id, so the Zenodo link and its concept DOI survive the rename.
2. In Read the Docs, import the renamed repo with the slug `voxelwisetoolbox`,
   so it serves at `voxelwisetoolbox.readthedocs.io`.
3. Keep the old `jy-fmritoolbox` project and add an exact redirect from `/` to
   the new URL, so existing links and any citation of the old address keep
   working. Deleting it frees the slug and breaks them.
4. Check `.readthedocs.yaml` has its leading dot. Named `readthedocs.yaml`, it
   is silently ignored: RTD falls back to defaults and builds without the
   pinned requirements and without `fail_on_warning`.
