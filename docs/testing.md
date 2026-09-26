# Testing

## Principles

Run tests as the desktop user. They do not need sudo and do not load modules,
modify media links, or retain imagery by default. A passing enumeration is not
a capture pass. Tests and the module build target Ubuntu generic
`7.0.0-31-generic`, not the installed linux-surface reference kernel.

## Baseline collection

```bash
./scripts/collect-baseline.sh
```

The script creates a timestamped report under `/tmp` unless `--output DIR` is
specified. It redacts the DMI serial number and records unavailable commands
or inaccessible kernel logs explicitly.

## Module inspection

```bash
./scripts/build-dw9719-7.0.sh
```

This builds the upstream DW9719 backport in an ignored workspace, checks the
exact target headers and vermagic, and fails unless `i2c:dw9719` is exported.
It neither installs nor loads the module.

The experimental privileged installer adds a second gate before copying a
module: it must find the packaged DW9719 module for `7.0.0-31-generic` and its
vermagic must equal the patched artifact after removal of trailing whitespace
only. This check is intentionally against the installed stock module, not an
assumed version string.

## Enumeration

```bash
./tests/enumeration.sh
```

Pass criteria: a media node exists, `cam -l` lists an Internal front camera,
and the OV5693 and CIO2 drivers are bound. The script emits a diagnostic report
even on failure.

## Frame capture and sanity

```bash
./tests/capture.sh --frames 8
./tests/capture.sh --width 1280 --height 720 --frames 16
```

The capture test chooses the front camera listed by `cam -l`, requests NV12 raw
frames with libcamera, and verifies command success, requested frame count,
nonzero and non-truncated NV12 file sizes, and that not every SHA-256 hash is
identical. It also reports Y-plane minimum, maximum, mean, standard deviation,
luminance diversity, black/near-uniform flags, and successive-frame
comparisons. Captures are kept only with `--keep`; no imagery belongs in Git.

All-black or near-uniform sequences and completely frozen Y-plane sequences
fail the test. A single suspicious frame or repeated first frame across fresh
cycles is explicitly reported but does not alone fail: repeat the test while
changing the scene to distinguish an initialization artifact from stale data.
These checks do not establish color calibration or visual quality; inspect a
private local capture separately if needed.

## Host validation and visual evidence

Run only in the normal Zorin desktop host session:

```bash
./tests/host-validation.sh
```

It retains private logs, raw NV12 frames, hashes, statistics, and JPEGs under
`~/Pictures/surface5-frontcamera-tests/<timestamp>/`, including frame 000000,
the `frame-000001-BLACK-STARTUP.jpg`, frame 000002, a middle frame, and a final
frame. It prints the exact path and an `xdg-open` command. Do not commit these
personal images or raw frames.

The known frame-000001 SHA-256 is
`9ee1d13fd6ed345f060ab756351293df8c9fedf100c25a4366a9c249bc9c95f6`; its Y
plane is entirely zero and is reported as a canonical startup frame, not frozen
output. Additional black/uniform frames and exact repeats remain diagnostics.

## Restart resilience

```bash
./tests/restart-stream.sh --cycles 5
```

This invokes a short front-camera capture in fresh processes for each cycle.
Pass criteria: every cycle succeeds and produces the requested number of
nonempty frames. Test at least two resolutions after basic capture passes.

## Application-facing validation

After native capture passes:

```bash
gst-launch-1.0 -e libcamerasrc ! queue ! fakesink num-buffers=30
pw-cli ls Node | grep -iE 'camera|libcamera|video'
```

Record return status and relevant output in `docs/changes.md`. Only test a
normal desktop application when a graphical session is available; do not claim
PipeWire or application success merely because the packages are installed.

On the target system `pipewire-libcamera`, `xdg-desktop-portal`, the
GStreamer libcamera plugin, and Cheese are installed. That only establishes the
available desktop path. A post-live-test snapshot has no PipeWire camera nodes
in the restricted agent namespace because that namespace overlays `/dev` with
a private tmpfs. It cannot judge the host pipeline. Run desktop validation from
the normal host user session with the verified camera graph available.

## Browser/WebRTC diagnostic

Run `./tests/browser-integration-diagnostics.sh` only in the normal desktop
host session. It is read-only and retains PipeWire, WirePlumber, portal,
package, browser-packaging, and filtered-log evidence below `~/Pictures/`.
Before testing webcamtests.com, ensure its browser camera permission is
**Allow**; do not erase browser settings or profiles.

For a deterministic browser-level control, run:

```bash
./tests/browser-webrtc-test.sh
```

