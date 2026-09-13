# Community report: Surface Pro 5 generic-kernel DW9719 validation

## Status

**Not ready to post.** The module build and alias inspection are verified, but
no patched module has yet been installed or tested against the hardware. Do
not post a speculative report.

## Existing discussions to update after verification

- [linux-surface issue #2225](https://github.com/linux-surface/linux-surface/issues/2225): DW9719 I2C ID-table regression.
- [linux-surface discussion #2224](https://github.com/linux-surface/linux-surface/discussions/2224): Surface Pro 5 camera fixes.
- [Ubuntu Launchpad bug #2162045](https://bugs.launchpad.net/bugs/2162045): Ubuntu 7.0 regression and SRU tracking.
- The upstream fix is Linux commit
  [`d7fe0d53b2a8b08f6042cc89315118dee49e072e`](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=d7fe0d53b2a8b08f6042cc89315118dee49e072e).
  Report to an upstream Linux media thread only if validation reveals new,
  actionable information beyond confirming this already accepted fix.

Avoid a new issue unless the existing threads cannot accept the evidence or a
new, distinct OV5693 defect is verified.

## Ready-to-post template

> Validated on Microsoft Surface Pro 5 (model 1796), Zorin OS 18.1 (Ubuntu
> 24.04 base), Ubuntu generic HWE kernel `7.0.0-31-generic`
> (`7.0.0-31.31~24.04.1`). Before the fix, OV5693 and IPU3 CIO2 bound, but the
> IPU bridge-created VCM exposed `i2c:dw9719` while the native `dw9719` module
> had OF-only aliases. The VCM was unbound and no media graph or libcamera
> camera was created.
>
> I built only `dw9719` from the exact Ubuntu 7.0 source baseline with upstream
> `d7fe0d53b2a8b08f6042cc89315118dee49e072e` backported. The artifact's
> vermagic matched and it exported `i2c:dw9719` plus the other restored IDs.
> **[Replace this paragraph with verified binding, graph, libcamera, capture,
> restart, reboot, and rollback results.]**
>
> Reproducible source, diagnostics, and non-sensitive evidence:
> https://github.com/Eurobotics-Association/surface5-frontcamera

Before posting, replace every bracketed section with actual command results;
include no imagery, serial numbers, host names, credentials, or assumptions.
