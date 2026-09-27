# Surface5 HD Front Camera — install and use

This tested solution for the Microsoft Surface Pro 5 (model 1796) on the
reference Ubuntu/Zorin generic-kernel stack makes the internal front camera
available to **Firefox and Brave** as `Surface5_Front_Camera_HD` at 1280×720.
It does not alter normal browser profiles or settings. Other Surface models or
Debian/Ubuntu releases need their own hardware validation.

## Install for all desktop users

The one-command GitHub installation is:

```bash
curl -fsSL https://raw.githubusercontent.com/Eurobotics-Association/surface5-frontcamera/main/scripts/install-from-github.sh | bash
```

It downloads the full source archive and then calls the versioned system
installer through `sudo`, which displays the administrator password prompt.
For an existing checkout, an administrator instead runs:

```bash
./scripts/install-v4l2-camera.sh
```

It requests the administrator's `sudo` password because it installs the
kernel-provided V4L2 loopback policy and global integration. It adds these
Internet-menu entries for every desktop user:

- **Firefox — Surface5 HD Front Camera**
- **Brave — Surface5 HD Front Camera**
- **Stop Surface5 HD Front Camera**

Start the relevant browser entry, allow camera access at the call site, and
choose **Surface5_Front_Camera_HD**. Use the shared Stop entry after the call
to release the physical camera and turn off its LED.

The deployment is versioned and idempotent. Check it with:

```bash
./scripts/install-v4l2-camera.sh --status
./scripts/install-v4l2-camera.sh --version
```

## Optional Desktop icons

Desktop folders are per-user. A user who wants Desktop shortcuts after the
system install runs:

```bash
./scripts/install-v4l2-camera.sh --user
```

This needs no `sudo` and cannot create `/dev/video20` on its own.

## Verify without saving images

The menu includes **Surface5 HD Camera Diagnostic**. It starts a localhost-only
test page, opens it in the default browser, and saves textual events—not
frames—under `~/Pictures/surface5-frontcamera-tests/`. Run the
`permission-then-virtual-hd` test. A pass names
`Surface5_Front_Camera_HD`, shows 1280×720 and has changing `FRAME_PIXELS`
with `allBlack:false`.

For a real call/site check, choose the same source and verify moving visible
video; an LED or live track alone is not enough.

## Remove

An administrator removes all-user components with:

```bash
./scripts/install-v4l2-camera.sh --rollback
```

It removes only project policy, global unit/assets/menu items and trace; it
does not remove Firefox, Brave, ordinary profiles, or personal files. A user
can remove that user's optional shortcuts with:

```bash
./scripts/install-v4l2-camera.sh --user --rollback
```

Stop calls first. If another application uses the module, it may remain loaded
until released; no unrelated application is forcibly stopped.

## Start from a clean previous deployment

If this computer used the retired Firefox PipeWire or old Brave-specific
deployment, remove it before testing a fresh installation:

```bash
./scripts/install-v4l2-camera.sh --user --legacy-rollback
./scripts/install-v4l2-camera.sh --system --legacy-rollback
```

The first command runs in the affected graphical user's session and permanently
deletes only the old project-created isolated Firefox profile, units, launchers
and traces. That profile can contain browsing state, but is not the normal
Firefox profile. The second command requests administrator authentication and
removes only the old project V4L2 policy/module. It refuses to unload a
loopback device owned by something else.
