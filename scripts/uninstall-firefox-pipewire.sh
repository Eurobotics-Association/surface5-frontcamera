#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-only
# Remove only the managed Firefox PipeWire profile and recovery unit.
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
data_home="${XDG_DATA_HOME:-$HOME/.local/share}"
state_dir="$data_home/surface5-frontcamera"
profile="$state_dir/firefox-pipewire-profile"
manifest="$state_dir/deployment.env"
[ "${1:-}" != '--help' ] || { echo "Usage: $0"; exit 0; }
[ "$#" -eq 0 ] || { echo 'error: no arguments accepted' >&2; exit 2; }
case "$profile" in
    "${XDG_DATA_HOME:-$HOME/.local/share}"/surface5-frontcamera/firefox-pipewire-profile) ;;
    *) echo 'error: unsafe managed profile path' >&2; exit 2 ;;
esac
systemctl --user stop surface5-firefox-hd-camera.service 2>/dev/null || true
rm -rf "$profile"
"$root/scripts/uninstall-user-firefox-camera-launchers.sh"
"$root/scripts/uninstall-user-hd-camera-bridge.sh"
"$root/scripts/uninstall-user-camera-recovery.sh"
rm -f "$manifest"
rmdir "$state_dir" 2>/dev/null || true
printf 'Removed managed Firefox PipeWire integration. Normal Firefox profiles were not changed.\n'
