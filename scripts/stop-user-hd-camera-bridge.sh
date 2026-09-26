#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-only
# Stop the fixed-HD bridge to release the physical camera and turn off its LED.
set -euo pipefail

unit=surface5-frontcamera-hd-bridge.service
[ "${1:-}" != '--help' ] || { echo "Usage: $0"; exit 0; }
[ "$#" -eq 0 ] || { echo 'error: no arguments accepted' >&2; exit 2; }

systemctl --user stop "$unit"
printf 'HD_BRIDGE=stopped; the physical camera source was released.\n'
