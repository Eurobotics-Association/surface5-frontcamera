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
systemctl --user enable --now "$unit"

for _ in $(seq 1 15); do
    if systemctl --user --quiet is-active "$unit" && wpctl status -n | grep -Fq "$virtual_source"; then
        printf 'HD_BRIDGE=active %s\n' "$virtual_source"
        exit 0
    fi
    sleep 1
done
systemctl --user --no-pager --full status "$unit" || true
systemctl --user disable --now "$unit" 2>/dev/null || true
rm -f "$destination"
systemctl --user daemon-reload
echo "error: fixed-HD virtual source did not appear: $virtual_source" >&2
exit 1
