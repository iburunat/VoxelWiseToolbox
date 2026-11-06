# Sphinx configuration — VoxelWise Toolbox
# Docs: https://www.sphinx-doc.org/en/master/usage/configuration.html

project   = 'VoxelWise Toolbox'
author    = 'Iballa Burunat, Vinoo Alluri & Petri Toiviainen'
copyright = '2026, University of Jyväskylä — MIT Licence'

# Keep in step with the Zenodo release and CITATION.cff.
release = '1.0.0'
version = '1.0'

extensions = [
    'sphinx_copybutton',        # copy button on every code block
    'sphinx_design',            # grids/cards used on the landing page
]

templates_path   = ['_templates']
exclude_patterns = [
    '_build', 'Thumbs.db', '.DS_Store',
    # Dropbox writes these beside the original when two machines touch a
    # file. Sphinx reads every .rst it finds, so one silently fails an
    # -nW build with "document isn't included in any toctree".
    '**/*conflicted copy*',
    '**/*conflicted copy*/**',
]

# Every code block in this project is MATLAB, so make that the default and
# stop tagging each one individually.
highlight_language = 'matlab'
pygments_style     = 'friendly'

# Treat these as errors rather than letting them accumulate silently.
nitpicky = True

html_theme       = 'sphinx_rtd_theme'
html_static_path = ['_static']
html_title       = 'VoxelWise Toolbox'
html_logo        = '_static/voxelwise-toolbox_logo.jpg'
html_favicon     = '_static/voxelwise-toolbox_logo.jpg'

html_theme_options = {
    'collapse_navigation': False,
    'navigation_depth': 2,
    'style_external_links': True,
}

# Shown at the foot of every page.
html_show_sourcelink = True
html_last_updated_fmt = '%Y-%m-%d'
