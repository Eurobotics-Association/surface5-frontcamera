# Firefox HD front-camera deployment

## Supported scope

This deployment is verified only for the reference Microsoft Surface Pro 5
(model 1796) on the documented Ubuntu/Zorin generic-kernel stack. It supports
the system `firefox` executable. It does not support Brave, other Surface
models, other camera sensors, or arbitrary Debian/Ubuntu installations merely
because they use PipeWire.

The Surface Pro 5 physical front source is black when an application negotiates
its ordinary 640x480 route. The deployment exposes a separate fixed-HD source,
`Surface5_Front_Camera_HD`, which keeps the physical source at 1280x720. This
is the source to select in Firefox or a video-call website.

## Prerequisites

- Run as the logged-in graphical desktop user; do not use `sudo`.
- The repository's kernel/camera prerequisites must already be satisfied.
- `firefox`, PipeWire, WirePlumber, the desktop portal, and GStreamer's
  `pipewiresrc` and `pipewiresink` plugins must be available.
- This is a reference-specific deployment. Confirm the source and portal with
  `./scripts/status-firefox-pipewire.sh` before relying on it.

The installer reports both detected browsers. A detected Brave installation is
reported as unsupported; it is not configured or modified.

## Install

From a checkout of this repository:

```bash
./scripts/install-firefox-pipewire.sh
```

The idempotent user-level installer validates its prerequisites before it
changes anything. It creates only these project-owned items:

- an isolated Firefox profile under
  `~/.local/share/surface5-frontcamera/firefox-pipewire-profile`;
- the repository's WirePlumber recovery and fixed-HD bridge user services;
- two application-menu entries and their small launch helpers under
  `~/.local/share/surface5-frontcamera/` and `~/.local/share/applications/`.
- matching executable Start and Stop shortcuts in the desktop directory
  configured by `xdg-user-dir DESKTOP`.

It does not modify Firefox's normal profile, a browser package, global camera
permissions, device ACLs, or the kernel. The HD bridge is installed inactive,
so it does not hold the camera or light its LED at login.

## Use

Open **Firefox — Surface5 HD Front Camera** from the desktop application's
Network/Internet category. The separate **Stop Surface5 HD Front Camera**
entry is in Utilities.

The Firefox entry starts the bridge, then opens the isolated Firefox profile.
On a WebRTC
site, grant Firefox's camera permission and select
**Surface5_Front_Camera_HD**. Do not select **Built-in Front Camera** for a
call: its normal 640x480 route is the known-black path on this reference host.

The launcher starts Firefox in a project-named **transient user service**.
That service keeps Firefox alive after the short menu/Desktop action exits and
is automatically removed when Firefox closes. This is deliberate: on the
reference Zorin GNOME Wayland session, directly launching Firefox from a
custom application-menu scope caused the Camera portal to reject its permission
dialog before Firefox could access the virtual source. The repository-installed
transient-service launch path was verified at WebcamTests with real 1280x720,
29 FPS RGB video.

When the call is finished, open **Stop Surface5 HD Front Camera** from the
application menu. It stops the bridge, removes the virtual source, releases
the physical camera, and turns off its privacy LED. Closing a browser tab alone
does not stop a running bridge, by design: a virtual PipeWire source is a
separate camera client.

## Verify and troubleshoot

For installation state:

```bash
./scripts/status-firefox-pipewire.sh
```

For a browser-level moving-frame test, run:

```bash
./tests/browser-webrtc-test.sh
```

Open its localhost URL in the managed Firefox launcher, choose **Run virtual
HD camera test**, and pass only if `VIRTUAL_HD_FRAME_PIXELS` is non-black with
changing frames. The page stores only textual results; it never records camera
images.

If the source does not appear, use the desktop stop entry, then run the status
command. Do not use `chmod`, broad device ACL changes, ad-hoc Firefox
preferences, or a manual PipeWire pipeline as a substitute for this deployment.

If Firefox reports `NotAllowedError` and the user journal contains `Only the
focused app is allowed to show a system access dialog`, the request was denied
by the GNOME Camera portal before it reached the virtual source. Use the
repository-installed Start launcher, focus Firefox, reload the page, and start
its camera test from that focused window. Do not bypass the portal or add
permanent permission-store entries as a workaround.

## Roll back

```bash
./scripts/uninstall-firefox-pipewire.sh
```

This removes only the managed profile, project-owned desktop entries/helpers,
and project-owned user services. It leaves Firefox, unrelated Firefox profiles,
browser packages, and camera permissions intact.

## Maintainer and AI contract

Treat this as a deployable product feature, not a host-specific hotfix. Keep
installation, status, desktop-launcher, and uninstall paths versioned together.
Do not claim browser support for a new device, OS stack, or browser until the
repository installation, a browser restart, actual changing-frame WebRTC
playback, and rollback have all been verified.
