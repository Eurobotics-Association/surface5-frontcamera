# Maintenance design

## Current state: verified 7.0 workaround with guarded maintenance

`scripts/install-dw9719-7.0.sh` is deliberately restricted to
`7.0.0-31-generic`. It was used for the controlled live test only. The
validated module bound the VCM and exposed the SP5 front-camera pipeline, but
this historical helper is not an upgrade strategy.

The upstream defect is fixed. A stale out-of-tree module must never mask an
officially fixed Ubuntu/Zorin kernel.

The repository now provides a guarded wrapper:

```bash
./scripts/status.sh [kernel-release]
sudo ./scripts/install.sh [kernel-release]
sudo ./scripts/uninstall.sh [kernel-release]
```

`status.sh` locates the target's packaged module specifically below
`/lib/modules/<kernel>/kernel/drivers/media/i2c/`, so it cannot mistake a local
`/updates/` override for the native implementation. It returns success with
`NATIVE_FIX_PRESENT` when that file exports `i2c:dw9719`, and returns status
10 with `NATIVE_FIX_MISSING` otherwise. It reports a local override separately.

`install.sh` builds and installs nothing when the native fix is present. For an
affected kernel it requires matching headers, invokes the strict build and
metadata checks, and currently permits only the reviewed
`7.0.0-31-generic` ABI. Any other affected ABI is an intentional safe stop for
source/API review. `uninstall.sh` removes only the local override for the named
kernel, runs `depmod`, and never removes the packaged module or unloads a
possibly in-use driver.

The included DKMS metadata retains `AUTOINSTALL="no"`. Automatic DKMS builds
cannot by themselves make the per-kernel native-fix decision, so enabling them
would risk masking an official repair on a later kernel.

`tests/host-validation.sh` is intentionally separate from maintenance: it
never installs, unloads, reloads, or otherwise changes a kernel module. It is
a normal-user validation workflow and retains private visual evidence below
`~/Pictures/surface5-frontcamera-tests/`, outside the repository.

## Required final installer behavior

The kernel-aware installer accepts a target kernel and performs these checks in
order:

1. require matching installed headers under `/lib/modules/<kernel>/build`;
2. locate the target kernel's *native* `dw9719` module, excluding local
   `/updates/` overrides;
3. inspect its aliases with `modinfo` and stop successfully when it already
   exports `i2c:dw9719`;
4. only for an affected kernel, build the minimal upstream backport;
5. require successful compilation, target vermagic, and every restored I2C
   alias before installation;
6. install into that kernel's documented override path, run `depmod`, and
   report precisely what changed;
7. refuse unknown or API-incompatible kernels rather than force a build;
8. support idempotent status and uninstall operations.

No broad DKMS `AUTOINSTALL=yes` setting is acceptable without an equivalent
per-target native-fix guard.

## Operational workflow after proof

### Normal package or kernel update

After `apt upgrade` and booting the new kernel, run `status.sh`.
If native `dw9719` exposes `i2c:dw9719`, remove any old override for that
kernel and use the packaged driver. If it does not, the installer may build
only after headers and source/API checks pass.

### Future 7.x kernel or distribution upgrade

Do not carry a built `.ko` forward. Re-run status against the active kernel.
An API mismatch is a safe stop requiring source review, not a reason to force
the old driver. Recheck Secure Boot before any new module load.

### Official Ubuntu fix

When a normal package update includes the restored alias, the workaround is
self-obsoleted: status reports `NATIVE FIX PRESENT`, no override is installed,
and any per-kernel old override can be removed with the documented uninstall
tool. Capture/restart tests should be repeated before retiring the workaround.

## Adding support for a future affected ABI

Do not bypass the installer guard. First obtain the exact vendor source for
the target kernel, verify that its native driver still lacks the I2C ID table,
apply and inspect the upstream restoration, build against matching headers,
and validate its aliases and vermagic. Only then extend the explicit reviewed
ABI list and repeat media, capture, restart, and rollback tests. If the native
module is fixed, remove any matching per-kernel override instead of extending
the workaround.
