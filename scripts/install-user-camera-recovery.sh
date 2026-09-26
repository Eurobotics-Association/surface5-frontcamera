#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-only
# Install the narrowly scoped per-user WirePlumber graphical-session recovery.
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
unit=surface5-wireplumber-camera-recovery.service
destination="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user/${unit}"
[ "${1:-}" != '--help' ] || { echo "Usage: $0 [--no-start]"; exit 0; }
[ "$#" -le 1 ] || { echo 'error: too many arguments' >&2; exit 2; }
case "${1:-}" in
    '') start_now=true ;;
    --no-start) start_now=false ;;
    *) echo "error: unknown argument: $1" >&2; exit 2 ;;
esac
install -D -m 644 "$root/systemd/user/$unit" "$destination"
systemctl --user daemon-reload
systemctl --user enable "$unit"
if [ "$start_now" = true ]; then systemctl --user start "$unit"; fi
systemctl --user --no-pager --full status "$unit"
