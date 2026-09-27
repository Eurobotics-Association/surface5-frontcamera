# Changes and experiment log

## 2026-09-13 — Initial read-only baseline

No system state was changed. The repository gained documentation and
non-privileged diagnostics only. The active Ubuntu HWE 7.0 kernel has an
unbound `i2c:dw9719` VCM and no media/video nodes. See
[baseline.md](baseline.md).

## 2026-09-13 — Target changed to Ubuntu generic 7.x only

The permanent target is `7.0.0-31-generic`; `6.18.7-surface-1` is not a
solution or planned boot target. It remains useful only because its exported
`i2c:dw9719` alias provides a local pre-regression comparison.

The normal configured Ubuntu/Zorin repositories offer no newer generic 7.x
candidate: the installed and candidate HWE meta packages are all
`7.0.0-31.31~24.04.1`. The Ubuntu Kernel Team has submitted the upstream fix
for SRU, but it is not yet available from these repositories.

Secure Boot is disabled and the platform is in Setup Mode. No signing or MOK
enrollment is required for a live test on the machine's current security
state; that fact must be rechecked before any future test.

## 2026-09-13 — Exact 7.0 module source prepared

The source tagged `Ubuntu-hwe-7.0-7.0.0-31.31_24.04.1` was compared with the
installed `linux-modules-7.0.0-31-generic` package. Its package delta does not
modify `drivers/media/i2c/dw9719.c`, which lacks the I2C table. The repository
vendors that exact GPL driver with only upstream commit
`d7fe0d53b2a8b08f6042cc89315118dee49e072e` added. The original upstream patch
is retained under `patches/`.

Build, without installing anything:

```bash
./scripts/build-dw9719-7.0.sh
```

Required success evidence is a module whose `modinfo` output includes
`alias: i2c:dw9719`, plus the other restored I2C aliases. Build artifacts stay
under ignored `build/` paths and are not installed or loaded.

Build result: passed on this machine using the installed
`linux-headers-7.0.0-31-generic` package. The artifact's vermagic was exactly
`7.0.0-31-generic SMP preempt mod_unload modversions` and it advertised
`i2c:dw9718s`, `i2c:dw9719`, `i2c:dw9761`, and `i2c:dw9800k`. The compiler and
GCC major/minor version matched the kernel build; the header build emitted a
non-fatal executable-name warning and skipped BTF because no `vmlinux` image is
present. Neither affects module loading or aliases. No `dkms` package is
installed, so the reviewed source contains a DKMS configuration for a later,
operator-approved persistent setup but the current test uses no DKMS install.

## 2026-09-13 — DW9719 live test verified on Ubuntu generic 7.0

The controlled live test was performed on this Surface Pro 5 while running
Zorin OS 18.1 (Ubuntu 24.04 base), `7.0.0-31-generic`. The local
`/updates/dkms/dw9719.ko` was selected instead of the packaged module. The
patched driver bound to `i2c-INT347A:00-VCM` and the CIO2 graph completed.

Verified results from that test:

- `dw9719 3-000c` appeared as a Lens subdevice;
- OV5693 appeared in the media graph;
- libcamera registered `Internal front camera`;
- a 1280x720 NV12 capture produced frame data;
- five independent stop/start capture cycles completed.

A 16-frame host capture confirmed image-bearing, changing frames at about
28--30 fps. The recurring SHA-256
`9ee1d13fd6ed345f060ab756351293df8c9fedf100c25a4366a9c249bc9c95f6` is exactly
the all-zero `frame-000001` startup frame (Y min/max/mean/stddev = 0/0/0/0,
one distinct value). It is transient and not frozen output; later frames vary.
Its origin remains a separate IPU3/libcamera/sensor-startup investigation.

This verifies the upstream DW9719 restoration on the target generic kernel.
It does **not** yet verify image quality, frame motion, PipeWire/application
use, or the IPA-tuning layer. No personal frame data is retained in Git.

### Follow-up execution limitation

The later follow-up commands ran in the agent's restricted mount namespace,
which overlays `/dev` with a private tmpfs. They can inspect the registered
sysfs endpoints but cannot access the host's `/dev/media*` or `/dev/video*`
nodes, so an empty `cam -l` result there is not evidence of a host graph
regression. The registered sysfs endpoints included all IPU3 video devices,
OV5693 as `v4l-subdev8`, and DW9719 as `v4l-subdev9`. Run further capture and
desktop validation from the normal host user session, not that restricted
namespace.

### Portable enumeration-test correction

