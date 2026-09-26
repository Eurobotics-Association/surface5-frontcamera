#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-only
# Install the narrowly scoped per-user WirePlumber graphical-session recovery.
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
unit=surface5-wireplumber-camera-recovery.service
destination="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user/${unit}"
[ "${1:-}" != '--help' ] || { echo "Usage: $0"; exit 0; }
[ "$#" -eq 0 ] || { echo 'error: no arguments accepted' >&2; exit 2; }
install -D -m 644 "$root/systemd/user/$unit" "$destination"
systemctl --user daemon-reload
systemctl --user enable --now "$unit"
systemctl --user --no-pager --full status "$unit"