Open the displayed `127.0.0.1` URL in exactly one browser and keep the helper
running while granting the browser prompt. The page separately time-bounds and
reports `mediaDevices`, enumeration before permission, `getUserMedia`,
enumeration after permission, track label/settings/capabilities, and actual
video dimensions after playback. It also samples four downscaled video frames
in memory and reports luminance extrema, mean, and whether pixels changed; an
`*_FRAME_PIXELS` result with `allBlack: true` is a failure even if the browser
reports a live track and non-zero dimensions. It stores no image data. Use
**Run permission-then-front test** after reloading the page to test the front
camera. Browser privacy rules may hide physical camera labels before the
localhost origin receives a `getUserMedia()` permission grant; the test records
that probe, releases it, and then makes an exact front-camera request. The
default-then-front control is kept to expose reconfiguration failures. When a post-permission label includes
`front`, it makes a second, exact-device request and reports that stream
separately. A timeout is recorded distinctly as
`ENUMERATE_BEFORE_TIMEOUT`, `GETUSERMEDIA_TIMEOUT`, or
`ENUMERATE_AFTER_TIMEOUT`. The helper stops its own localhost server when
interrupted and writes only textual HTTP/event logs below the private Pictures
test directory; it does not retain frames or alter browser profiles. Each run
also stops its browser stream before reporting `TEST_COMPLETE`, so it does not
leave the camera held for a following control.

**Run permission-then-front HD test** requests the exact 1280x720 front mode.
It is an investigation control, not a browser workaround: it determines
whether Firefox can consume the currently known-good native/PipeWire mode.

## System Firefox PipeWire deployment — experimental

The experimental path uses the system `firefox` executable, never a portable
browser or a normal Firefox profile. It installs the PipeWire preference only
in `~/.local/share/surface5-frontcamera/firefox-pipewire-profile`, enables the
repository's user-session recovery, and verifies the front source plus Camera
portal before reporting integration readiness. It does not validate image
pixels and must not be described as a deployable browser-camera solution until
the local diagnostic reports changing, non-black frames.

```bash
./scripts/install-firefox-pipewire.sh
./scripts/status-firefox-pipewire.sh
./scripts/launch-firefox-pipewire.sh https://fr.webcamtests.com/
```

At WebcamTests, grant the Firefox prompt, select `Built-in Front Camera`, and
click **Tester ma webcam**. The current reference host reaches this point but
WebcamTests receives all-black 1280x720 frames after repeated resolution
negotiation. The local `browser-webrtc-test.sh` is the programmatic pixel-flow
verification control. Roll back the managed profile and recovery unit with
`./scripts/uninstall-firefox-pipewire.sh`.

## Fixed-HD virtual camera bridge

The reference OV5693/IPU3 pipeline currently produces usable changing frames
at 1280x720 but all-black frames at its default 640x480 negotiation. The
Firefox installer deploys a user-level GStreamer/PipeWire bridge that keeps the
physical `libcamera_input.__SB_.PCI0.I2C2.CAMF` source at 1280x720 and exposes
the separate virtual source `Surface5_Front_Camera_HD`.

The bridge is user-owned, has no root privileges, changes no camera ACL or
browser profile, and has a paired status/uninstall path:

```bash
./scripts/install-user-hd-camera-bridge.sh
./scripts/status-user-hd-camera-bridge.sh
./scripts/uninstall-user-hd-camera-bridge.sh
```

Use it only on the validated Surface Pro 5 reference hardware. Select the
virtual source explicitly in the browser or conferencing application; do not
assume that a browser will prefer it over the physical cameras. Treat it as
experimental until installation, browser restart, and changing-pixel WebRTC
validation all pass.

After installation, use **Run virtual HD camera test** in the local WebRTC
diagnostic. It selects `Surface5_Front_Camera_HD` with ordinary device
selection rather than an exact resolution constraint; pass only when the
reported `VIRTUAL_HD_FRAME_PIXELS` samples are changing and non-black.

## WirePlumber graphical-session recovery

The target session reproduced a WirePlumber startup race: the service started
before the graphical logind ACL existed for `/dev/media0` and `/dev/media1`,
then never rediscovered libcamera after the ACL appeared. The repository unit
restarts WirePlumber once when `graphical-session.target` starts; it does not
change device permissions, poll, or run as root.

```bash
./scripts/install-user-camera-recovery.sh
./scripts/status-user-camera-recovery.sh
./scripts/uninstall-user-camera-recovery.sh
```

After installation, verify on the next logout/login (or reboot) that `wpctl
status -n` lists `libcamera_input.__SB_.PCI0.I2C2.CAMF` and the portal Camera
property is true without a manual restart.
