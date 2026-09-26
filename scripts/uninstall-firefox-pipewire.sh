#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-only
# Remove only the managed Firefox PipeWire profile and recovery unit.
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
profile="${XDG_DATA_HOME:-$HOME/.local/share}/surface5-frontcamera/firefox-pipewire-profile"
[ "${1:-}" != '--help' ] || { echo "Usage: $0"; exit 0; }
[ "$#" -eq 0 ] || { echo 'error: no arguments accepted' >&2; exit 2; }
case "$profile" in
    "${XDG_DATA_HOME:-$HOME/.local/share}"/surface5-frontcamera/firefox-pipewire-profile) ;;
    *) echo 'error: unsafe managed profile path' >&2; exit 2 ;;
esac
rm -rf "$profile"
"$root/scripts/uninstall-user-firefox-camera-launchers.sh"
"$root/scripts/uninstall-user-hd-camera-bridge.sh"
"$root/scripts/uninstall-user-camera-recovery.sh"
printf 'Removed managed Firefox PipeWire integration. Normal Firefox profiles were not changed.\n'
