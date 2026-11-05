# How to apply the NIFTI fix — patch once, don't patch at runtime

Short answer to "should the toolbox call `patch_nifti_version_check` itself?":
**No.** Patch the files once, as the maintainer, and ship them patched. Nothing
should rewrite files at runtime.

## Why not at runtime

A toolbox that edits its own source files every time it loads is the wrong
pattern:

- It **mutates the user's installation**. If the toolbox is in a read-only
  location (shared install, container, /opt), the write fails and a non-event
  becomes a startup error.
- It forces either a check-and-patch on every load (slow, touches disk each
  session) or patch-once-with-a-flag (now you maintain state about whether
  you've patched). Both are needless complexity.
- It **hides the change from version control**: the file committed to Git stays
  buggy while what actually runs differs. That is the opposite of the toolbox's
  transparency selling point.

## The right model

`patch_nifti_version_check.m` is a **one-time maintenance tool for you**, not
part of the runtime. The workflow:

```matlab
% ONCE, on your machine, as maintainer:
patch_nifti_version_check('external/NIFTI_20130306')
% run the tests, confirm everything still works
% delete the .bak files
% git add external/NIFTI_20130306/*.m  &&  git commit
```

After that, the corrected files ARE the bundled files. Users receive
already-correct code and never run the patcher.

**Where the patcher lives afterwards:** keep it in a `maintenance/` or `tools/`
folder — outside `core/`, excluded from the released path and from `Contents.m`.
It documents what you changed in a third-party dependency and why, which is
useful if you ever re-import a fresh NIFTI copy and need to re-apply the fix.
Just make sure `fmritoolbox_setup.m` never calls it and it is never on the
default path.

## What SHOULD run at load time: a read-only check

`fmri_checknifti.m` (included) is the runtime counterpart. It **does not modify
anything** — it only checks and warns. Call it once from `fmritoolbox_setup.m`.
Its job is to catch the case where someone replaces your patched `external/`
folder with a fresh unpatched download, which would silently corrupt header
reads on R2023b+. It:

- warns if the NIFTI toolbox is missing from the path;
- warns if the version-check bug is still present, and says whether the current
  MATLAB release is actually affected.

So the division is clean:

| Tool | When | What it does | Ships to users |
|---|---|---|---|
| `patch_nifti_version_check.m` | once, by maintainer, offline | **writes** files | in maintenance/, off-path |
| `fmri_checknifti.m` | every load, from setup | **reads** and warns only | yes, on-path |

## Suggested addition to `fmritoolbox_setup.m`

After the path is set up, add:

```matlab
fmri_checknifti();   % read-only: warns if bundled NIFTI is missing/unpatched
```

That is all the runtime involvement the fix should have.
