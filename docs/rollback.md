# Rollback

## Current investigation state

The initial milestone adds only repository files and runs read-only commands.
There is no system-level change to roll back.

## One-time linux-surface boot experiment

If the proposed experiment in [changes.md](changes.md) causes a problem,
reboot and select `7.0.0-31-generic` from the boot loader's normal or advanced
kernel entries. `7.0.0-30-generic` is also installed. The plan deliberately
does not change the default entry, remove kernels, alter initramfs, or modify
boot configuration.

Verify rollback with:

```bash
uname -r
```

Then re-run `./tests/enumeration.sh` to document the restored baseline.

## Future module or package intervention

No custom module, DKMS package, repository setting, or module-load rule has
been installed. If one is introduced later, this file must be updated in the
same change with its exact source version, install paths, unload/remove
commands, initramfs implications, and the known-good kernel fallback.
