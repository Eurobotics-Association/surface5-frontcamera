# Testing

## Safety boundary

Run camera/browser tests in the normal graphical host session. An automated
agent may have a private `/dev`; absence of camera nodes there is not evidence
of host regression. Private artifacts belong only under
`~/Pictures/surface5-frontcamera-tests/`; never commit images, frames, profiles
or logs containing personal data.

## Kernel and libcamera controls

```bash
./scripts/collect-baseline.sh
./tests/enumeration.sh
./tests/capture.sh --frames 8
./tests/restart-stream.sh --cycles 5
./tests/host-validation.sh
```

Cheese and direct 1280×720 libcamera capture are physical-camera controls.
The direct 640×480 browser path can be black on this host; browser support uses
the fixed-HD V4L2 bridge instead.

## Installed browser diagnostic

Install once with `./scripts/install-v4l2-camera.sh`, then open **Surface5 HD
Camera Diagnostic**. It starts the bridge and a transient localhost server,
opens `webrtc-camera-test.html`, and saves textual events only. Do not recreate
ad-hoc `/tmp` HTML pages or terminal-owned HTTP servers.

Use `permission-then-virtual-hd`. It reports device enumeration before/after
permission, a permission probe, exact camera selection, `getUserMedia`, track
settings/capabilities, playback dimensions, separate timeouts, and four
in-memory frame samples. Pass only when `Surface5_Front_Camera_HD` is 1280×720
and `FRAME_PIXELS` has changed frames with `allBlack:false`.

Run it in both Firefox and Brave after browser updates, then check visible
moving video at a real call site. Use **Stop Surface5 HD Front Camera** after
testing; it releases the bridge and should turn off the LED.

## Deployment regression checks

```bash
bash -n scripts/install-v4l2-camera.sh scripts/desktop-launch-v4l2-browser.sh \
  scripts/desktop-stop-surface5-hd-camera.sh scripts/launch-v4l2-camera-diagnostic.sh
./tests/v4l2-deployment.sh
./scripts/install-v4l2-camera.sh --status
```

Before a release validate initial install, a genuine no-op repeat, both browser
launchers, changing frames, real-site video, Stop/LED release, and scoped
system/user rollback. Profile edits, persistent browser flags, manual portal
changes, and temporary servers are diagnostic-only, never deployment fixes.
