#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-only
# Report only the user-level fixed-HD virtual camera bridge installed here.
set -euo pipefail

unit=surface5-frontcamera-hd-bridge.service
virtual_source='surface5_frontcamera_hd'
[ "${1:-}" != '--help' ] || { echo "Usage: $0"; exit 0; }
[ "$#" -eq 0 ] || { echo 'error: no arguments accepted' >&2; exit 2; }

systemctl --user --no-pager --full status "$unit" || true
if systemctl --user --quiet is-active "$unit"; then
    echo 'HD_BRIDGE_ACTIVE=yes'
else
    echo 'HD_BRIDGE_ACTIVE=no'
fi
if wpctl status -n | grep -Fq "$virtual_source"; then
    echo "HD_BRIDGE_SOURCE=present $virtual_source"
else
    echo "HD_BRIDGE_SOURCE=absent $virtual_source"
fi
