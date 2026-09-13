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

## Candidate: DW9719 I2C ID-table regression

[linux-surface PR #2123](https://github.com/linux-surface/linux-surface/pull/2123)
is open at the time of research. Its actual proposed diff restores a
`dw9719_id_table`, exports it with `MODULE_DEVICE_TABLE(i2c, ...)`, and assigns
it to the I2C driver's `.id_table`. The table includes `dw9719`, `dw9718s`,
`dw9761`, and `dw9800k`.

The proposed patch is intended for linux-surface 6.19, not specifically the
Ubuntu 7.0 HWE package currently booted here. It must not be applied blindly
to a different kernel. However, its mechanism is independently verified on
this computer:

| Kernel/module | `dw9719` aliases | Result |
| --- | --- | --- |
| Running `7.0.0-31-generic` | OF aliases only | Cannot match local `i2c:dw9719` VCM |
| Installed `6.18.7-surface-1` | includes `i2c:dw9719` | Has the necessary match alias |

The PR is therefore highly applicable as an explanation of the active state,
but **not yet a selected backport**. The first experiment should use the
already installed kernel that demonstrably retains the matching alias. A
separate, source-level compatibility audit is required before building any
Ubuntu 7.0 replacement module.

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
- Updating to `6.19.8-surface-3`: not selected. The package is held and the
  documented DW9719 regression is specifically reported between 6.18 and 6.19.
- New OV5693 driver work: unjustified. The sensor binds; a lower-layer graph
  blocker is observed first.
