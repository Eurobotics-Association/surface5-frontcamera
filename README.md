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

The upstream DW9719 I2C ID-table restoration is **verified** on the target
kernel. The per-kernel `/updates/dkms/dw9719.ko` override bound the VCM,
completed the CIO2 graph, exposed OV5693 and `Internal front camera`, produced
1280x720 NV12 frame data, and completed five independent start/stop cycles.
No kernel switch or reboot was required.

This is not yet a claim that the camera is fully solved. The recurring
`frame-000001` is now identified as an all-zero startup frame, not frozen
output; subsequent frames vary normally. Cheese displays usable live front
video after manual selection. WirePlumber initially skipped media devices after
permission-denied discovery, but a user-service restart now exposes both
libcamera sources and makes the Camera portal present. Brave retesting and
automatic login-time recovery remain separate work.

A subsequent read-only snapshot found the VCM still bound but no media/video
nodes in the restricted agent execution namespace. That namespace overlays
`/dev` with a private tmpfs and cannot be used to judge the host camera graph;
the verified live result remains the relevant machine evidence. Follow-up
capture and desktop tests must run from the normal host user session. See
[docs/changes.md](docs/changes.md).

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
./scripts/status.sh
./tests/host-validation.sh
```

`host-validation.sh` must run in the normal host desktop session. It retains
private logs, raw frames, hashes, statistics, and selected JPEGs under
`~/Pictures/surface5-frontcamera-tests/<timestamp>/`; these images are never
committed and must be handled as personal data.

`capture.sh` records temporary raw frames only for objective checks (count,
size, SHA-256, Y-plane statistics, and duplicate-frame detection). It deletes
them by default; use `--keep` only when inspecting a local, private capture.

After the current kernel has passed the reviewed controlled test, the guarded
maintenance commands are:

```bash
./scripts/status.sh
sudo ./scripts/install.sh
sudo ./scripts/uninstall.sh
```

`install.sh` first examines the target kernel's packaged (non-override)
`dw9719` module. It does nothing when the packaged driver already advertises
`i2c:dw9719`; it currently refuses every unreviewed ABI except
`7.0.0-31-generic` rather than forcing an old source onto a later kernel.

## Safety

Only `scripts/install.sh`, `scripts/uninstall.sh`, and the historical
per-kernel installer are privileged helpers. Kernel changes, module
replacement, configuration changes, and reboots are always described with
verification and rollback before execution.

## Maintenance and community feedback

The generic installer inspects a target kernel's native `dw9719` module and
skips itself when the official fix is present, so it cannot mask a fixed Ubuntu
kernel. It is deliberately source/API-guarded while support for future ABIs is
reviewed. See [maintenance.md](docs/maintenance.md).

Verified findings will be prepared for the existing linux-surface and Ubuntu
bug discussions, but are never posted under an operator identity without
approval. See [community-report.md](docs/community-report.md).

## License

This project is GPL-2.0-only; the full text is in [COPYING](COPYING). The
vendored kernel-derived DW9719 driver preserves its upstream `GPL-2.0` SPDX
identifier and copyright notice. See [licensing.md](docs/licensing.md).
