# Baseline: 2026-09-13

## Scope and collection method

This file records observations from this specific machine, made without sudo,
configuration changes, package changes, module changes, or a reboot. Re-run
`../scripts/collect-baseline.sh` to collect a sanitized report after a state
change.

## Observed hardware and OS facts

| Item | Observed value |
| --- | --- |
| System vendor / product | Microsoft Corporation / Surface Pro |
| SKU | `Surface_Pro_1796` |
| CPU | Intel Core i7-7660U (Kaby Lake, family 6 model 142) |
| OS | Zorin OS 18.1, Ubuntu Noble base |
| Running kernel | `7.0.0-31-generic`, package `7.0.0-31.31~24.04.1` |
| Running kernel origin | Ubuntu HWE generic, not linux-surface |
| Installed linux-surface kernel | `6.18.7-surface-1`, held; reference only, not a proposed final solution |
| Secure Boot state | disabled; platform setup mode |
| IPU3 PCI function | `00:14.3`, Intel CSI-2 Host Controller `8086:9d32`, bound to `ipu3-cio2` |
| Front sensor | `INT33BE:00`, bound to `ov5693` on I2C bus 2 |
| Other detected sensors | `INT347A:00` / `ov8865`; `INT347E:00` / `ov7251` |
| VCM | `i2c-INT347A:00-VCM`, device name and modalias `dw9719` / `i2c:dw9719` |

The DMI serial is intentionally not recorded; it is not needed to reproduce
the driver diagnosis.

## Active media state

Observed loaded modules included `ipu3_cio2`, `ipu3_imgu`, `ipu_bridge`,
`ov5693`, `ov8865`, `ov7251`, and the INT3472 companion drivers. The CIO2 PCI
function and OV5693 I2C client are both bound. `dw9719` is available as an
in-tree module but was not loaded or bound.

There were **no** `/dev/media*`, `/dev/video*`, or `/dev/v4l-subdev*` nodes.
`media-ctl` could not enumerate a media device. `cam -l` reported that
`/dev/media0` and `/dev/media1` should exist, then listed no cameras. PipeWire
had no camera/video node. This means enumeration failed before a stream could
be negotiated; the absence of a camera application image is not being used as
the primary evidence.

## Confirmed immediate blocking condition

The currently running kernel supplies this VCM device:

```text
MODALIAS=i2c:dw9719
```

Its `dw9719` module has only `of:` aliases (including
`of:N*T*Cdongwoon,dw9719`) and no `i2c:dw9719` alias. In contrast, the
installed `6.18.7-surface-1` module has `alias: i2c:dw9719` and
`alias: i2c:dw9761`. This is direct local evidence that the active kernel
cannot auto-bind the VCM created by the IPU bridge.

The IPU3 bridge waits for all asynchronously registered camera components. An
unbound VCM can therefore prevent the graph for the otherwise-bound OV5693
front camera from completing. The graph failure is observed; the causal
relationship is supported by the source audit in [research.md](research.md)
and is being validated with an exact minimal module build for this kernel.

## Userspace and firmware

| Component | Observed version/state |
| --- | --- |
| libcamera | `0.2.0-3fakesync1build6`; `cam`, `qcam`, IPA and GStreamer plugin installed |
| PipeWire | 1.0.5 |
| WirePlumber | 0.4.17 |
| v4l-utils | 1.26.1 |
| V4L2 loopback | module available, version 0.15.3, not loaded |
| IPU3 IMGU firmware | `intel/ipu3-fw.bin.zst` points to the expected IRCI firmware payload |

The IPU3 IMGU module is loaded. Firmware presence alone does not demonstrate
that frame capture works.

## Limits of this baseline

The normal user cannot read the current boot's kernel journal on this install;
`journalctl -b -k` returned no entries for this account. The diagnostic script
records that limitation and does not manufacture a log. The initial state has
no camera node, so capture, frame quality, restart resilience, and normal app
compatibility are all untested rather than failed capture tests.
