# Surface Pro 5 front camera on Linux

Reproducible work for the Microsoft Surface Pro 5 (1796) OV5693 front camera
on Zorin OS / Ubuntu generic kernels. The reference target is
`7.0.0-31-generic`; linux-surface is comparison evidence only, not the
solution.

## Install

For the default all-desktop-user installation, run this single command in a
terminal as an ordinary desktop user:

```bash
curl -fsSL https://raw.githubusercontent.com/Eurobotics-Association/surface5-frontcamera/main/scripts/install-from-github.sh | bash
```

The bootstrap downloads the complete repository archive from GitHub and then
runs its versioned system installer with `sudo`; the administrator password
prompt appears during installation. It installs the guarded native V4L2 policy,
the on-demand bridge, global Firefox/Brave Internet-menu entries, Stop entry,
and the browser diagnostic. It does not change normal browser profiles or
enable browser feature flags.

If you already cloned the repository, use the equivalent local command:

```bash
./scripts/install-v4l2-camera.sh
```

After installation, start **Firefox — Surface5 HD Front Camera** or **Brave —
Surface5 HD Front Camera**, allow the camera at the site, and select
`Surface5_Front_Camera_HD`. Use **Stop Surface5 HD Front Camera** when finished
to release the physical camera and turn off its LED.

## Current verified result

The upstream DW9719 I2C ID-table restoration gives the reference Surface a
complete CIO2/IMGU/libcamera graph and working front capture. Cheese displays
the physical front camera. Browser-compatible capture is the fixed-HD native
V4L2 camera `Surface5_Front_Camera_HD` at 1280×720.

It is verified with **system Firefox and Brave**: the repository WebRTC test
reported changing non-black 1280×720 / 30 FPS frames, and the operator
confirmed visible WebcamTests video in both. Direct physical browser capture
can negotiate a black/unstable 640×480 stream, so select
`Surface5_Front_Camera_HD` for calls.

This result is specific to the reference Surface Pro 5, OV5693/IPU3 graph, and
tested Ubuntu/Zorin stack. It is a safe starting point for compatible hosts,
not a guarantee for every Surface or Debian-based machine.

## Installation details

An administrator can also install the default all-desktop-user deployment from
a checked-out copy:

```bash
./scripts/install-v4l2-camera.sh
```

It requests `sudo` only for guarded native module policy and global menu
integration. It adds Internet-menu entries for Firefox, Brave, Stop and the
diagnostic. It never changes normal browser profiles or browser flags.

It is versioned and idempotent:

```bash
./scripts/install-v4l2-camera.sh --status
./scripts/install-v4l2-camera.sh --version
```

Desktop icons are per-user. A logged-in user can add that user's shortcuts
after system setup with `./scripts/install-v4l2-camera.sh --user`.

See [install, use and rollback](docs/v4l2-deployment.md).

## Verify

**Surface5 HD Camera Diagnostic** is installed with the deployment. It starts
the bridge, serves the repository timeout-bounded WebRTC page on localhost,
and logs only textual events under `~/Pictures/surface5-frontcamera-tests/`.
The `permission-then-virtual-hd` result must name the HD camera, show 1280×720
and report changing `FRAME_PIXELS` with `allBlack:false`. No frames are stored.

For source diagnostics:

```bash
./scripts/collect-baseline.sh
./tests/enumeration.sh
./tests/capture.sh --frames 8
./tests/restart-stream.sh --cycles 5
./tests/browser-webrtc-test.sh
./scripts/status.sh
```

## Roll back browser integration

```bash
./scripts/install-v4l2-camera.sh --rollback
./scripts/install-v4l2-camera.sh --user --rollback  # optional per-user icons
```

Rollback removes only project policy, units, launcher assets, menu entries and
trace. It does not remove browsers, normal profiles, private tests, or
unrelated configuration.

## Repository map

- [Browser deployment](docs/v4l2-deployment.md)
- [Developer and AI maintenance contract](docs/developer-deployment.md)
- [Diagnostics and test procedure](docs/testing.md)
- [Stack architecture](docs/architecture.md)
- [Baseline facts](docs/baseline.md)
- [Verified changes](docs/changes.md)
- [Kernel/module maintenance](docs/maintenance.md)
- [Rollback](docs/rollback.md)
- [Licensing](docs/licensing.md)

## License

GPL-2.0-only; see [COPYING](COPYING). Vendored kernel-derived DW9719 code
keeps its upstream SPDX and copyright notices.
