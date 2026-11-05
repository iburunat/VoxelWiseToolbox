# Real-data validation: StudyForrest → MNI152 → VoxelWise toolbox

**Which StudyForrest dataset this is.** The files used here are
`task-avmovie` in `bold3Tp2` space: the **3 T audio-visual** acquisition
described in Hanke et al. (2016), *A studyforrest extension, simultaneous fMRI
and eye gaze recordings during prolonged natural stimulation*, Sci Data
3:160092 (accession ds000113d), in which 15 of the original participants watched
the audio-visual film.

This is easily confused with Hanke et al. (2014), Sci Data 1:140003, the
**7 T audio-only** dataset, and with the 7 T music-genre extension
(F1000Research 4:174, ds000113b). All three share the movie stimulus, an
eight-segment structure and the studyforrest alignment infrastructure, but they
are separate experiments with different field strengths, resolutions and brain
coverage. Acquisition parameters for `task-avmovie` must be taken from the 2016
paper; the 2014 paper is background only.

Because the 2016 extension reused "the exact same movie cut and a stimulation
that was synchronized with the previous acquisition", the segment durations and
volume counts do carry across the datasets — which is why run 1 is 451 volumes
at TR 2 s in both.

The toolbox operates on data already in canonical MNI152 space, resampled onto
its 91×109×91 2 mm grid (228,453 in-mask voxels). Getting raw fMRI to that point
is standard preprocessing performed with established tools, and is deliberately
outside the toolbox's scope. This directory documents the route for the
StudyForrest data.

## Why the raw release cannot be read directly

The raw BIDS releases are in native scanner space with an oblique acquisition
affine. Checked on `ds000113b` (music genres), `sub-01`, run 01:

| field | value | meaning |
|---|---|---|
| `dim` | 160 × 160 × 36 × 153 | partial-brain slab, 153 volumes |
| `pixdim` | 1.4 × 1.4 × 1.54 mm, TR 2.0 s | high-resolution 7 T EPI |
| `qform_code` | **1** | `SCANNER_ANAT` — native scanner space |
| `sform_code` | **0** | sform unused; its identity rows are placeholders |
| obliquity | ~12° off cardinal | genuinely oblique acquisition |

`qform_code = 1` is decisive: the affine describes scanner coordinates, not a
template. MNI-space data would carry code 4.

**These figures describe `ds000113b` only — do not carry them over to the
avmovie analysis.** The 3 T audio-visual data actually used here has quite
different geometry, and in particular is *not* a partial-brain slab:

| | ds000113b (7 T music genres) | task-avmovie (3 T, aligned) |
|---|---|---|
| grid | 160 × 160 × 36 | 64 × 86 × 45 |
| voxel size | 1.4 × 1.4 × 1.54 mm | 2.5 mm isotropic |
| z-extent | ~55 mm (auditory-centred slab) | ~112 mm |
| volumes (run 1) | 153 | 451 |

Because the avmovie acquisition covers roughly twice the z-extent, there is no
reason to expect the large empty regions that a partial-brain slab would leave
in the 228,453-voxel vector. Any substantial missing coverage in the avmovie
result should therefore be investigated rather than attributed to the
acquisition.

This is also why `fmri_readnii` fails on these files with *"Non-orthogonal
rotation or shearing found inside the affine matrix"*. That is not a bug:
`fmri_readnii` uses `load_nii`, which refuses to apply a non-orthogonal affine
rather than silently distorting the data. (`fmri_tomni152` uses
`load_untouch_nii` instead, reading the raw array and handling the affine
itself — but it performs affine resampling only and explicitly does **not**
do native→MNI spatial normalisation, so it cannot rescue raw native-space data
on its own.)

## The route (movie data, 3 T — well supported)

StudyForrest publishes subject-aligned data plus the transforms to reach MNI.
Three repositories are needed:

- `psychoinformatics-de/studyforrest-data-aligned` — BOLD aligned to each
  subject's own template space, and the MCFLIRT motion parameters beside it
- `psychoinformatics-de/studyforrest-data-templatetransforms` — the templates
  and transformations
- `psychoinformatics-de/studyforrest-data-annotations` — the published stimulus
  annotations, including the acoustic envelope used as the regressor

The chain is:

```
studyforrest-data-aligned/sub-XX/in_bold3Tp2/*_bold.nii.gz   (subject BOLD space)
        |
        |  sf_to_mni152.sh  -- FLIRT, two transforms composed into ONE resample:
        |     bold3Tp2 -> T1w            (6 dof, rigid)
        |     T1w      -> MNI152_T1_2mm  (12 dof, affine)
        v
mni/sub-XX_task-avmovie_run-N_MNI.nii.gz   (91 x 109 x 91, 2 mm = the toolbox grid)
        |
        |  demo_studyforrest.m
        |     fmri_readnii   -> 91 x 109 x 91 x T
        |     fmri_vol2vect  -> 228453 x T
        v
toolbox analysis
```

Confirmed present for `sub-01`:

