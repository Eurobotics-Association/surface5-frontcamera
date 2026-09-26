# Rollback

## Current investigation state

The current host has two user-owned browser/session integrations. Neither
changes a kernel module, device ACL, global configuration, or packaged browser.

To remove the graphical-session WirePlumber recovery unit:

```bash
cd /home/aev/Github/surface5-frontcamera
./scripts/uninstall-user-camera-recovery.sh
```

This disables the one-shot user unit, removes only
`~/.config/systemd/user/surface5-wireplumber-camera-recovery.service`, and
reloads the user manager. It does not restart PipeWire or alter device access.

To remove the isolated portable-Firefox PipeWire profile and its browsing data:

```bash
cd /home/aev/Github/surface5-frontcamera
./scripts/uninstall-firefox-pipewire-profile.sh --purge-profile
```

This removes only
`~/.local/share/surface5-frontcamera/firefox-pipewire-profile`. It does not
touch normal Firefox or Brave profiles. Close the isolated Firefox first.

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
