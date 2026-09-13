# Changes and experiment log

## 2026-09-13 — Initial read-only baseline

No system state was changed. The repository gained documentation and
non-privileged diagnostics only. The active Ubuntu HWE 7.0 kernel has an
unbound `i2c:dw9719` VCM and no media/video nodes. See
[baseline.md](baseline.md).

## Proposed next action: boot the installed linux-surface 6.18 kernel once

This is the least invasive technically justified experiment. It does not
install, remove, or modify any package, module, initramfs, boot entry, or
configuration. The kernel is already installed at:

```text
/boot/vmlinuz-6.18.7-surface-1
```

It is relevant because its `dw9719` module locally advertises `i2c:dw9719`,
unlike the booted generic kernel. It also has the same IPU3/CIO2/OV5693/DW9719
features configured as modules.

### Operator action required

PURPOSE:
Boot the pre-installed linux-surface `6.18.7-surface-1` kernel once to test
whether the media graph completes with its matching DW9719 I2C alias.

COMMAND:
```bash
sudo reboot
```

At the boot loader, select the entry named `Linux 6.18.7-surface-1` (or the
equivalent Advanced options entry). Do not make it the default.

EXPECTED RESULT:
The computer runs an already installed kernel. If the diagnosis is correct,
`/dev/media*` and `/dev/video*` nodes appear and `cam -l` lists the front
camera. This is a hypothesis to test, not an assurance.

VERIFICATION:
```bash
uname -r
cd /home/aev/Github/surface5-frontcamera
./scripts/collect-baseline.sh
./tests/enumeration.sh
./tests/capture.sh --frames 8
./tests/restart-stream.sh --cycles 5
```

ROLLBACK:
Reboot and select `7.0.0-31-generic` (or `7.0.0-30-generic`) in the boot
loader. No files need to be removed because this experiment changes no
persistent setting.

RISK:
A reboot interrupts the current session. The surface kernel could expose an
unrelated hardware regression, but the currently running generic kernel and
an older generic kernel remain installed as fallback entries. No Secure Boot
change is required on this machine because it is currently disabled.

## Pending results

Awaiting the above boot and non-privileged tests. Do not mark the camera fixed
until native frames, restart resilience, and one application-facing route have
all passed.
