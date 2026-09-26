# Firefox HD-camera deployment: developer and AI guide

This document is the maintenance contract for the deployable browser
integration. It is intentionally more technical than the
[Firefox user guide](firefox-deployment.md). Do not make users perform these
steps manually; the supported user entry point remains the versioned installer.

## Verified scope and current boundary

The verified product is **system Firefox** on the reference Microsoft Surface
Pro 5 (model 1796), Ubuntu/Zorin generic-kernel stack. It provides the virtual
camera `Surface5_Front_Camera_HD`, which pins the physical OV5693 front-camera
source at 1280x720 to avoid the known black 640x480 route.

Actual Firefox WebRTC validation has shown changing, non-black 1280x720 frames
and visible video at WebcamTests. This does not generalize to another Surface
model, sensor, PipeWire/libcamera stack, or Debian/Ubuntu release.

Brave is detected by the installer but is **not supported**. Do not infer
Brave support from the virtual source or from Firefox success. Any Brave work
must be isolated, reversible, and independently validated with changing
frames before deployment is proposed.

## Product identity and local deployment trace

`config/deployment-version.env` is the repository source of truth:

```text
DEPLOYMENT_PRODUCT=EBtx-surface5-HDCam-patch
DEPLOYMENT_VERSION=1.0.260926
```

The installer writes this local, user-owned record:

```text
~/.local/share/surface5-frontcamera/deployment.env
```

It is mode 600 and contains:

```text
DEPLOYMENT_PRODUCT=...
DEPLOYMENT_VERSION=...
DEPLOYMENT_REVISION=...
DEPLOYMENT_INSTALLED_AT=...
```

The record is a deployment trace, not proof of camera operation. It contains
host state and must never be committed. Preserve the product identifier during
an ordinary update; change it only for a genuinely distinct deployment product.
Bump the version for every released deployment behavior or artifact change.

## Owned component map

The Firefox integration is user-level and owns only the following paths. All
must have a matching install, status, and rollback path.

| Repository source | Installed target | Purpose |
| --- | --- | --- |
| `config/firefox/firefox-pipewire-user.js` | `~/.local/share/surface5-frontcamera/firefox-pipewire-profile/user.js` | Isolated Firefox PipeWire preference |
| `systemd/user/surface5-wireplumber-camera-recovery.service` | `~/.config/systemd/user/` | User-session discovery recovery |
| `systemd/user/surface5-frontcamera-hd-bridge.service` | `~/.config/systemd/user/` | Fixed-HD PipeWire virtual source |
| `scripts/desktop-launch-firefox-hd-camera.sh` | `~/.local/share/surface5-frontcamera/bin/` | Starts bridge and managed Firefox |
| `scripts/desktop-stop-firefox-hd-camera.sh` | `~/.local/share/surface5-frontcamera/bin/` | Stops bridge and releases physical source |
| `desktop/*.desktop` | `~/.local/share/applications/` | Application menu entries |
| Start/Stop desktop entries | `$(xdg-user-dir DESKTOP)` | Discoverable Desktop shortcuts |
| generated deployment record | `~/.local/share/surface5-frontcamera/deployment.env` | Local deployment trace |

Do not write the normal Firefox profile, browser packages, global portal
permissions, udev/logind ACLs, `/dev` permissions, or system-wide services.

## Supported interfaces and update behavior

The sole user deployment interface is:

```bash
./scripts/install-firefox-pipewire.sh
```

It also provides these stable interfaces:

```bash
./scripts/install-firefox-pipewire.sh --version
./scripts/install-firefox-pipewire.sh --status
./scripts/install-firefox-pipewire.sh --rollback
```

`--rollback` delegates to the dedicated Firefox uninstall script and removes
only the owned components above. It must stop the bridge before removal, so the
physical source and privacy LED are released. Never replace rollback with broad
configuration cleanup.

The install algorithm is a safety property, not an optional convenience:

