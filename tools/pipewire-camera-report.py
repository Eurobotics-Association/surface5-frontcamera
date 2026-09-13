#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0-only
"""Classify PipeWire video devices and source nodes from pw-dump JSON."""
import json
import sys

FIELDS = ("media.class", "device.api", "node.name", "node.description",
          "device.name", "device.description", "device.path", "device.devid",
          "api.v4l2.path", "api.libcamera.path", "api.libcamera.camera")

def props(item):
    return item.get("info", {}).get("props", {})

def libcamera(values):
    return any("libcamera" in str(key).lower() or "libcamera" in str(value).lower()
               for key, value in values.items())

def describe(item):
    values = props(item)
    fields = [f"object.id={item.get('id', '?')}", f"object.type={item.get('type', '')}"]
    fields.extend(f"{key}={values.get(key, '')}" for key in FIELDS)
    print("\t".join(fields))

def main():
    if len(sys.argv) != 2:
        print("usage: pipewire-camera-report.py PW-DUMP.json", file=sys.stderr); return 2
    try:
        with open(sys.argv[1], encoding="utf-8") as source: objects = json.load(source)
    except (OSError, json.JSONDecodeError) as error:
        print(f"error: cannot read PipeWire dump: {error}", file=sys.stderr); return 2
    video_devices = []
    source_nodes = []
    libcamera_devices = []
    libcamera_sources = []
    for item in objects:
        values = props(item); media = values.get("media.class", ""); is_libcamera = libcamera(values)
        if item.get("type") == "PipeWire:Interface:Device" and media.startswith("Video/"):
            video_devices.append(item)
            if is_libcamera: libcamera_devices.append(item)
        if item.get("type") == "PipeWire:Interface:Node" and media.startswith("Video/Source"):
            source_nodes.append(item)
            if is_libcamera: libcamera_sources.append(item)
    print(f"PIPEWIRE_VIDEO_DEVICE_COUNT={len(video_devices)}")
    print(f"PIPEWIRE_VIDEO_SOURCE_NODE_COUNT={len(source_nodes)}")
    print(f"PIPEWIRE_LIBCAMERA_DEVICE_COUNT={len(libcamera_devices)}")
    print(f"PIPEWIRE_LIBCAMERA_SOURCE_COUNT={len(libcamera_sources)}")
    for label, items in (("VIDEO_DEVICE", video_devices), ("VIDEO_SOURCE_NODE", source_nodes)):
        for item in items:
            print(f"{label}\t", end=""); describe(item)
    if not source_nodes:
        print("INFO: no application-facing Video/Source nodes; inspect Video/Device and libcamera counts before diagnosing the browser.")
    return 0

if __name__ == "__main__": raise SystemExit(main())