```
sub-01/bold3Tp2/in_grpbold3Tp2/subj2tmpl_warp.nii.gz
templates/grpbold3Tp2/xfm/tmpl2mni_12dof.mat
templates/grpbold3Tp2/xfm/mni2tmpl_12dof.mat
templates/grpbold3Tp2/in_mni/brain_12dof.nii.gz
templates/grpbold3Tp2/from_mni/MNI152_T1_1mm.nii.gz
```

**The group template is not canonical MNI152.** `grpbold3Tp2` is a
study-specific template built from these participants; the dataset author
describes it as being "in MNI space", meaning MNI-aligned. Because the toolbox's
atlases (AAL, Harvard-Oxford, Juelich, …) are defined in canonical MNI152,
stopping at the group template would leave a systematic offset in every region
label. The final `tmpl2mni_12dof` hop is therefore **required, not optional**.

Helpfully, the `12dof` naming shows the group↔MNI152 relationship is a pure
affine, so that last hop is a single cheap FLIRT operation with no warp
interpolation.

### What the aligned release already did, and what it did not

Reading the derivation code in `studyforrest-data-aligned/code/` settles two
questions that otherwise have to be assumed:

- **Motion correction: applied.** `mcflirt_2stage`, driven by
  `avmovie_motion_correction.submit`, runs a two-stage MCFLIRT realignment.
  These are not raw unaligned volumes.
- **Spatial smoothing: none.** The only smoothing anywhere in that pipeline is
  `fslmaths "$ref" -s …`, applied to the registration *reference* volume and
  consumed by `flirt -omat` to estimate a transform. It never touches the
  timeseries, and its parameter defaults to 0. The output volumes are written by
  `flirt -applyxfm -interp sinc` — resampling only.

Note that realignment having been **applied** is not the same as motion having
been **regressed out**. Residual motion-related signal survives realignment, and
in naturalistic viewing head motion covaries with the stimulus — people shift at
loud moments — so it can induce spurious correlation with an acoustic regressor
specifically. The 6 parameters MCFLIRT estimated are distributed beside the BOLD
as `*_bold_mcparams.txt`, and `demo_studyforrest.m` regresses them out
with `fmri_correctmovement`. They were estimated in the native input space,
before the warp to MNI152, which does not matter: they are a per-volume time
series used as temporal nuisance regressors, not a spatial object.

### Running it

`sf_to_mni152.sh` performs both steps in **one** `applywarp` call using
`--postmat`, so this stage resamples the data once rather than twice:

```bash
./sf_to_mni152.sh <transforms_dir> <aligned_bold> <subject> <output>
```

Transform order was checked against FSL's convention: forward, `applywarp`
applies `premat`, then `warp`, then `postmat`. Our chain is warp (subj→tmpl)
then affine (tmpl→MNI), so `--warp=subj2tmpl_warp --postmat=tmpl2mni_12dof` is
the correct assignment, and `--premat` is correctly omitted because the input is
already in `bold3Tp2` space.

The reference image defaults to FSL's 2 mm MNI152 standard rather than the
bundled 1 mm template: the toolbox resamples to 2 mm regardless, and 1 mm output
would be roughly eight times larger per volume (7.2 M vs 903 K voxels). Override
with `SF_REF=/path/to/ref.nii.gz` if 1 mm is wanted.

All three repositories are DataLad datasets, so files appear as symlinks until
their content is fetched. A symlink pointing into `.git/annex/objects/…` that
will not open is an unfetched file, not a missing one. Retrieve only what is
needed:

```bash
datalad clone https://github.com/psychoinformatics-de/studyforrest-data-templatetransforms
cd studyforrest-data-templatetransforms
datalad get sub-01/bold3Tp2/in_grpbold3Tp2/subj2tmpl_warp.nii.gz
datalad get templates/grpbold3Tp2/xfm/tmpl2mni_12dof.mat

datalad clone https://github.com/psychoinformatics-de/studyforrest-data-aligned
cd studyforrest-data-aligned
datalad get sub-01/in_bold3Tp2/sub-01_task-avmovie_run-1_bold.nii.gz
datalad get sub-01/in_bold3Tp2/sub-01_task-avmovie_run-1_bold_mcparams.txt

datalad clone https://github.com/psychoinformatics-de/studyforrest-data-annotations
cd studyforrest-data-annotations
datalad get segments/avmovie/conf_audio_run-1_events.tsv
```

## Verification — do not trust the chain, test it

Running without error is not evidence of correct alignment. Check:

1. **Visual overlay.** `fsleyes $FSLDIR/data/standard/MNI152_T1_2mm.nii.gz out.nii.gz`
2. **Time dimension survived.** `fslinfo out.nii.gz` — `dim4` must equal the
   input's volume count.
3. **Canonical voxel count**, in MATLAB:
   ```matlab
   fmri_tomni152('out.nii.gz', 'out_mni2mm.nii');
   v = fmri_vol2vect(fmri_readnii('out_mni2mm.nii'));
   size(v, 1)   % must be 228453
   ```
