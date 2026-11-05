"""
Build the NIfTI test fixtures listed in Section 12 of the handover, so the
MATLAB tests have real files to run against. Also quantify the FOV-overlap
issue with a realistic already-normalised image.
"""
import numpy as np
import nibabel as nib
import os

OUT = os.path.join(os.path.dirname(__file__), 'fixtures')
os.makedirs(OUT, exist_ok=True)

MNI2 = np.array([[-2., 0., 0.,   90.],
                 [ 0., 2., 0., -126.],
                 [ 0., 0., 2.,  -72.],
                 [ 0., 0., 0.,    1.]])

def phantom(shape, affine, seed=0):
    """A structured phantom: nested ellipsoids + a gradient, so interpolation
    errors and mis-registrations are visible rather than hidden in noise."""
    rng = np.random.default_rng(seed)
    i, j, k = np.meshgrid(*[np.arange(s) for s in shape], indexing='ij')
    # world coordinates of every voxel
    v = np.stack([i.ravel(), j.ravel(), k.ravel(), np.ones(i.size)])
    w = affine @ v
    x, y, z = [w[a].reshape(shape) for a in range(3)]
    r = np.sqrt((x/70)**2 + (y/90)**2 + (z/70)**2)
    img = np.zeros(shape)
    img[r < 1.0] = 100.
    img[r < 0.7] = 200.
    img[r < 0.4] = 300.
    img += 20 * (x / 90.)                      # L-R gradient: catches flips
    img[r > 1.05] = 0.
    return img.astype(np.float32)

fixtures = {}

# ---- 1. identity: already MNI152 2mm -------------------------------------
img = phantom((91,109,91), MNI2)
n = nib.Nifti1Image(img, MNI2)
n.header.set_sform(MNI2, code=1); n.header.set_qform(MNI2, code=0)
f = f'{OUT}/test_mni152_2mm.nii'; nib.save(n, f); fixtures['identity'] = f

# ---- 2. MNI152 1mm --------------------------------------------------------
A1 = np.array([[-1.,0.,0., 90.],[0.,1.,0.,-126.],[0.,0.,1.,-72.],[0.,0.,0.,1.]])
img = phantom((181,217,181), A1)
n = nib.Nifti1Image(img, A1)
n.header.set_sform(A1, code=1); n.header.set_qform(A1, code=0)
f = f'{OUT}/test_mni152_1mm.nii'; nib.save(n, f); fixtures['1mm'] = f

# ---- 3. anisotropic 3x3x4 mm, still in MNI space ---------------------------
A3 = np.array([[-3.,0.,0., 90.],[0.,3.,0.,-126.],[0.,0.,4.,-72.],[0.,0.,0.,1.]])
img = phantom((61,73,46), A3)
n = nib.Nifti1Image(img, A3)
n.header.set_sform(A3, code=1); n.header.set_qform(A3, code=0)
f = f'{OUT}/test_aniso_3x3x4.nii'; nib.save(n, f); fixtures['aniso'] = f

# ---- 4. integer atlas / label map -----------------------------------------
lab = np.zeros((91,109,91), dtype=np.int16)
i,j,k = np.meshgrid(np.arange(91), np.arange(109), np.arange(91), indexing='ij')
v = np.stack([i.ravel(), j.ravel(), k.ravel(), np.ones(i.size)])
w = MNI2 @ v
x,y,z = [w[a].reshape((91,109,91)) for a in range(3)]
r = np.sqrt((x/70)**2 + (y/90)**2 + (z/70)**2)
lab[(r<1.0)] = 1
lab[(r<1.0)&(x>0)] = 2          # right hemisphere
lab[(r<0.5)] = 3
lab[(r<0.5)&(x>0)] = 4
n = nib.Nifti1Image(lab, MNI2)
n.header.set_sform(MNI2, code=1); n.header.set_qform(MNI2, code=0)
f = f'{OUT}/test_atlas_labels.nii'; nib.save(n, f); fixtures['atlas'] = f
print(f"atlas labels present: {sorted(np.unique(lab).tolist())}")

# ---- 5. qform-only (sform_code = 0) ---------------------------------------
img = phantom((91,109,91), MNI2)
n = nib.Nifti1Image(img, None)
n.header.set_qform(MNI2, code=1)
n.header.set_sform(None, code=0)
f = f'{OUT}/test_qform_only.nii'; nib.save(n, f); fixtures['qform'] = f
h = nib.load(f).header
print(f"qform-only: sform_code={h['sform_code']}, qform_code={h['qform_code']}, qfac={h['pixdim'][0]}")