`tests/enumeration.sh` had falsely reported a missing front camera in a
successful test environment solely because its `rg` command was unavailable.
It now uses standard `grep -qiE`; the direct `grep` match against `Internal
front camera` passes without `rg`. The supporting collection/build scripts also
now use `grep` instead of an unnecessary `rg` dependency. The corrected full
enumeration test must be rerun from the normal host user session; the restricted
agent namespace cannot access the host device nodes.

### Desktop-path inventory (not a usability claim)

The target packages include `pipewire-libcamera`, `xdg-desktop-portal`,
GStreamer `libcamerasrc`, and Cheese. No PipeWire, portal, browser, or
desktop-application result is recorded yet. Test the installed GStreamer path
first, then PipeWire/portal and a graphical application from the normal host
session where camera nodes are accessible.

## Historical controlled live-test procedure

This procedure was used for the verified first live test. It remains useful
for a controlled reproduction, but is no longer described as pending.
It installs one external module under `/lib/modules`, updates module dependency
metadata, and binds the existing VCM on the running kernel. It does not install
another kernel, unload camera modules, or reboot.

PURPOSE:
Replace only the active kernel's DW9719 module with the reviewed upstream
backport, then bind the existing IPU3 VCM on `7.0.0-31-generic`.

COMMAND:
```bash
cd /home/aev/Github/surface5-frontcamera
sudo ./scripts/install-dw9719-7.0.sh \
  /home/aev/Github/surface5-frontcamera/build/dw9719-7.0.0-31-generic.XXXXXX/dw9719.ko
sudo modprobe dw9719
```

Replace `XXXXXX` with the exact inspected build directory printed by the build
script. The installer locates the packaged DW9719 module below the target
kernel's `kernel/drivers/media/i2c/` tree, compares its vermagic with the
patched artifact, and normalizes only trailing whitespace before requiring an
exact match. Do not run while a camera application is active.

EXPECTED RESULT:
`dw9719` binds to `i2c-INT347A:00-VCM`; its asynchronous registration completes
the already registered CIO2 notifier and creates media/video nodes. This may
reveal a separate OV5693 or userspace streaming issue, which must be diagnosed
independently.

VERIFICATION:
```bash
test -L /sys/bus/i2c/devices/i2c-INT347A:00-VCM/driver
modinfo dw9719 | grep '^alias:.*i2c:dw9719'
./tests/enumeration.sh
./tests/capture.sh --frames 8
./tests/restart-stream.sh --cycles 5
```

ROLLBACK:
```bash
sudo ./scripts/uninstall-dw9719-7.0.sh
sudo reboot
```

The reboot loads the packaged Ubuntu module again, returning to the known
broken-but-original driver state. No kernel package, boot entry, initramfs, or
Secure Boot setting is changed by the procedure.

RISK:
The test dynamically binds a VCM to the existing camera stack. A failed graph
completion may require the rollback reboot. The procedure must not be run while
a camera application is active; it must never use forced module removal.

## Desktop application evidence and remaining work

Cheese is verified to display usable live video from `Internal front camera`
when the operator selects it manually. Cheese initially chooses the rear
camera, whose image is currently unusable; this is application ordering, not a
reason to disable the rear camera. Its exact transport path is not yet claimed.

Changing OV5693 frames and repeated start/stop are verified. Browser/WebRTC
access is the remaining primary target: diagnose PipeWire libcamera exposure,
WirePlumber, portal, browser packaging, and site permissions without changing
the proven kernel workaround or camera drivers.

### Verified WirePlumber/portal recovery

At initial session startup WirePlumber received permission denied opening
`/dev/media0` and `/dev/media1`, skipped libcamera discovery, and did not later
recover when normal logind ACLs granted `aev` read/write access. After
`systemctl --user restart wireplumber`, it registered both `\_SB_.PCI0.I2C3.CAMR`
and `\_SB_.PCI0.I2C2.CAMF`; PipeWire gained both libcamera devices/sources,
the front source became default, and portal `IsCameraPresent` changed false to
true. This is verified stale WirePlumber state after startup-time ACL failure.

### Current browser boundary

After recovery, `wpctl` lists front and rear libcamera devices
(`libcamera_device.\_SB_.PCI0.I2C2.CAMF` and
`libcamera_device.\_SB_.PCI0.I2C3.CAMR`) and corresponding sources; the front
source is the default. The Camera portal is present (`IsCameraPresent=true`).
Brave 1.95.101 (Chromium 153.0.8010.37, native DEB, Wayland) requests and is
granted site camera permission at webcamtests.com, but reports
`NotFoundError: Requested device not found`. This isolates the remaining
functional investigation to Brave's WebRTC camera backend, not permissions,
PipeWire enumeration, or the camera stack.

