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

## Proposed privileged live test — pending build inspection and approval

Do not run this procedure until the uninstalled build has passed inspection.
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
script. Do not execute the unload line while a camera application is running.
If `modprobe -r` reports an in-use dependency, stop and report it rather than
forcing an unload.

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

## Pending results

Awaiting uninstalled build inspection, then explicit operator approval for the
live module test. Do not mark the front camera fixed until real OV5693 frames,
restart resilience, and an application-facing path have all passed.
