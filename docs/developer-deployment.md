# Surface5 HD V4L2 deployment: developer and AI guide

The human guide is [V4L2 deployment](v4l2-deployment.md). This file is the
maintenance contract.

## Verified boundary

`EBtx-surface5-HDCam-V4L2` exposes `Surface5_Front_Camera_HD` at `/dev/video20`.
On the reference Surface Pro 5 / Ubuntu-or-Zorin generic 7.x stack, both
system Firefox and Brave produced changing non-black 1280×720 / 30 FPS WebRTC
frames and visible WebcamTests video. It is not evidence for a different
Surface sensor, distro release, or kernel without the same validation.

The user-session bridge reads
`libcamera_input.__SB_.PCI0.I2C2.CAMF`, fixes NV12 at 1280×720, converts it to
YUY2 and publishes it via the kernel-provided `v4l2loopback` module. This
replaces the old Firefox-only PipeWire/profile solution. Do not enable
Chromium's experimental `WebRtcPipeWireCamera`: it stalled enumeration on the
reference host.

## Ownership and scopes

`./scripts/install-v4l2-camera.sh` defaults to `--system` and owns only:

| Target | Purpose |
| --- | --- |
| `/etc/modprobe.d/`, `/etc/modules-load.d/` | Fixed native `/dev/video20` policy |
| `/etc/systemd/user/surface5-frontcamera-v4l2-bridge.service` | Per-login, on-demand bridge |
| `/usr/lib/surface5-frontcamera/` | Launch/Stop/diagnostic helpers and test assets |
| `/usr/share/applications/` | Global Firefox, Brave, Stop and diagnostic entries |
| `/etc/surface5-frontcamera/v4l2.env` | Product/version/kernel trace |

Optional `--user` owns only analogous user-unit, menu/Desktop launcher and
mode-600 record paths under `~/.config` and `~/.local/share`. It requires a
system loopback policy and must never alter a normal browser profile, package,
portal setting, or device ACL. System deployment uses global menu entries;
Desktop icons are necessarily opt-in per user.

`scripts/install-from-github.sh` is the supported curl bootstrap. It downloads
one complete GitHub source archive to a private temporary directory, verifies
that the V4L2 installer is present, and invokes that installer with `sudo`.
Do not document a curl download of `install-v4l2-camera.sh` alone: that script
needs its versioned unit, desktop, configuration and diagnostic assets from the
same source tree.

## Update, safety and rollback

Bump the source version for every released artifact/behaviour change. A fully
matching deployment must report `already-current` without restarting a stream
or rewriting files. Repair drift only through the installer. Never overwrite a
record for another product. `--rollback` stops the bridge and deletes only its
scope; system rollback leaves other users' Desktop state alone.

The native-module guard accepts only
`/lib/modules/<running-kernel>/kernel/v4l2loopback/…`; never install a DKMS
substitute automatically. Do not add world-writable nodes, permanent ACLs,
polling services, browser preferences, or permanent flags.

When migrating a user from the retired PipeWire deployment, remove only its
known units, isolated `firefox-pipewire-profile`, launchers and records—not an
ordinary profile.

## Durable WebRTC diagnostic

The source diagnostic is `tests/webrtc-camera-test.html` plus
`tests/browser-webrtc-server.py`; system deployment copies both into
`/usr/lib/surface5-frontcamera/tests/`. **Surface5 HD Camera Diagnostic** starts
the V4L2 bridge and a transient localhost server, then opens the page. It
avoids the prior failure where a shell-owned server vanished before Firefox
could connect.

The page must retain separate timeout-bound reports for enumeration before and
after permission, the permission probe, exact device choice, track details,
playback dimensions and four in-memory pixel samples. Passing requires
`allBlack:false` with changed frames. Logs are textual-only under
`~/Pictures/surface5-frontcamera-tests/`; never save image data or profiles.

## Release validation

Require: system install then a no-op repeat; Firefox and Brave permission/
selection; local changing-frame evidence; visible website video; shared Stop
LED release; and status/version/rollback scoped to owned paths. Keep outcomes
in `docs/changes.md` and never publish external reports or user data without
approval.