This was the browser boundary before the controlled localhost tests below.

### Browser control results (2026-09-26)

On the real host session, after the documented WirePlumber recovery, `cam -l`
listed both internal cameras, PipeWire listed
`libcamera_input.__SB_.PCI0.I2C2.CAMF` as the default source, and the Camera
portal property was true. The repository-local WebRTC page produced these
separate results without retaining frames:

* Brave 153.1.95.101 with its normal backend resolved enumeration but exposed
  zero `videoinput` devices and returned `NotFoundError` from `getUserMedia`.
* The same Brave build with its compiled `WebRtcPipeWireCamera` feature
  explicitly enabled timed out in both pre-permission enumeration and
  `getUserMedia` after 12 seconds. The process arguments confirmed the feature
  was active while the PipeWire source and Camera portal remained healthy.
* Portable Mozilla Firefox 156.0.1 with its default GTK camera backend had the
  same zero-video-input/`NotFoundError` result. With only
  `media.webrtc.camera.allow-pipewire=true` in a disposable profile, it listed
  both cameras after permission, made an exact request for `Built-in Front
  Camera`, and produced a live 640x480 front stream.

This proves a practical Firefox/PipeWire workaround and isolates the remaining
Brave failure to Chromium's PipeWire camera backend on this host, not the
kernel, libcamera, WirePlumber source, or portal.

The disposable portable-Firefox profile used for this control was removed from
the host and is no longer shipped as a solution. It did not meet the project's
deployment standard. A Flatpak or other browser path must be validated and
then delivered through a complete repository installer/status/uninstall
workflow before it is presented to users.

### System Firefox deployment control (2026-09-26)

The installed distribution Firefox (`/usr/bin/firefox`, package version
`156.0.1~build1`) was retested, not inferred from the removed portable build.
Its default disposable profile exposed zero video inputs and returned
`NotFoundError`. A second disposable profile containing only the managed
PipeWire camera preference discovered both built-in cameras and produced a
live 640x480 `Built-in Front Camera` stream through an exact-device request.

The supported deployment therefore uses the system Firefox executable with a
separate repository-managed profile, never a manual edit to an existing
profile. The installer validates active user services, restores the known
WirePlumber discovery state, checks the front PipeWire source and Camera portal,
then creates the isolated profile. It has paired status, launch, and uninstall
commands. Brave remains outside supported scope because its PipeWire backend
does not complete device enumeration on this host.

The deployed launcher was then tested end to end, using the managed profile
rather than a temporary profile. It completed `getUserMedia`, reported a live
`Built-in Front Camera` track, and displayed 640x480 dimensions. A subsequent
browser start selected the rear camera by default but completed the diagnostic's
exact front-device request and again displayed 640x480 dimensions. The managed
status check simultaneously reported the enabled recovery unit, active user
services, default front source, and true Camera portal property. Those results
were enumeration/playback-state evidence only and must not be interpreted as
proof of image-bearing frames.

### Firefox physical-source all-black WebcamTests result (2026-09-26)

The managed Firefox profile was used at `https://fr.webcamtests.com/`. Firefox
identified `Built-in Front Camera`, negotiated 1280x720 at 29 FPS, but the site
reported one colour and zero brightness, saturation, and RGB values: the stream
was entirely black. Concurrent host evidence showed the Firefox PipeWire stream
active and targeted at `libcamera_input.__SB_.PCI0.I2C2.CAMF`. During the
website's sequence of resolution changes (832x480, 640x480, 1024x576, then
1280x720), PipeWire logged:

```
ERROR Request request.cpp:472 FrameBuffer already set for stream
spa.libcamera: can't add buffer 0 for request: File exists
```

This is a PipeWire libcamera-SPA request/buffer failure after camera access is
already granted, not a Firefox permission failure, missing camera node, or the
known one-frame OV5693 startup-black condition. PipeWire 1.0.5 and
`pipewire-libcamera` 1.0.5 on the Ubuntu 24.04 reference stack are now a
suspected boundary for the physical-source reconfiguration path. The WebRTC
diagnostic samples in-memory video luminance and frame changes so dimensions
alone cannot produce a false pass.

### Fixed-HD virtual Firefox result (2026-09-26)

