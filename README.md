# Surface Pro 5 front camera on Linux

Use the internal front camera of a Microsoft Surface Pro 5 (model 1796) in
Firefox and Brave on the tested Ubuntu/Zorin generic-kernel stack. The
supported browser camera is the native V4L2 bridge
`Surface5_Front_Camera_HD` at 1280×720.

The reference system is Ubuntu/Zorin with `7.0.0-31-generic`. linux-surface is
comparison evidence only; it is not installed or required by this project.

## Install and make a call

In a terminal in a normal graphical desktop session, run:

```bash
curl -fsSL https://raw.githubusercontent.com/Eurobotics-Association/surface5-frontcamera/main/scripts/install-from-github.sh | bash
```

The installer asks for `sudo`, downloads one complete versioned source archive,
and installs the guarded V4L2 policy, on-demand bridge, global browser
launchers, Stop entry, and local diagnostic. It does not edit browser profiles,
add browser flags, or save camera frames.

1. Open **Firefox — Surface5 HD Front Camera** or **Brave — Surface5 HD Front
   Camera** from the Internet menu.
2. At the call site, allow camera access and select
   `Surface5_Front_Camera_HD`.
3. When finished, open **Stop Surface5 HD Front Camera**. The physical camera
   is released and its LED should turn off.

The installation is system-wide: every desktop user gets these menu entries.
Desktop icons are optional and per-user; see the [user guide](docs/v4l2-deployment.md#optional-desktop-icons).

## Verify it is really working

Open **Surface5 HD Camera Diagnostic** from the application menu and click
**Run virtual HD camera test**. A pass requires all of the following:

- `Surface5_Front_Camera_HD` is selected;
- the stream is 1280×720;
- the preview visibly moves; and
- `FRAME_PIXELS` shows changed frames with `allBlack:false`.

Run this in Firefox and Brave, then verify visible video at the real site you
use. The diagnostic saves textual browser events only under
`~/Pictures/surface5-frontcamera-tests/`; it never stores image frames.

## Compatibility and scope

This deployment is verified on the reference Surface Pro 5 OV5693/IPU3 camera
graph with system Firefox and Brave: changing, non-black 1280×720 WebRTC video
at about 30 FPS, real-site visible video, and shared Stop/LED release. It is a
tested starting point for compatible machines, not a guarantee for other
Surface models, distributions, kernels, or camera pipelines.

For the full install, verification, optional shortcuts, status, and scoped
rollback instructions, read the [user deployment guide](docs/v4l2-deployment.md).

## Documentation by audience

- **Users:** [install, test, and remove the browser camera](docs/v4l2-deployment.md)
- **Contributors and coding agents:** read [AGENTS.md](AGENTS.md) first, then
  the [developer and AI deployment guide](docs/developer-deployment.md)
- **Testers:** [hardware and browser validation procedure](docs/testing.md)
- **Kernel/module maintainers:** [maintenance guide](docs/maintenance.md)
- **Project history and evidence:** [verified changes](docs/changes.md)
- **Architecture and licensing:** [architecture](docs/architecture.md) and
  [licensing](docs/licensing.md)

## Working from a checkout

To install from a cloned repository instead of the curl bootstrap:

```bash
./scripts/install-v4l2-camera.sh
```

The installer is versioned and idempotent. A repeat install of the same
release reports `system already-current; no files or services changed.`

## License

GPL-2.0-only; see [COPYING](COPYING). Vendored kernel-derived DW9719 code
retains its upstream SPDX and copyright notices.
