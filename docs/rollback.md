# Rollback

## Current investigation state

The current host may have one user-owned Firefox/session integration. It does
not change a kernel module, device ACL, global configuration, browser package,
or a normal Firefox profile.

To remove the managed Firefox PipeWire integration and graphical-session
WirePlumber recovery unit:

```bash
cd /home/aev/Github/surface5-frontcamera
./scripts/uninstall-firefox-pipewire.sh
```

This removes only the managed profile at
`~/.local/share/surface5-frontcamera/firefox-pipewire-profile` and the
repository's one-shot WirePlumber recovery unit. It does not remove Firefox,
touch a normal Firefox profile, restart PipeWire, or alter device access.

It also removes the project-owned **Firefox — Surface5 HD Front Camera** and
**Stop Surface5 HD Front Camera** application-menu entries plus their launch
helpers. No normal desktop entries are changed.

It also stops and removes the user-level `surface5-frontcamera-hd-bridge`
service and its `Surface5_Front_Camera_HD` virtual source. To roll back only
that bridge while retaining the managed Firefox profile and WirePlumber
recovery unit, use:

```bash
cd /home/aev/Github/surface5-frontcamera
./scripts/uninstall-user-hd-camera-bridge.sh
```

For a non-destructive temporary release of the camera while keeping the bridge
installed, use `./scripts/stop-user-hd-camera-bridge.sh`.

## DW9719 external-module rollback

The only proposed system change targets `7.0.0-31-generic` and places a
reviewed `dw9719.ko` in `/lib/modules/$(uname -r)/updates/dkms/`. To return to
the packaged Ubuntu module:

```bash
cd /home/aev/Github/surface5-frontcamera
sudo ./scripts/uninstall-dw9719-7.0.sh
sudo reboot
```

Verify rollback with `uname -r`, `modinfo dw9719`, and
`./tests/enumeration.sh`. This neither switches kernels nor changes the boot
default. The older linux-surface kernel is not used as part of rollback.

## Future module or package intervention

No custom module, DKMS package, repository setting, or module-load rule has
been installed. If one is introduced later, this file must be updated in the
same change with its exact source version, install paths, unload/remove
commands, initramfs implications, and the known-good kernel fallback.