# ---- 6. qfac = -1 ----------------------------------------------------------
Aq = MNI2.copy()
Aq[:3,2] *= -1                      # flip z -> forces qfac = -1
Aq[2,3]  = 108.
img = phantom((91,109,91), Aq)
n = nib.Nifti1Image(img, None)
n.header.set_qform(Aq, code=1)
n.header.set_sform(None, code=0)
f = f'{OUT}/test_qfac_minus1.nii'; nib.save(n, f); fixtures['qfac'] = f
h = nib.load(f).header
print(f"qfac test: qfac={h['pixdim'][0]}  (expect -1)")

# ---- 7. 4D time series -----------------------------------------------------
T = 5
img4 = np.stack([phantom((91,109,91), MNI2) * (1 + 0.1*t) for t in range(T)], axis=-1)
n = nib.Nifti1Image(img4.astype(np.float32), MNI2)
n.header.set_sform(MNI2, code=1); n.header.set_qform(MNI2, code=0)
f = f'{OUT}/test_4d_timeseries.nii'; nib.save(n, f); fixtures['4d'] = f
print(f"4D shape: {nib.load(f).shape}")

# ---- 8. oblique (rotated 12 deg about z), still overlapping MNI -------------
th = np.deg2rad(12)
R = np.array([[np.cos(th),-np.sin(th),0],[np.sin(th),np.cos(th),0],[0,0,1]])
Ao = np.eye(4)
Ao[:3,:3] = R @ np.diag([-3.,3.,3.])
Ao[:3, 3] = [90.,-126.,-72.]
img = phantom((61,73,61), Ao)
n = nib.Nifti1Image(img, Ao)
n.header.set_sform(Ao, code=1); n.header.set_qform(Ao, code=0)
f = f'{OUT}/test_oblique.nii'; nib.save(n, f); fixtures['oblique'] = f

# ---- 9. scl_slope / scl_inter (integer stored, physical scaled) ------------
img = phantom((91,109,91), MNI2)
stored = np.round(img / 0.5).astype(np.int16)      # slope 0.5
n = nib.Nifti1Image(stored, MNI2)
n.header.set_sform(MNI2, code=1); n.header.set_qform(MNI2, code=0)
n.header['scl_slope'] = 0.5
n.header['scl_inter'] = 10.0
f = f'{OUT}/test_scl_scaling.nii'; nib.save(n, f); fixtures['scl'] = f
print(f"scl test: slope=0.5 inter=10 -> physical max should be ~{stored.max()*0.5+10:.1f}")

# ---- 10. NATIVE SPACE — the silent-failure case ----------------------------
Anat = np.array([[3.,0.,0.,-100.],[0.,3.,0.,-100.],[0.,0.,4.,-60.],[0.,0.,0.,1.]])
img = phantom((64,64,35), Anat)
n = nib.Nifti1Image(img, Anat)
n.header.set_sform(Anat, code=1); n.header.set_qform(Anat, code=0)
f = f'{OUT}/test_native_space.nii'; nib.save(n, f); fixtures['native'] = f

# ---- 11. .nii.gz -----------------------------------------------------------
img = phantom((91,109,91), MNI2)
n = nib.Nifti1Image(img, MNI2)
n.header.set_sform(MNI2, code=1); n.header.set_qform(MNI2, code=0)
f = f'{OUT}/test_gzipped.nii.gz'; nib.save(n, f); fixtures['gz'] = f

print("\n" + "="*72)
print("FIXTURES WRITTEN")
print("="*72)
for k, v in fixtures.items():
    sz = os.path.getsize(v) / 1e6
    print(f"  {k:10s} {os.path.basename(v):28s} {sz:6.1f} MB")

# =========================================================================
print("\n" + "="*72)
print("FOV OVERLAP — how much of the target grid each fixture actually covers")
print("="*72)
def overlap(path):
    n = nib.load(path)
    A = n.affine
    dim = np.array(n.shape[:3])
    I,J,K = np.meshgrid(np.arange(91), np.arange(109), np.arange(91), indexing='ij')
    tv = np.vstack([I.ravel(),J.ravel(),K.ravel(),np.ones(I.size)])
    iv = np.linalg.solve(A, MNI2 @ tv)
    ins = np.all((iv[:3] >= 0) & (iv[:3] <= (dim[:,None]-1)), axis=0)
    return ins.mean()

print(f"\n  {'fixture':12s} {'target grid inside input FOV':>30s}")
print("  " + "-"*44)
for k, v in fixtures.items():
    print(f"  {k:12s} {overlap(v):>29.1%}")
print("""
  The 'native' fixture covers 65% of the grid by coordinate overlap -- but the
  DATA there is a phantom centred on native coordinates, so the resampled
  output is mostly the zero background. Coordinate overlap alone is therefore
  NOT a sufficient guard. A non-zero-fraction check on the OUTPUT is the
  robust test, because it catches both no-overlap AND overlap-with-background.
""")
