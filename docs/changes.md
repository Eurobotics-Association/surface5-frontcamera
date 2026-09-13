# Changes and experiment log

## 2026-09-13 — Initial read-only baseline

No system state was changed. The repository gained documentation and
non-privileged diagnostics only. The active Ubuntu HWE 7.0 kernel has an
unbound `i2c:dw9719` VCM and no media/video nodes. See
[baseline.md](baseline.md).

## 2026-09-13 — Target changed to Ubuntu generic 7.x only

The permanent target is `7.0.0-31-generic`; `6.18.7-surface-1` is not a
solution or planned boot target. It remains useful only because its exported
`i2c:dw9719` alias provides a local pre-regression comparison.

The normal configured Ubuntu/Zorin repositories offer no newer generic 7.x
candidate: the installed and candidate HWE meta packages are all
`7.0.0-31.31~24.04.1`. The Ubuntu Kernel Team has submitted the upstream fix
for SRU, but it is not yet available from these repositories.

Secure Boot is disabled and the platform is in Setup Mode. No signing or MOK
enrollment is required for a live test on the machine's current security
state; that fact must be rechecked before any future test.

## 2026-09-13 — Exact 7.0 module source prepared

The source tagged `Ubuntu-hwe-7.0-7.0.0-31.31_24.04.1` was compared with the
installed `linux-modules-7.0.0-31-generic` package. Its package delta does not
modify `drivers/media/i2c/dw9719.c`, which lacks the I2C table. The repository
vendors that exact GPL driver with only upstream commit
`d7fe0d53b2a8b08f6042cc89315118dee49e072e` added. The original upstream patch
is retained under `patches/`.

Build, without installing anything:

```bash
./scripts/build-dw9719-7.0.sh
```

Required success evidence is a module whose `modinfo` output includes
`alias: i2c:dw9719`, plus the other restored I2C aliases. Build artifacts stay
under ignored `build/` paths and are not installed or loaded.

Build result: passed on this machine using the installed
`linux-headers-7.0.0-31-generic` package. The artifact's vermagic was exactly
`7.0.0-31-generic SMP preempt mod_unload modversions` and it advertised
`i2c:dw9718s`, `i2c:dw9719`, `i2c:dw9761`, and `i2c:dw9800k`. The compiler and
GCC major/minor version matched the kernel build; the header build emitted a
non-fatal executable-name warning and skipped BTF because no `vmlinux` image is
present. Neither affects module loading or aliases. No `dkms` package is
installed, so the reviewed source contains a DKMS configuration for a later,
operator-approved persistent setup but the current test uses no DKMS install.

## 2026-09-13 — DW9719 live test verified on Ubuntu generic 7.0

The controlled live test was performed on this Surface Pro 5 while running
Zorin OS 18.1 (Ubuntu 24.04 base), `7.0.0-31-generic`. The local
`/updates/dkms/dw9719.ko` was selected instead of the packaged module. The
patched driver bound to `i2c-INT347A:00-VCM` and the CIO2 graph completed.

Verified results from that test:

- `dw9719 3-000c` appeared as a Lens subdevice;
- OV5693 appeared in the media graph;
- libcamera registered `Internal front camera`;
- a 1280x720 NV12 capture produced frame data;
- five independent stop/start capture cycles completed.

This verifies the upstream DW9719 restoration on the target generic kernel.
It does **not** yet verify image quality, frame motion, PipeWire/application
use, or the IPA-tuning layer. No personal frame data is retained in Git.

### Post-test state drift

A later read-only snapshot found the VCM still bound and camera modules loaded,
but `/dev/media*` and `/dev/video*` absent; `cam -l` again reported no cameras.
`cam` specifically warned that `/dev/media0` and `/dev/media1` should exist
but do not. No module or kernel action was taken during that inspection. This
conflicts with the successful live-test graph and is an unresolved
reproducibility/state issue, not a retraction of the observed success. A
controlled reprobe and fresh statistics capture are required before declaring
robust operation.

### Portable enumeration-test correction

`tests/enumeration.sh` had falsely reported a missing front camera in a
successful test environment solely because its `rg` command was unavailable.
It now uses standard `grep -qiE`; the direct `grep` match against `Internal
front camera` passes without `rg`. A rerun at the later drift snapshot correctly
fails for the actual missing media nodes and empty `cam -l` result, rather than
for a missing text-search dependency. The supporting collection/build scripts
also now use `grep` instead of an unnecessary `rg` dependency.

### Desktop-path inventory (not a usability claim)

The target packages include `pipewire-libcamera`, `xdg-desktop-portal`,
GStreamer `libcamerasrc`, and Cheese. During the later missing-media-node
snapshot, PipeWire had no camera/libcamera/video node and `cam -l` was empty,
so no PipeWire, portal, browser, or desktop-application result is recorded.
Once the graph is restored, test the installed GStreamer path first, then
PipeWire/portal and a graphical application.

## Historical controlled live-test procedure

This procedure was used for the verified first live test. It remains useful
for a controlled reproduction, but is no longer described as pending.
It installs one external module under `/lib/modules`, updates module dependency
metadata, and binds the existing VCM on the running kernel. It does not install
another kernel, unload camera modules, or reboot.

PURPOSE:
Replace only the active kernel's DW9719 module with the reviewed upstream
backport, then bind the existing IPU3 VCM on `7.0.0-31-generic`.

COMMAND:
```bash
cd /home/aev/Github/surface5-frontcamera
sudo ./scripts/install-dw9719-7.0.sh \
  /home/aev/Github/surface5-frontcamera/build/dw9719-7.0.0-31-generic.XXXXXX/dw9719.ko
sudo modprobe dw9719
```

Replace `XXXXXX` with the exact inspected build directory printed by the build
script. The installer locates the packaged DW9719 module below the target
kernel's `kernel/drivers/media/i2c/` tree, compares its vermagic with the
patched artifact, and normalizes only trailing whitespace before requiring an
exact match. Do not run while a camera application is active.

EXPECTED RESULT:
`dw9719` binds to `i2c-INT347A:00-VCM`; its asynchronous registration completes
the already registered CIO2 notifier and creates media/video nodes. This may
reveal a separate OV5693 or userspace streaming issue, which must be diagnosed
independently.

VERIFICATION:
```bash
test -L /sys/bus/i2c/devices/i2c-INT347A:00-VCM/driver
modinfo dw9719 | grep '^alias:.*i2c:dw9719'
./tests/enumeration.sh
./tests/capture.sh --frames 8
./tests/restart-stream.sh --cycles 5
```

ROLLBACK:
```bash
sudo ./scripts/uninstall-dw9719-7.0.sh
sudo reboot
```

The reboot loads the packaged Ubuntu module again, returning to the known
broken-but-original driver state. No kernel package, boot entry, initramfs, or
Secure Boot setting is changed by the procedure.

RISK:
The test dynamically binds a VCM to the existing camera stack. A failed graph
completion may require the rollback reboot. The procedure must not be run while
a camera application is active; it must never use forced module removal.

## Pending results

Pixel-level validity, repeated-first-frame characterization, graph persistence,
and normal desktop camera-path validation remain outstanding. Do not mark the
front camera fully fixed until those checks pass.
