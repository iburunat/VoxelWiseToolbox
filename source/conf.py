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

# Only keys sphinx_rtd_theme actually recognises. It warns on any option it
# does not know, and with -nW that warning fails the build - so the Alabaster
# options the old conf.py carried ('logo_name', 'description', 'show_related',
# 'show_powered_by', 'sidebar_hide_name', 'navigation_with_keys',
# 'github_user', 'github_repo') must not be copied across.
html_theme_options = {
    'collapse_navigation': False,
    'sticky_navigation': True,
    'navigation_depth': 2,
    'style_external_links': True,
    # Colour is NOT set here. jyu.css owns every colour in one :root block,
    # so there is a single place to change it; a theme option set here would
    # be a second, silently overridden source of truth.
}

# Custom stylesheet, loaded after the theme's own CSS so its rules win.
# The file must exist at source/_static/jyu.css.
html_css_files = ['jyu.css']

# Shown at the foot of every page.
html_show_sourcelink = True
html_last_updated_fmt = '%Y-%m-%d'