The physical front source has a deterministic format boundary on the reference
host: the default 640x480 route produces zero-valued frames, while a fixed
1280x720 route produces moving image data after the known startup frames. A
user-owned GStreamer/PipeWire bridge was therefore installed as the separate
camera `Surface5_Front_Camera_HD`. It pins its input to NV12 1280x720 and
offers an ordinary PipeWire `Video/Source` for WebRTC applications.

The managed Firefox profile's localhost virtual-HD test selected that source,
reported a live 1280x720 track, and measured three changing, non-black frame
samples. The operator also selected it at WebcamTests and observed a usable
1280x720 image. The website reported RGB image data and non-zero brightness;
its displayed zero-FPS metric is not treated as an authoritative frame-flow
result because the local in-memory test directly observed changing frames.

The bridge is installed as a static user service, deliberately inactive at
login. The repository launcher starts it for Firefox; the paired stop command
releases the physical camera and removes the virtual source. Install, start,
stop, status, and uninstall were exercised in the host session. This is a
reference-specific Firefox workaround, not a claim of support for other
Surface models, other Linux camera pipelines, or Brave.

### Firefox desktop-launcher deployment (2026-09-26)

The Firefox deployment now reports detected Firefox and Brave installations,
but configures only the verified Firefox path. It installs two project-owned
application-menu entries: **Firefox — Surface5 HD Front Camera** starts the
managed profile and fixed-HD bridge, while **Stop Surface5 HD Front Camera**
stops the bridge and releases the privacy LED. The launch helpers and desktop
entries are user-owned, checked by the status command, and removed by the
existing Firefox uninstall command.

During the first full deployment run, the WirePlumber recovery installer
reported its expected inactive completed one-shot state as an error. That
installer now reports the state without treating it as a failed install, so the
top-level Firefox deployment remains idempotent.

The first desktop-entry smoke test also found that invoking the Bash launch
helper through `/bin/sh` made Dash reject `pipefail`. The entries now execute
their versioned, executable Bash helpers directly. The corrected Start entry
was then verified to create `surface5_frontcamera_hd`; the paired Stop entry
was verified to remove it and release the physical camera.

The initial custom entry used the Audio/Video category, so it appeared outside
Zorin's Internet section. It now uses the standard Network category. A later
Firefox `NotAllowedError` was traced to the GNOME Camera portal, which logged
both a failed parent-window association and `Only the focused app is allowed to
show a system access dialog`. Earlier occurrences predated the desktop
launcher, so this is not evidence of a camera-bridge failure. The custom entry
now declares Firefox's documented `StartupWMClass=firefox`, matching the
distribution Firefox entry, so GNOME can associate the managed Firefox window
with the launcher for portal focus checks. This requires a focused-window
retest; no portal permissions or security policy were changed.

The focused-window retest showed that the custom menu scope still triggered the
portal denial. A direct launch from the normal terminal scope, by contrast,
opened a persistent managed Firefox window and WebcamTests verified
`Surface5_Front_Camera_HD` at 1280x720, 29 FPS with changing RGB image data.
The launcher now starts Firefox in a project-named transient user service
instead of inheriting the custom menu scope. The transient service automatically
disappears when Firefox exits; it changes no global portal permission, browser
setting, or permanent Firefox service. The installer also adds matching Start
and Stop shortcuts to the user's Desktop directory. The new service-based
repository launcher was then verified end to end at WebcamTests. The site
received `Surface5_Front_Camera_HD` as a visible 1280x720 RGB stream at 29 FPS
with 108,647 colours and non-zero image metrics. This validates the
repository-installed Firefox launch path, not merely the direct diagnostic
control.

### Deployment version and rollback interface (2026-09-26)

The Firefox deployment now has the versioned product identity
`EBtx-surface5-HDCam-patch 1.0.260926`. The installer writes a user-owned,
mode-600 trace containing the product, version, source revision where Git data
is available, and timestamp. On subsequent runs it checks the trace and the
managed profile, user units, launch helpers, application entries, and Desktop
shortcuts. A fully current deployment is a no-op: it does not restart
WirePlumber or interrupt a camera call. The installer also provides read-only
`--status`, `--version`, and scoped `--rollback` entry points. Rollback removes
only the tracked Firefox deployment and its trace.

### Deployment documentation contract (2026-09-26)

The project rules now preserve the Firefox deployment invariants for future AI
and human maintainers: the versioned product identity and local trace, safe
no-op/adoption/repair behavior, scoped rollback, ownership boundaries,
transient-service launcher rationale, and the requirement for actual
moving-frame validation. User instructions remain limited to installation,
launch, stop, status, and rollback in
[Firefox desktop deployment](firefox-deployment.md); implementation and update
requirements are in [Developer deployment guide](developer-deployment.md).

