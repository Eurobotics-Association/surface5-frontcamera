#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-only
# Remove only the user-owned Firefox HD-camera desktop launchers.
set -euo pipefail

data_home="${XDG_DATA_HOME:-$HOME/.local/share}"
applications="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
desktop_dir=$(xdg-user-dir DESKTOP 2>/dev/null || printf '%s/Desktop' "$HOME")
launcher_dir="$data_home/surface5-frontcamera/bin"
desktop_launcher="$applications/surface5-firefox-hd-camera.desktop"
desktop_stopper="$applications/surface5-stop-hd-camera.desktop"
desktop_shortcut_launcher="$desktop_dir/Firefox — Surface5 HD Front Camera.desktop"
desktop_shortcut_stopper="$desktop_dir/Stop Surface5 HD Front Camera.desktop"
[ "${1:-}" != '--help' ] || { echo "Usage: $0"; exit 0; }
[ "$#" -eq 0 ] || { echo 'error: no arguments accepted' >&2; exit 2; }

rm -f "$desktop_launcher" "$desktop_stopper" "$desktop_shortcut_launcher" "$desktop_shortcut_stopper"
rm -f "$launcher_dir/firefox-surface5-hd-camera" "$launcher_dir/stop-surface5-hd-camera"
rmdir "$launcher_dir" 2>/dev/null || true
command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "$applications" >/dev/null 2>&1 || true
printf 'Removed user Firefox HD-camera desktop launchers.\n'
