# Maintenance design

## Current state: controlled experiment only

`scripts/install-dw9719-7.0.sh` is deliberately restricted to
`7.0.0-31-generic`. It supports the first live test only. It is not an upgrade
strategy and the DKMS metadata has `AUTOINSTALL="no"` by design.

The upstream defect is fixed. A stale out-of-tree module must never mask an
officially fixed Ubuntu/Zorin kernel.

## Required final installer behavior

After actual OV5693 capture has been proven, the final kernel-aware installer
will accept a target kernel and perform these checks in order:

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

After `apt upgrade` and booting the new kernel, run the future `status.sh`.
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

## Deferred implementation decision

The generic `install.sh`, `status.sh`, and `uninstall.sh` are intentionally
deferred until the live patch proves that DW9719 binding resolves this
machine's first failure. This prevents a maintenance mechanism from
institutionalizing an unproven workaround. The controlled scripts, source, and
rollback already provide the evidence needed for that decision.
