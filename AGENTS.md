# Persistent project rules

- Target Ubuntu/Zorin generic kernel 7.x; current reference is
  `7.0.0-31-generic`.
- Do not solve the camera issue by downgrading to or permanently switching to
  the linux-surface 6.18 kernel. It is a comparison reference only.
- Work directly on `main` unless an experiment genuinely needs isolation.
- Commit and push useful milestones regularly.
- Privileged system changes require explicit operator approval with purpose,
  command, expected result, verification, rollback, and risk.
- Never commit captured personal camera imagery or machine secrets.
- Prefer minimal fixes with upstream provenance.
- Every installed fix needs documented rollback.
- Validate actual moving frames and restart resilience; enumeration alone is
  insufficient.
- Prepare verified results for existing upstream/community discussions. Do not
  create duplicate reports or post externally under the operator's identity
  without explicit approval; never post speculative results or personal data.
- Keep licensing explicit: kernel-derived code and derivative patches remain
  GPL-2.0-only as required by their upstream provenance; original project
  kernel tooling is GPL-2.0-only unless documented otherwise.
- Treat the first `7.0.0-31-generic` module install as a controlled experiment,
  not final deployment. Future maintenance tooling must inspect each target
  kernel's native `dw9719` aliases and never override a kernel that already
  exports `i2c:dw9719`; fail safely on API incompatibility.
- Browser integration is a deployable product feature, never a host-specific
  hotfix. Any persistent browser, PipeWire, portal, WirePlumber, Firefox, or
  Flatpak configuration must be installed only through a versioned repository
  script and have matching status and uninstall/rollback commands.
- A browser deployment script must be idempotent, validate prerequisites and
  supported scope before changing anything, use narrowly defined user or
  system paths, preserve unrelated browser profiles/settings, and document
  every change it makes. One-off commands, manual preference edits, and
  untracked profile changes are diagnostic-only and must not be presented as a
  solution.
- Before describing browser support as deployable, validate installation from
  the repository, actual front-camera WebRTC playback, browser restart, and
  documented rollback. The README must provide a short supported-hardware/OS
  statement, prerequisites, install, verification, limitations, and uninstall
  path suitable for another user.
- User-facing browser deployment must provide a discoverable desktop launcher
  when the supported browser is installed, plus a visible, non-terminal way to
  stop a camera bridge that keeps the physical device open. Both launchers must
  be installed and removed only by the versioned deployment scripts.
- Report all detected browsers during deployment. A detected unsupported
  browser is diagnostic information, not permission to enable or claim support
  for it.
- Every user-facing browser deployment must have a versioned product identity,
  an inspectable user-owned deployment record, an idempotent no-op path for
  already-current components, and a scoped rollback entry point. A version
  record is evidence of deployment state, never evidence of camera-frame
  correctness.

## Deployable Firefox integration: durable maintenance contract

The currently verified browser solution is deliberately narrow: **system
Firefox** on the reference Surface Pro 5 / Ubuntu-or-Zorin stack, using the
fixed-HD virtual source `Surface5_Front_Camera_HD`. It is a supported Firefox
workaround, not a general Debian/Ubuntu installer and not evidence that Brave
works. Keep the user-facing instructions short in
`docs/firefox-deployment.md`; keep implementation, update, and diagnostic
details in `docs/developer-deployment.md`.

- The source of truth for the deployed product identity is
  `config/deployment-version.env` (currently
  `EBtx-surface5-HDCam-patch 1.0.260926`). Bump the version for a released
  deployment change; do not put host-specific state in Git.
- The installer-owned trace is
  `~/.local/share/surface5-frontcamera/deployment.env`, mode 600. It records
  product, version, source revision, and deployment time. It is inspectable
  local evidence only, never proof that video frames work and never a file to
  commit.
- `./scripts/install-firefox-pipewire.sh` is the only supported deployment
  entry point. Its no-argument mode must: (1) leave a fully current deployment
  untouched, including WirePlumber and an active call; (2) adopt only a missing
  or stale trace when all managed components match; (3) repair component drift
  through the versioned workflow; and (4) fail rather than overwrite a trace
  belonging to another product. Keep `--version`, `--status`, and `--rollback`
  functional and scoped.
- Deployment owns only its isolated Firefox profile, user units, helpers,
  desktop entries, Desktop shortcuts, and trace. It must not modify the normal
  Firefox profile, package configuration, global portal permissions, device
  ACLs, or browser settings outside that profile. Rollback must remove only
  those owned paths and release the bridge.
- The Firefox Start launcher intentionally uses a project-named transient user
  service. A direct custom GNOME menu scope was verified to fail Camera-portal
  focus association (`Only the focused app is allowed ...`); do not replace the
  service path with a custom permission-store entry, a manual browser launch,
  or another untracked hotfix without new evidence and full deployment tests.
- A release/change is not verified until it has passed repository install,
  repeat-install no-op, launcher start, actual changing non-black 1280x720
  WebRTC frames, stop/release behavior, and scoped rollback. Preserve Firefox
  as the working control while investigating other browsers.
- Brave support is the separately deployed native-V4L2 path only:
  `v4l2loopback` at `/dev/video20` plus the fixed-HD user bridge. Do not enable
  or persist Chromium's `WebRtcPipeWireCamera` feature: it timed out on the
  reference host. Preserve the root/user installer split, native-module guard,
  and both rollback layers; use disposable profiles for future Brave changes.
- Never include captured images, raw frames, browser profiles, logs containing
  personal data, credentials, or host deployment traces in commits. Private
  test artifacts remain under `~/Pictures/surface5-frontcamera-tests/`.
