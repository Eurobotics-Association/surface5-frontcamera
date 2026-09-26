# Brave HD front-camera deployment

This is the verified Brave solution for the reference Surface Pro 5 / Ubuntu or
Zorin generic-kernel stack. It creates a conventional V4L2 camera named
`Surface5_Front_Camera_HD`; Brave uses it with its normal camera backend. It
does not enable Chromium's PipeWire-camera feature and does not alter Brave's
profile or site settings.

## Install

Run this single command as the logged-in desktop user:

```bash
./scripts/install-brave-v4l2-camera.sh
```

If the native loopback policy is missing, the installer invokes its guarded
root helper and your terminal requests the `sudo` password. The root layer uses
the `v4l2loopback` module already supplied by the current kernel and refuses to
install a DKMS replacement automatically. The user layer installs a bridge and
Brave Start/Stop entries, but keeps the camera off until you start it.

## Use

Open **Brave — Surface5 HD Front Camera** from the Internet menu or the Desktop
shortcut. On the video-call site, approve the camera request and select
**Surface5_Front_Camera_HD**. Use **Stop Brave Surface5 HD Front Camera** after
the call to release the physical camera and turn off its LED.

## Check and remove

```bash
./scripts/install-brave-v4l2-camera.sh --status
sudo ./scripts/install-brave-v4l2loopback.sh --status

./scripts/install-brave-v4l2-camera.sh --rollback
sudo ./scripts/install-brave-v4l2loopback.sh --rollback
```

Stop the Brave bridge before root rollback. Rollback removes only the project
launchers, user service, project loopback configuration, and its native module
load; it does not remove Brave or change its profile.
