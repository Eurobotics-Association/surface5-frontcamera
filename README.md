# Surface Pro 5 front camera on Linux

Reproducible investigation of the Microsoft Surface Pro 5 (model 1796) front
camera (OmniVision OV5693) on Zorin OS.

## Design target

```text
Microsoft Surface Pro 5 (1796)
Zorin OS 18.1 / Ubuntu 24.04 base
Ubuntu generic kernel 7.x
Current development target: 7.0.0-31-generic
```

The older installed `6.18.7-surface-1` linux-surface kernel is a source and
module comparison reference only. It is **not** this project's intended
solution and must not become the permanent camera kernel.

## Current status

The initial baseline was collected on 2026-09-13. The camera is **not
functional in the currently booted kernel**: no media or video device nodes
exist, so libcamera and PipeWire enumerate no cameras.

The evidence currently points to a kernel-driver binding regression, not a
missing OV5693 driver: the running Ubuntu `7.0.0-31-generic` kernel creates an
`i2c:dw9719` focus-motor device but its `dw9719` module does not advertise the
matching I2C alias. The installed, unbooted `6.18.7-surface-1` linux-surface
kernel does advertise that alias. This is a diagnosis, not a claimed repair:
no camera capture has yet succeeded.

The immediate repair path is an uninstalled build of the minimal upstream
DW9719 fix against the current 7.0.0-31 headers. Its inspection and any live
test are documented in [docs/changes.md](docs/changes.md); no kernel switch,
module installation, or reboot has been performed.

## Repository map

- [Baseline facts](docs/baseline.md)
- [Stack architecture](docs/architecture.md)
- [Upstream research and patch audit](docs/research.md)
- [Diagnostics and test procedure](docs/testing.md)
- [Change plan and results](docs/changes.md)
- [Rollback](docs/rollback.md)

## Reproducible commands

All scripts run as the normal user and write their output outside the Git tree
by default.

```bash
./scripts/collect-baseline.sh
./tests/enumeration.sh
./tests/capture.sh --frames 8
./tests/restart-stream.sh --cycles 5
./scripts/build-dw9719-7.0.sh
```

`capture.sh` records temporary raw frames only for objective checks (count,
size, SHA-256, and duplicate-frame detection). It deletes them by default;
use `--keep` only when inspecting a local, private capture.

## Safety

No installer in this repository performs privileged actions. Kernel changes,
module replacement, configuration changes, and reboots are always described
with verification and rollback before execution.

## Maintenance and community feedback

The current per-kernel install helper is only for the first controlled live
test. A final installer will inspect a target kernel's native `dw9719` module
and skip itself when the official fix is present, so it cannot mask a fixed
Ubuntu kernel. See [maintenance.md](docs/maintenance.md).

Verified findings will be prepared for the existing linux-surface and Ubuntu
bug discussions, but are never posted under an operator identity without
approval. See [community-report.md](docs/community-report.md).

## License

This project is GPL-2.0-only; the full text is in [COPYING](COPYING). The
vendored kernel-derived DW9719 driver preserves its upstream `GPL-2.0` SPDX
identifier and copyright notice. See [licensing.md](docs/licensing.md).
