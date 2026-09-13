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