4. **A biological-plausibility check (not a formal validation).** For an
   auditory stimulus, confirming that the response falls within an
   independently-defined Heschl's/superior-temporal mask (`fmri_regionmask`,
   Harvard-Oxford) is reassuring. But it is *not* proof of correct registration:
   the activation pattern also depends on the regressor, the HRF model, the
   preprocessing and the statistics, so a plausible map cannot isolate the
   registration step. Treat it as converging evidence alongside checks 1-3, and
   rely on the visual overlay (check 1) and the published transforms for the
   registration claim itself.

## Running the group analysis

### Layout the script expects

`demo_studyforrest.m` reads one `rootFolder` and derives every path from
it. Set it at the top of the script and arrange the data as:

```
<rootFolder>/
  studyforrest-data-aligned/
    sub-01/in_bold3Tp2/sub-01_task-avmovie_run-1_bold_mcparams.txt
    ...
  studyforrest-data-annotations/
    segments/avmovie/conf_audio_run-1_events.tsv
  mni/
    sub-01_task-avmovie_run-1_MNI.nii.gz
    sub-02_task-avmovie_run-1_MNI.nii.gz
    ...
  toolbox_work/                 # created by the script
```

The filenames in `mni/` must match exactly, including the `task-avmovie`
segment and the uppercase `MNI`: the script builds them with `sprintf` and
reports `MISSING, skipped` for anything it cannot find.

### Fetching and converting all fifteen participants

The avmovie acquisition covers 15 of the 20 original participants, so the
subject IDs are not contiguous. Note the second `datalad get`: the motion
parameters are a separately annexed file, and the demo now stops without them.

```bash
ROOT=~/Desktop/FORRESTDATA
XFM=$ROOT/studyforrest-data-templatetransforms
ALIGNED=$ROOT/studyforrest-data-aligned
OUT=$ROOT/mni
RUN=run-1

chmod +x sf_to_mni152.sh

for s in 01 02 03 04 05 06 09 10 14 15 16 17 18 19 20; do
    SUBJ=sub-$s
    IN=$ALIGNED/$SUBJ/in_bold3Tp2/${SUBJ}_task-avmovie_${RUN}_bold.nii.gz
    datalad get "$IN"
    datalad get "$ALIGNED/$SUBJ/in_bold3Tp2/${SUBJ}_task-avmovie_${RUN}_bold_mcparams.txt"
    datalad get "$XFM/$SUBJ/bold3Tp2/in_grpbold3Tp2/subj2tmpl_warp.nii.gz"
    ./sf_to_mni152.sh "$XFM" "$IN" "$SUBJ" \
        "$OUT/${SUBJ}_task-avmovie_${RUN}_MNI.nii.gz"
done
```

`datalad get` is inside the loop deliberately: fetching all fifteen runs up
front needs the whole set on disk at once, whereas converting one at a time
lets you `datalad drop` each input after it has been transformed.

### Running the demo

```matlab
% in demo_studyforrest.m
rootFolder = '/Users/you/Desktop/FORRESTDATA';
```

then run the script. `$ROOT` above and `rootFolder` here are the same directory;
keep them in step and nothing else needs configuring.

### Disk and time

Converting one run for fifteen participants requires about 24 GB for the 
MNI-space NIfTI files. The demo additionally writes one `.mat` file per 
participant to `toolbox_work/`, holding the retained run as a 228453 × 451 
masked matrix for the smoothness estimate and the intersubject correlation — 
824 MB per participant uncompressed, about 11 GB for fifteen after -v7.3 
compression. Peak memory is one run at a time (roughly 1.6 GB), independent 
of how many runs are combined. The full analysis takes about 85 minutes on a 
2023 MacBook Pro, of which the 1000-permutation cluster-size distribution 
is the majority.

### Verify more than one subject

The per-conversion checks above apply to every participant, not just `sub-01`.
Nothing in the group script validates the grid per subject — it calls
`fmri_vol2vect` and trusts the result — so a participant whose conversion
silently produced the wrong geometry will not raise an error. It will contribute
a column of noise to the group map. At minimum, confirm the canonical shape on
several participants spread through the list:

```matlab
for s = {'sub-01', 'sub-09', 'sub-20'}
    v = fmri_vol2vect(fmri_readnii(fullfile(rootFolder, 'mni', ...
            [s{1} '_task-avmovie_run-1_MNI.nii.gz'])));
    fprintf('%s: %d x %d\n', s{1}, size(v, 1), size(v, 2));   % 228453 x 451
end
```

## The music-genre data (7 T) — one open question

The `bold7Tp1` subject template exists and carries a 6-dof transform into
`bold3Tp2`, so a 7 T chain is available in principle:

```
bold7Tp1 → [xfm_6dof.mat] → bold3Tp2 → [subj2tmpl_warp] → grpbold3Tp2
         → [tmpl2mni_12dof] → MNI152
```

**But `bold7Tp1` is the phase-1 7 T movie acquisition, and the music-genre
extension (`ds000113b`) is a separate acquisition.** Whether the released music
runs already sit in the `bold7Tp1` template space, or need their own initial
alignment step first, is not answerable from the published file layout — it
requires confirmation from the dataset authors. Until that is settled, the movie
data is the supported route.
