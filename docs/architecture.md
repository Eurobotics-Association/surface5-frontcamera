# Architecture

## Hardware-to-application path

```text
OV5693 front sensor (ACPI INT33BE, I2C-2)
       │ raw CSI-2
       ▼
Intel IPU3 CIO2 (PCI 8086:9d32) ──► media/V4L2 subdevices
       │                                  │
       ├── IPU bridge + all async components (including rear DW9719 VCM)
       ▼
IPU3 IMGU + firmware ──► libcamera IPU3 pipeline ──► PipeWire/GStreamer/app
```

The Surface Pro 5 uses raw MIPI sensors, not a USB/UVC webcam. The kernel
must construct the media graph first; libcamera then runs the IPU3 pipeline.
Most conventional applications consume PipeWire or V4L2-style camera devices,
so successful sensor detection alone is insufficient. The target kernel for
every repair and validation in this project is Ubuntu generic 7.x, currently
`7.0.0-31-generic`.

## Machine-specific component mapping

| Function | Local device/driver |
| --- | --- |
| Front camera | `INT33BE:00` / `ov5693` |
| Rear camera | `INT347A:00` / `ov8865` |
| IR camera | `INT347E:00` / `ov7251` |
| Rear focus motor | `i2c-INT347A:00-VCM` / `dw9719` |
| Bridge | `ipu_bridge` plus INT3472 companion drivers |
| CSI receiver | `ipu3_cio2` at PCI `00:14.3` |
| Image processing | `ipu3_imgu` plus IRCI firmware |

## Failure boundary in the initial state

The front sensor and CIO2 controller bind, but the `dw9719` VCM does not. The
media graph never creates device nodes. Thus the current failure is below
libcamera, PipeWire, and V4L2 compatibility layers. Those layers should be
tested only after `tests/enumeration.sh` passes.

## User-facing paths to validate after graph recovery

1. `cam` validates the native libcamera IPU3 pipeline and writes test frames.
2. `gst-launch-1.0 libcamerasrc` validates the GStreamer integration.
3. PipeWire node discovery validates desktop integration.
4. If a target application cannot consume libcamera/PipeWire directly, a
   separately documented V4L2 bridge may be appropriate. It is not a remedy
   for a missing kernel media graph.
