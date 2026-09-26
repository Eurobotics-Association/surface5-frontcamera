#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-only
# Start the installed fixed-HD virtual camera bridge only for an active call.
set -euo pipefail

unit=surface5-frontcamera-hd-bridge.service
physical_source='libcamera_input.__SB_.PCI0.I2C2.CAMF'
virtual_source='surface5_frontcamera_hd'
[ "${1:-}" != '--help' ] || { echo "Usage: $0"; exit 0; }
[ "$#" -eq 0 ] || { echo 'error: no arguments accepted' >&2; exit 2; }

systemctl --user --quiet is-active pipewire wireplumber || { echo 'error: PipeWire or WirePlumber is inactive' >&2; exit 1; }
wpctl status -n | grep -Fq "$physical_source" || { echo "error: required physical front source is absent: $physical_source" >&2; exit 1; }
systemctl --user start "$unit"
for _ in $(seq 1 15); do
    if systemctl --user --quiet is-active "$unit" && wpctl status -n | grep -Fq "$virtual_source"; then
        printf 'HD_BRIDGE=active %s\n' "$virtual_source"
        exit 0
    fi
    sleep 1
done
systemctl --user --no-pager --full status "$unit" || true
systemctl --user stop "$unit" || true
echo "error: fixed-HD virtual source did not appear: $virtual_source" >&2
exit 1
