# Rollback

## Browser V4L2 deployment

Stop calls first, then an administrator removes the all-user browser
integration from this checkout:

```bash
./scripts/install-v4l2-camera.sh --rollback
```

The helper requests `sudo` where needed. It stops the project V4L2 bridge,
removes project modprobe/modules-load policy, global user unit, launcher and
diagnostic assets, global menu entries and its product trace. It attempts to
unload `v4l2loopback`, but leaves it if another application is using it. It
does not remove Firefox, Brave, normal browser profiles, camera drivers, or
personal test logs.

Desktop shortcuts are user-owned and therefore not removed by an administrator
acting for all users. Their owner removes optional user components with:

```bash
./scripts/install-v4l2-camera.sh --user --rollback
```

## DW9719 external-module rollback

The controlled `7.0.0-31-generic` external module can return to the packaged
driver with:

```bash
sudo ./scripts/uninstall-dw9719-7.0.sh
sudo reboot
```

Verify with `uname -r`, `modinfo dw9719`, and `./tests/enumeration.sh`. This
neither switches kernels nor changes the boot default.
