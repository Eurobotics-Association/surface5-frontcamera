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

A 16-frame host capture confirmed image-bearing, changing frames at about
28--30 fps. The recurring SHA-256
`9ee1d13fd6ed345f060ab756351293df8c9fedf100c25a4366a9c249bc9c95f6` is exactly
the all-zero `frame-000001` startup frame (Y min/max/mean/stddev = 0/0/0/0,
one distinct value). It is transient and not frozen output; later frames vary.
Its origin remains a separate IPU3/libcamera/sensor-startup investigation.

This verifies the upstream DW9719 restoration on the target generic kernel.
It does **not** yet verify image quality, frame motion, PipeWire/application
use, or the IPA-tuning layer. No personal frame data is retained in Git.

### Follow-up execution limitation

The later follow-up commands ran in the agent's restricted mount namespace,
which overlays `/dev` with a private tmpfs. They can inspect the registered
sysfs endpoints but cannot access the host's `/dev/media*` or `/dev/video*`
nodes, so an empty `cam -l` result there is not evidence of a host graph
regression. The registered sysfs endpoints included all IPU3 video devices,
OV5693 as `v4l-subdev8`, and DW9719 as `v4l-subdev9`. Run further capture and
desktop validation from the normal host user session, not that restricted
namespace.

### Portable enumeration-test correction

`tests/enumeration.sh` had falsely reported a missing front camera in a
successful test environment solely because its `rg` command was unavailable.
It now uses standard `grep -qiE`; the direct `grep` match against `Internal
front camera` passes without `rg`. The supporting collection/build scripts also
now use `grep` instead of an unnecessary `rg` dependency. The corrected full
enumeration test must be rerun from the normal host user session; the restricted
agent namespace cannot access the host device nodes.

### Desktop-path inventory (not a usability claim)

The target packages include `pipewire-libcamera`, `xdg-desktop-portal`,
GStreamer `libcamerasrc`, and Cheese. No PipeWire, portal, browser, or
desktop-application result is recorded yet. Test the installed GStreamer path
first, then PipeWire/portal and a graphical application from the normal host
session where camera nodes are accessible.

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

## Desktop application evidence and remaining work

Cheese is verified to display usable live video from `Internal front camera`
when the operator selects it manually. Cheese initially chooses the rear
camera, whose image is currently unusable; this is application ordering, not a
reason to disable the rear camera. Its exact transport path is not yet claimed.

Changing OV5693 frames and repeated start/stop are verified. Browser/WebRTC
access is the remaining primary target: diagnose PipeWire libcamera exposure,
WirePlumber, portal, browser packaging, and site permissions without changing
the proven kernel workaround or camera drivers.

### Verified WirePlumber/portal recovery

At initial session startup WirePlumber received permission denied opening
`/dev/media0` and `/dev/media1`, skipped libcamera discovery, and did not later
recover when normal logind ACLs granted `aev` read/write access. After
`systemctl --user restart wireplumber`, it registered both `\_SB_.PCI0.I2C3.CAMR`
and `\_SB_.PCI0.I2C2.CAMF`; PipeWire gained both libcamera devices/sources,
the front source became default, and portal `IsCameraPresent` changed false to
true. This is verified stale WirePlumber state after startup-time ACL failure.