1. Check prerequisites and identify Firefox/Brave without changing Brave.
2. If every owned component matches and the trace matches the current product
   and version, print `already-current` and change nothing. In particular, do
   not restart WirePlumber, interrupt the bridge, or rewrite files during a
   current no-op.
3. If every component matches but the trace is absent or stale for the same
   product, write only the current trace and report `adopted-current`.
4. If an owned component is absent or differs, run the normal versioned repair
   path. Tell the user to do this outside an active call because recovery can
   restart WirePlumber.
5. If the trace identifies another product, fail safely and require inspection;
   never overwrite it automatically.

When changing deployment code or artifacts, update the version file and test
the no-op, adoption, repair, status, and rollback paths. A status-script-only
change need not force a host rewrite, but its release/documentation state must
not be misrepresented as a camera validation.

## Why the Firefox launcher is a transient user service

The menu and Desktop launcher call the versioned helper, which starts Firefox
in a project-named transient user service. The service is collected when
Firefox exits. This is intentional and must remain declarative and scoped.

On the reference Zorin GNOME Wayland session, a direct Firefox launch inherited
the custom application-menu scope. The Camera portal then rejected the
permission request with a focus-association failure, including `Only the
focused app is allowed to show a system access dialog`. The transient-service
path was verified to allow the managed Firefox window to receive camera
permission and real video. Do not work around this by adding permanent portal
permissions, editing the normal Firefox profile, or asking users to launch
ad-hoc commands.

## Release validation

Before calling a change deployable, perform and record only non-sensitive
evidence for all relevant checks:

1. Repository installation succeeds for the logged-in desktop user without
   `sudo`.
2. A second install is a genuine no-op and does not restart WirePlumber or
   disrupt an active bridge/call.
3. The Network/Internet launcher and Desktop Start shortcut open the managed
   Firefox path; the Stop entry and Desktop shortcut release the bridge and
   LED.
4. The repository WebRTC test obtains `Surface5_Front_Camera_HD` at 1280x720
   and reports changing, non-black in-memory frame statistics. Enumeration or
   video dimensions alone are insufficient.
5. A normal browser restart and a real WebRTC website work using the virtual
   source.
6. `--status`, `--version`, and `--rollback` describe and remove only the
   product-owned deployment. Normal Firefox remains usable after rollback.

Keep textual logs under `~/Pictures/surface5-frontcamera-tests/` when needed.
Never retain or commit camera imagery, raw frames, secrets, tokens, normal
browser profiles, or host deployment traces.

## Browser expansion protocol

Firefox is the working control. Preserve it while testing Brave or another
browser. Use one hypothesis at a time, a disposable browser profile, and a
temporary/reversible launch path. Verify portal behavior, device enumeration,
exact virtual-camera selection, video playback, and changing frames.

Do not install a browser flag, preference, portal entry, or launcher until it
passes the complete release-validation sequence above. A detected executable,
an enabled permission toggle, a live track, an LED, or a nominal resolution is
not enough: the evidence must prove moving image data.

For Brave experiments, use the repository control harness rather than a manual
command:

```bash
./tests/brave-disposable-webrtc.sh --close-existing
./tests/brave-disposable-webrtc.sh --pipewire-camera --close-existing
```

Each invocation closes Brave only after the explicit `--close-existing` opt-in,
uses a new temporary profile, starts the already-installed HD bridge, and
removes that profile and releases the bridge when the temporary Brave window
closes. The second command enables Chromium's experimental
`WebRtcPipeWireCamera` feature for that one process only. It is an experiment,
not an installation or supported configuration.

On the reference host with Brave `154.1.96.59`, the normal control produced
zero video inputs and `NotFoundError`; the `WebRtcPipeWireCamera` control
timed out during enumeration and the permission probe. Neither control reached
video delivery. Treat this as a documented Chromium/Brave boundary until a new
version passes the full moving-frame validation sequence.

If the terminal running a temporary test is interrupted while the browser is
still open, clean up only that recorded control with:

```bash
./tests/brave-disposable-webrtc.sh --stop
```
