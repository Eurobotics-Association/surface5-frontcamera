# Surface Pro 5 front camera on Linux

Reproducible investigation of the Microsoft Surface Pro 5 (model 1796) front
camera (OmniVision OV5693) on Zorin OS.

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

The next safe experiment is documented in [docs/changes.md](docs/changes.md):
boot the already installed linux-surface kernel once and run the test suite. It
requires an operator-approved reboot, makes no package or configuration change,
and preserves the generic kernel as a fallback.

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
```

`capture.sh` records temporary raw frames only for objective checks (count,
size, SHA-256, and duplicate-frame detection). It deletes them by default;
use `--keep` only when inspecting a local, private capture.

## Safety

No installer in this repository performs privileged actions. Kernel changes,
module replacement, configuration changes, and reboots are always described
with verification and rollback before execution.
