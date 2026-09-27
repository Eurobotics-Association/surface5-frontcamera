# Persistent project rules

- Target Ubuntu/Zorin generic kernel 7.x; current reference is
  `7.0.0-31-generic`. Do not switch permanently to linux-surface; it is a
  comparison reference only.
- Work directly on `main`, preserve GPL-2.0-only and upstream copyright/SPDX,
  commit useful verified milestones, and never commit images, raw frames,
  private logs, credentials, tokens, or host deployment traces.
- Privileged changes need explicit operator approval identifying purpose,
  exact command, expected result, verification, rollback, and risk.
- Validate moving non-black frames and restart/release behaviour. Enumeration,
  a live track, an LED, and dimensions are not sufficient evidence.
- Treat the first `7.0.0-31-generic` DW9719 module installation as a controlled
  experiment. Maintenance must inspect native aliases and never override a
  kernel that already exports `i2c:dw9719`; fail safely on ABI uncertainty.

## Browser camera deployment contract

The supported browser solution is the browser-neutral native V4L2 bridge,
`EBtx-surface5-HDCam-V4L2`, versioned in
`config/v4l2-deployment-version.env`. It converts the working
PipeWire/libcamera source to `Surface5_Front_Camera_HD` at `/dev/video20` and
is verified on the reference Surface Pro 5 with system Firefox and Brave. It
does not edit browser profiles, install browser flags, change ACLs, or persist
a PipeWire camera feature. The older browser-specific PipeWire virtual-camera
deployment is retired; never restore it as a hotfix.

- `./scripts/install-v4l2-camera.sh` is the sole supported entry point.
  Default `--system` self-elevates through `sudo` and installs guarded native
  module policy, global user unit, global Firefox/Brave menu entries, and
  diagnostic assets for all desktop users. `--user` requires system setup and
  installs only current-user menu/Desktop shortcuts. Desktop shortcuts are
  inherently per-user.
- The documented curl command must invoke `scripts/install-from-github.sh`,
  which downloads one complete source archive and then calls the versioned
  system installer through `sudo`. Never publish a raw download of only the
  main installer: its unit, configuration, desktop and diagnostic assets must
  come from the same revision.
- Every release bumps its version and retains `--version`, `--status`, and
  `--rollback`. A fully current deployment must be a true no-op. Preserve
  unrelated profiles/settings and keep product records only in
  `/etc/surface5-frontcamera/v4l2.env` and optionally
  `~/.local/share/surface5-frontcamera/v4l2-deployment.env`.
- A release needs repository install, repeat-install no-op, actual changing
  non-black 1280x720 WebRTC frames in Firefox and Brave, real-site visible
  video, shared Stop/LED release, and scoped rollback.
- The deployment installs `webrtc-camera-test.html` and its localhost server
  under `/usr/lib/surface5-frontcamera/tests/`. Its launcher uses a transient
  user service, opens the page, and saves only textual logs under
  `~/Pictures/surface5-frontcamera-tests/`. Use it before recreating any
  browser diagnostic. Never rely on shell-owned `/tmp` test sites.
- The V4L2 bridge is off until a browser/diagnostic launcher starts it. The one
  shared Stop entry stops `surface5-frontcamera-v4l2-bridge.service` and
  releases the physical camera. Do not introduce ACL hacks, polling loops, or
  unsafe device permissions.
- If the agent sees a private sandbox `/dev`, report that execution boundary;
  do not call it a host regression or claim GUI/browser success.

See `docs/v4l2-deployment.md` for users and
`docs/developer-deployment.md` for developers/AI.
