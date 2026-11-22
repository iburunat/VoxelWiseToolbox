function s = abbreviate_region(s)
% ABBREVIATE_REGION  Shorten an atlas region name for a compact legend.
%
% Applies standard full-phrase abbreviations first, then word-level ones, then
% caps the length. Shared by fmri_show3datlas and fmri_show3dba; callers keep
% the full names for their own output, so this affects only legend text.

s = strtrim(s);

% Check full region names first so familiar abbreviations such as M1, V1 and
% DLPFC can be used directly. Names without a specific abbreviation are
% shortened using the general rules below.
special = {
    'BA1 Primary somatosensory',               'BA1 S1'
    'BA2 Primary somatosensory',               'BA2 S1'
    'BA3 Primary somatosensory',               'BA3 S1'
    'BA4 Primary motor',                       'BA4 M1'
    'BA5 Somatosensory association'            'BA5 SPL ant'
    'BA6 Premotor and supplementary motor',    'BA6 SMA/PM'
    'BA7 Somatosensory association'            'BA7 SPL'
    'BA8 Frontal eye field / superior frontal','BA8 FEF'
    'BA9 Dorsolateral prefrontal',             'BA9 DLPFC'
    'BA10 Anterior prefrontal',                'BA10 aPFC'
    'BA11 Orbitofrontal',                      'BA11 OFC'
    'BA12 (not delineated in this atlas)',     'BA12 (n.d.)'
    'BA13 Insular cortex',                     'BA13 INS'
    'BA14 (not delineated in this atlas)',     'BA14 (n.d.)'
    'BA15 (not delineated in this atlas)',     'BA15 (n.d.)'
    'BA16 (not delineated in this atlas)',     'BA16 (n.d.)'
    'BA17 Primary visual (V1)',                'BA17 V1'
    'BA18 Secondary visual (V2)',              'BA18 V2'
    'BA19 Associative visual (V3-V5)',         'BA19 V3-V5'
    'BA20 Inferior temporal gyrus',            'BA20 ITG'
    'BA21 Middle temporal gyrus',              'BA21 MTG'
    'BA22 Superior temporal gyrus',            'BA22 STG'
    'BA23 Ventral posterior cingulate',        'BA23 vPCC'
    'BA24 Ventral anterior cingulate',         'BA24 vACC'
    'BA25 Subgenual'                           'BA25 sgACC'
    'BA26 (not delineated in this atlas)'      'BA26 (n.d.)'
    'BA27 Piriform',                           'BA27 Piriform'
    'BA28 Posterior entorhinal',               'BA28 pERC'
    'BA29 Retrosplenial' ,                     'BA29 RSC'
    'BA30 Cingulate (retrosplenial agranular)','BA30 RGa'
    'BA31 Dorsal posterior cingulate',         'BA31 dPCC'
    'BA32 Dorsal anterior cingulate',          'BA32 dACC'
    'BA33 Pregenual anterior cingulate',       'BA33 pgACC'
    'BA34 Anterior entorhinal',                'BA34 aERC'
    'BA35 Perirhinal',                         'BA35 PRC'
    'BA36 Ectorhinal',                         'BA36 Ectorhinal'
    'BA37 Fusiform gyrus',                     'BA37 FG'
    'BA38 Temporopolar',                       'BA38 TP'
    'BA39 Angular gyrus',                      'BA39 AG'
    'BA40 Supramarginal gyrus',                'BA40 SMG'
    'BA41 Primary auditory (Heschl)',          'BA41 A1'
    'BA42 Auditory association',               'BA42 A2'
    'BA43 Subcentral (primary gustatory)',     'BA43 Gustatory'
    'BA44 Pars opercularis (Broca)',           'BA44 IFGoper (Broca)'
    'BA45 Pars triangularis (Broca)',          'BA45 IFGtri (Broca)'
    'BA46 Dorsolateral prefrontal',            'BA46 DLPFC'
    'BA47 Pars orbitalis',                     'BA47 IFGorb'
    };
hit = strcmpi(s, special(:,1));
if any(hit)
    s = special{find(hit, 1), 2};
    return
end

% Compound names first: these already encode the structure, so consume a
% following "Gyrus" to avoid a redundant trailing "G" (e.g. "PreCG G").
compound = {
    'Precentral Gyrus',    'PreCG'
    'Postcentral Gyrus',   'PostCG'
    'Supramarginal Gyrus', 'SupraMargG'
    'Calcarine fissure and surrounding cortex','Calcarine'
    };
for r = 1:size(compound, 1)
    s = regexprep(s, ['\<' compound{r,1} '\>'], compound{r,2}, 'ignorecase');
end

% Whole-word replacements (case-insensitive, word boundaries) applied in order.
repl = {
    'Left',         'L'
    'Right',        'R'
    'Anterior',     'Ant'
    'Posterior',    'Post'
    'Superior',     'Sup'
    'Inferior',     'Inf'
    'Middle',       'Mid'
    'Medial',       'Med'
    'Lateral',      'Lat'
    'Gyrus',        'G'
    'Sulcus',       'S'
    'Cortex',       'Ctx'
    'Nucleus',      'Nuc'
    'Division',     'Div'
    'Cerebellum',   'Cb'
    'Hemisphere',   'Hem'
    'Frontal',      'Front'
    'Temporal',     'Temp'
    'Occipital',    'Occ'
    'Parietal',     'Par'
    'Cingulate',    'Cing'
    };

for r = 1:size(repl, 1)
    s = regexprep(s, ['\<' repl{r,1} '\>'], repl{r,2}, 'ignorecase');
end


% Collapse any doubled spaces introduced by the replacements.
s = regexprep(s, '\s+', ' ');
s = strtrim(s);

% Cap the length so the legend stays narrow; keep the tail off with an ellipsis.
maxlen = 22;
if numel(s) > maxlen
    s = [s(1:maxlen-1) char(8230)];   % ... (single-char ellipsis)
end
end