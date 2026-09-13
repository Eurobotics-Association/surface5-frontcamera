# Upstream research

Research date: 2026-09-13. This document separates published claims from the
local evidence in [baseline.md](baseline.md). External reports are leads until
their relevant diff and local applicability are checked.

## Authoritative project status

The [linux-surface Camera Support wiki](https://github.com/linux-surface/linux-surface/wiki/Camera-Support)
lists Surface Pro 5 as IPU3 with OV5693 front and OV8865 rear support, while
warning that image quality/tuning remains incomplete. It explains that Surface
ACPI definitions require the CIO2 bridge. Its IPU3 hardware table maps SP5 to
OV5693 / OV8865 / OV7251 and maps OV5693's ACPI ID to `INT33BE`—all consistent
with this machine.

The wiki documents required IPU3 firmware and notes that Ubuntu-family systems
obtain it from linux-firmware. Local inspection confirms the expected firmware
payload is present and the IMGU driver is loaded. This rules out the most basic
missing-firmware explanation for the current no-node failure, but does not
prove processing succeeds.

## Confirmed: DW9719 I2C ID-table regression

Upstream commit
[`15faf0fa1472d1da301498a2e33cdaffe84bc4f1`](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=15faf0fa1472d1da301498a2e33cdaffe84bc4f1)
(`media: i2c: dw9719: Remove unused i2c device id table`) removed the I2C ID
table. Upstream commit
[`d7fe0d53b2a8b08f6042cc89315118dee49e072e`](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=d7fe0d53b2a8b08f6042cc89315118dee49e072e)
(`media: dw9719: Add back the I2C device id table`) restores it. The Ubuntu
Kernel Team's [HWE 7.0 SRU submission](https://lists.ubuntu.com/archives/kernel-team/2026-August/170639.html)
is an unmodified cherry-pick and explicitly links [Launchpad bug #2162045](https://bugs.launchpad.net/bugs/2162045).

The local normal repositories still have `7.0.0-31.31~24.04.1` as the candidate
for `linux-generic-hwe-24.04`, `linux-image-generic-hwe-24.04`, and
`linux-headers-generic-hwe-24.04`; no newer generic 7.x package is available.
The SRU therefore cannot yet be consumed as a normal system update here.

### Exact current-source comparison

The current module package is `linux-modules-7.0.0-31-generic`
`7.0.0-31.31~24.04.1`. The exact Ubuntu source tag is
`Ubuntu-hwe-7.0-7.0.0-31.31_24.04.1` (dereferenced commit
`cc909f9a3d277832d246c6493bbc06e0955cde2e`). This machine has no `deb-src`
repository, so the source package delta was downloaded directly from the
configured Ubuntu archive and audited. It does not touch
`drivers/media/i2c/dw9719.c`; the v7.0 base file is therefore the shipped file
for this driver.

Direct inspection of that source confirms it lacks all three required parts:

- `static const struct i2c_device_id dw9719_id_table[]`;
- `MODULE_DEVICE_TABLE(i2c, dw9719_id_table)`;
- `.id_table = dw9719_id_table` in `dw9719_i2c_driver`.

This agrees with the active built module's OF-only aliases and local
`i2c:dw9719` VCM modalias. It is a confirmed match to the regression, rather
than an inference from a kernel version alone.

[linux-surface PR #2123](https://github.com/linux-surface/linux-surface/pull/2123)
is open at the time of research. Its actual proposed diff restores a
`dw9719_id_table`, exports it with `MODULE_DEVICE_TABLE(i2c, ...)`, and assigns
it to the I2C driver's `.id_table`. The table includes `dw9719`, `dw9718s`,
`dw9761`, and `dw9800k`.

The linux-surface PR is corroborating community material. The primary fix for
this machine is the upstream commit above, applied to the exact Ubuntu 7.0
driver source. Its mechanism is independently verified on this computer:

| Kernel/module | `dw9719` aliases | Result |
| --- | --- | --- |
| Running `7.0.0-31-generic` | OF aliases only | Cannot match local `i2c:dw9719` VCM |
| Installed `6.18.7-surface-1` | includes `i2c:dw9719` | Has the necessary match alias |

The upstream fix is selected for an uninstalled, exact-header module build.
The 6.18 linux-surface module is comparison evidence only; no kernel downgrade
or 6.18 boot is part of this project plan.

The resulting external module was compiled successfully with the installed
`linux-headers-7.0.0-31-generic`. `modinfo` confirmed matching vermagic and all
four restored I2C aliases. It was inspected only; it has not been copied into
`/lib/modules`, loaded, or bound. This proves build/API compatibility and
expected module metadata, not hardware functionality.

The related [linux-surface issue #2225](https://github.com/linux-surface/linux-surface/issues/2225)
describes the same modalias mismatch and its effect on the asynchronous media
graph. It is useful corroboration but is a community issue report, not an
upstream merged fix.

## OV5693 stream-reconfiguration reports

Recent linux-surface discussion links mention a mode-programming/restart issue
for OV5693 and OV8865. The currently visible linux-surface pull-request index
shows a 6.19 OV8865 stale-mode patch, while a current OV5693 pull request is
explicitly for IPU6 Surface models, not this IPU3 Surface Pro 5. No compatible
IPU3/OV5693 stream-reconfiguration diff has yet been identified and audited
for this machine. It is therefore a test target—not a proposed fix.

Once the graph enumerates, `tests/capture.sh` and `tests/restart-stream.sh`
will test several negotiated sizes, multiple frames, hashes, and repeated
start/stop cycles. A one-frame or frozen-frame outcome must be recorded as a
separate post-enumeration defect.

## libcamera, PipeWire, and V4L2

The local `libcamera-tools`, IPA package, GStreamer `libcamerasrc`, PipeWire
libcamera SPA plugin, and V4L2 utilities are installed. In the initial state
they cannot help because there is no media graph. Current libcamera's
[IPU3 pipeline source](https://github.com/libcamera-org/libcamera/tree/master/src/libcamera/pipeline/ipu3)
and its [documentation](https://libcamera.org/docs.html) are relevant after
enumeration. Version `0.2.0` is materially older than current upstream, so a
later userspace upgrade can be considered only if a supported kernel graph
still fails in the libcamera layer.

V4L2 loopback is available locally but deliberately not loaded or configured.
It can provide compatibility for applications expecting a conventional webcam,
but it cannot create a camera from an absent CIO2 graph and is not part of the
initial repair.

## Rejected for now

- Third-party installers/DKMS recipes: not run. They can modify modules,
  initramfs, and boot behavior; each relevant modification needs source and
  compatibility review first.
- Updating to or booting a linux-surface kernel: not selected. The required
  final solution targets Ubuntu generic 7.x directly.
- New OV5693 driver work: unjustified. The sensor binds; a lower-layer graph
  blocker is observed first.
