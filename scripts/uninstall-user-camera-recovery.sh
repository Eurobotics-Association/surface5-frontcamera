#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-only
# Remove only the per-user WirePlumber graphical-session recovery installed here.
set -euo pipefail
unit=surface5-wireplumber-camera-recovery.service
destination="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user/${unit}"
[ "${1:-}" != '--help' ] || { echo "Usage: $0"; exit 0; }
[ "$#" -eq 0 ] || { echo 'error: no arguments accepted' >&2; exit 2; }
systemctl --user disable --now "$unit" 2>/dev/null || true
rm -f "$destination"
systemctl --user daemon-reload
printf 'Removed %s\n' "$destination"
