#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-only
# Install the user-level fixed-HD PipeWire virtual camera bridge.
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
unit=surface5-frontcamera-hd-bridge.service
destination="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user/${unit}"
physical_source='libcamera_input.__SB_.PCI0.I2C2.CAMF'
virtual_source='surface5_frontcamera_hd'

[ "${1:-}" != '--help' ] || { echo "Usage: $0"; exit 0; }
[ "$#" -eq 0 ] || { echo 'error: no arguments accepted' >&2; exit 2; }

for service in pipewire wireplumber; do
    systemctl --user --quiet is-active "$service" || { echo "error: user service is not active: $service" >&2; exit 1; }
done
for plugin in pipewiresrc pipewiresink; do
    gst-inspect-1.0 "$plugin" >/dev/null 2>&1 || { echo "error: required GStreamer PipeWire plugin is unavailable: $plugin" >&2; exit 1; }
done
wpctl status -n | grep -Fq "$physical_source" || { echo "error: required physical front source is absent: $physical_source" >&2; exit 1; }

install -D -m 644 "$root/systemd/user/$unit" "$destination"
systemctl --user daemon-reload
systemctl --user disable --now "$unit" 2>/dev/null || true
printf 'HD_BRIDGE=installed-inactive %s\n' "$virtual_source"
printf 'Start it before a call with: %s/scripts/start-user-hd-camera-bridge.sh\n' "$root"
