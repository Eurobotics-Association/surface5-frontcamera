# Testing

## Principles

Run tests as the desktop user. They do not need sudo and do not load modules,
modify media links, or retain imagery by default. A passing enumeration is not
a capture pass.

## Baseline collection

```bash
./scripts/collect-baseline.sh
```

The script creates a timestamped report under `/tmp` unless `--output DIR` is
specified. It redacts the DMI serial number and records unavailable commands
or inaccessible kernel logs explicitly.

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

The capture test chooses the front camera listed by `cam -l`, captures raw
frames with libcamera, and verifies command success, requested frame count,
nonzero file sizes, and that not every SHA-256 hash is identical. Captures are
kept only with `--keep`; no imagery belongs in Git.

These checks detect zero-byte and frozen-output patterns objectively. They do
not establish color calibration or visual quality; inspect a private local
capture separately if needed.

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
pw-cli ls Node | rg -i 'camera|libcamera|video'
```

Record return status and relevant output in `docs/changes.md`. Only test a
normal desktop application when a graphical session is available; do not claim
PipeWire or application success merely because the packages are installed.
