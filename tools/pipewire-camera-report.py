#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0-only
"""Summarise PipeWire video-source nodes from a pw-dump JSON file."""

import json
import sys


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: pipewire-camera-report.py PW-DUMP.json", file=sys.stderr)
        return 2
    try:
        with open(sys.argv[1], encoding="utf-8") as source:
            objects = json.load(source)
    except (OSError, json.JSONDecodeError) as error:
        print(f"error: cannot read PipeWire dump: {error}", file=sys.stderr)
        return 2

    nodes = []
    for item in objects:
        if item.get("type") != "PipeWire:Interface:Node":
            continue
        props = item.get("info", {}).get("props", {})
        media_class = props.get("media.class", "")
        if media_class.startswith("Video/"):
            nodes.append((item.get("id", "?"), media_class, props))
    print(f"PIPEWIRE_VIDEO_NODE_COUNT={len(nodes)}")
    for node_id, media_class, props in nodes:
        print(
            "node_id={id}\tmedia.class={media}\tnode.name={name}\t"
            "node.description={description}\tdevice.api={api}".format(
                id=node_id,
                media=media_class,
                name=props.get("node.name", ""),
                description=props.get("node.description", ""),
                api=props.get("device.api", ""),
            )
        )
    if not nodes:
        print("INFO: no PipeWire Video/* nodes. This alone does not prove that libcamera capture failed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
