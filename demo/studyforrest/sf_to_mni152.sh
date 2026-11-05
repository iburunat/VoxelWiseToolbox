#!/bin/bash
# sf_to_mni152.sh
#
# Brings StudyForrest "aligned" BOLD data into canonical MNI152 space, ready
# for the VoxelWise toolbox (which then resamples onto its 91x109x91 2mm grid
# with fmri_tomni152).
#
# Chain:
#   subject-aligned BOLD
#     --[subj2tmpl_warp.nii.gz, FNIRT nonlinear]--> grpbold3Tp2 (group template)
#     --[tmpl2mni_12dof.mat,   FLIRT affine]------> MNI152
#
# Both steps are applied in a SINGLE applywarp call using --postmat, so the
# data is interpolated ONCE: applywarp maps each output voxel back through the
# composed transform chain and samples the input only at the final coordinate,
# so the composition costs nothing. Applying them as two separate resampling
# steps would blur the data twice for no benefit.
#
# Requires: FSL (applywarp, and optionally fslinfo/fsleyes for the QC steps).
#
# Usage:
#   ./sf_to_mni152.sh <transforms_dir> <aligned_bold> <subject> <output>
#
# Example:
#   ./sf_to_mni152.sh ~/Desktop/FORRESTDATA/studyforrest-data-templatetransforms \
#                     ~/Desktop/FORRESTDATA/studyforrest-data-aligned/sub-01/in_bold3Tp2/sub-01_task-avmovie_run-1_bold.nii.gz \
#                     sub-01 \
#                     ~/Desktop/FORRESTDATA/mni/sub-01_task-avmovie_run-1_MNI.nii.gz
set -euo pipefail

if [ $# -ne 4 ]; then
    echo "Usage: $0 <transforms_dir> <aligned_bold> <subject> <output>" >&2
    echo "  transforms_dir : path to studyforrest-data-templatetransforms" >&2
    echo "  aligned_bold   : 4D BOLD already in the subject's bold3Tp2 space" >&2
    echo "  subject        : e.g. sub-01" >&2
    echo "  output         : output .nii.gz path" >&2
    exit 1
fi

XFM_DIR="$1"
INPUT="$2"
SUBJ="$3"
OUTPUT="$4"

WARP="${XFM_DIR}/${SUBJ}/bold3Tp2/in_grpbold3Tp2/subj2tmpl_warp.nii.gz"
POSTMAT="${XFM_DIR}/templates/grpbold3Tp2/xfm/tmpl2mni_12dof.mat"

# The reference image defines the OUTPUT geometry (grid and field of view), not
# the transform. It must be an MNI152-space image, because --postmat lands us in
# MNI152 coordinates.
#
# Resolution matters here. The bundled from_mni/MNI152_T1_1mm.nii.gz is 1mm,
# which would write 182x218x182 = 7.2M voxels per volume -- eight times the 2mm
# grid, for a long 4D movie run. Since fmri_tomni152 resamples to 2mm anyway,
# writing 2mm directly is far cheaper and loses nothing that the 2mm target grid
# would have kept. Override with SF_REF if you specifically want 1mm.
if [ -n "${SF_REF:-}" ]; then
    REF="$SF_REF"
elif [ -n "${FSLDIR:-}" ] && [ -f "${FSLDIR}/data/standard/MNI152_T1_2mm.nii.gz" ]; then
    REF="${FSLDIR}/data/standard/MNI152_T1_2mm.nii.gz"
else
    echo "NOTE: FSL 2mm standard not found; falling back to the bundled 1mm" >&2
    echo "      template. Output will be 1mm and roughly 8x larger." >&2
    REF="${XFM_DIR}/templates/grpbold3Tp2/from_mni/MNI152_T1_1mm.nii.gz"
fi

# --- check every input exists before doing any work ------------------------
for f in "$INPUT" "$WARP" "$POSTMAT" "$REF"; do
    if [ ! -f "$f" ]; then
        echo "ERROR: missing required file:" >&2
        echo "  $f" >&2
        echo >&2
        echo "If this is a DataLad dataset, the file may be a broken symlink" >&2
        echo "until its content is fetched. Retrieve it with:" >&2
        echo "  datalad get $f" >&2
        exit 1
    fi
done

mkdir -p "$(dirname "$OUTPUT")"

echo "Input : $INPUT"
echo "Warp  : $WARP"
echo "Postmat: $POSTMAT"
echo "Ref   : $REF"
echo "Output: $OUTPUT"
echo

# --- the single-interpolation transform ------------------------------------
# --premat is not needed: the input is already in bold3Tp2 space.
# --postmat applies the group->MNI152 affine after the nonlinear warp, so
# there is exactly one resampling of the data.
applywarp \
    --in="$INPUT" \
    --ref="$REF" \
    --warp="$WARP" \
    --postmat="$POSTMAT" \
    --interp=spline \
    --out="$OUTPUT"

echo
echo "Done: $OUTPUT"
echo
echo "NEXT: verify before trusting this."
echo "  1. Visual check that the brain overlays the template:"
echo "       fsleyes $REF $OUTPUT"
echo "  2. Confirm the 4th dimension (time) survived:"
echo "       fslinfo $OUTPUT | grep -E 'dim1|dim2|dim3|dim4|pixdim'"
echo "  3. In MATLAB, resample onto the toolbox grid and confirm the"
echo "     canonical voxel count:"
echo "       fmri_tomni152('$OUTPUT', 'out_mni2mm.nii');"
echo "       v = fmri_vol2vect(fmri_readnii('out_mni2mm.nii'));"
echo "       size(v,1)   % must be 228453"