### Brave 154 disposable WebRTC controls (2026-09-26)

Brave Browser `154.1.96.59` was retested after the Firefox integration was
known good. These were real-host controls: PipeWire exposed the physical front
source and the Camera portal property was true, while the fixed-HD virtual
source `surface5_frontcamera_hd` was active for each run. The repository test
harness used a transient user service and a newly created temporary Brave
profile, so neither test read or changed the normal Brave profile.

* **B1 — normal Brave:** `enumerateDevices()` resolved but returned zero video
  inputs. The permission probe failed immediately with
  `NotFoundError: Requested device not found`.
* **B2 — PipeWire camera feature:** the temporary Brave process command line
  confirmed `--enable-features=WebRtcPipeWireCamera`. In this case
  `enumerateDevices()` timed out at 12 seconds; the permission probe and
  post-probe enumeration also timed out. It never reached virtual-camera
  selection or frame delivery.

This isolates the current defect to Brave/Chromium camera enumeration on this
host. The experimental feature is not a usable workaround and is not deployed,
stored as a Brave preference, or added to a launcher. The test harness removes
its temporary profile and releases the bridge with `--stop`; Firefox remains
the verified browser solution.

### Brave native-V4L2 bridge result (2026-09-26)

The running generic kernel already provided a signed native `v4l2loopback`
module (`0.15.3`) in `linux-modules-7.0.0-31-generic`, so no DKMS module was
installed. A controlled `/dev/video20` loopback feed converted the verified
physical 1280x720 NV12 source to 1280x720 YUYV. Brave 154's ordinary backend
then requested camera authorization, enumerated `Surface5_Front_Camera_HD`,
and delivered a live 1280x720, 30 FPS track. The local browser diagnostic
observed three changing non-black frame samples both for the permission probe
and exact-device request. This is the supported Brave path; the Chromium
PipeWire feature remains unsupported.

The installed Brave launcher was then validated at WebcamTests using the
normal Brave profile. The site received `Surface5_Front_Camera_HD` as an RGB
1280x720 stream at 28 FPS, with 196,667 colours and a reported 20.3 MB/s data
rate. This confirms real website delivery in addition to the local
changing-frame test; no camera image was retained in the repository.

### User-session recovery deployment

The repository now provides a user-only one-shot unit, enabled for
`graphical-session.target`. It restarted WirePlumber successfully when
installed in the active session; after stabilization both libcamera sources and
the true portal Camera property returned. It changes no device ACL, kernel
component, or global system configuration. The target is enabled and its exact
uninstall command is documented. A fresh logout/login or reboot check remains
required to prove that the target fires at the next graphical-session start.

### Unified browser V4L2 deployment (2026-09-27)

Firefox was retested against the same native `/dev/video20`
`Surface5_Front_Camera_HD` route already verified in Brave. The repository
WebRTC diagnostic reported a 1280x720, 30 FPS track and three changing,
non-black pixel samples; the operator also confirmed visible Firefox video.
This establishes one browser-neutral fixed-HD V4L2 path for both system
Firefox and Brave. It has better image stability on the reference host than
the prior Firefox-only PipeWire virtual-source route.

The deployable product is now `EBtx-surface5-HDCam-V4L2 2.0.260927`. Its
default installer is system-wide: it installs only the kernel-provided
`v4l2loopback` policy, a global on-demand user bridge, global Internet-menu
entries, and the durable localhost WebRTC diagnostic assets. It does not
modify a normal browser profile or persist a browser feature flag. Optional
`--user` deployment adds only that user's menu/Desktop convenience entries.
The shared Stop entry releases the one V4L2 bridge.

The old Firefox PipeWire profile, virtual source, recovery unit and its
browser-specific scripts have been retired from the repository. A user-mode
migration removes only their known project-owned files; it never removes a
normal browser profile. The installed diagnostic is now a required maintenance
control: it starts a transient server which survives its launcher shell,
records only textual logs beneath the private Pictures test directory, and
proves moving frames rather than mere enumeration.

### Clean legacy rollback (2026-09-27)

Version `2.1.260927` adds a deliberate `--legacy-rollback` mode before a clean
installation test. It removes the retired project-owned user units, launchers,
traces and isolated Firefox profile from the affected graphical user, then
removes the old guarded loopback policy as administrator. The profile may hold
browser state and is therefore permanently deleted only by this explicit mode;
normal Firefox profiles are out of scope. The root step refuses to unload a
loopback camera if `/dev/video20` has a different owner label.
