# Rollback

## Current investigation state

The initial milestone adds only repository files and runs read-only commands.
There is no system-level change to roll back.

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
