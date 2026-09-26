#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-only
# Report only the user-owned Firefox HD-camera desktop launchers.
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
data_home="${XDG_DATA_HOME:-$HOME/.local/share}"
applications="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
launcher="$data_home/surface5-frontcamera/bin/firefox-surface5-hd-camera"
stopper="$data_home/surface5-frontcamera/bin/stop-surface5-hd-camera"
desktop_launcher="$applications/surface5-firefox-hd-camera.desktop"
desktop_stopper="$applications/surface5-stop-hd-camera.desktop"
[ "${1:-}" != '--help' ] || { echo "Usage: $0"; exit 0; }
[ "$#" -eq 0 ] || { echo 'error: no arguments accepted' >&2; exit 2; }

for item in "$launcher" "$stopper" "$desktop_launcher" "$desktop_stopper"; do
    if [ -e "$item" ]; then
        printf 'FIREFOX_DESKTOP_ITEM=present %s\n' "$item"
    else
        printf 'FIREFOX_DESKTOP_ITEM=missing %s\n' "$item"
    fi
done
if [ -x "$launcher" ] && grep -Fq "$launcher" "$desktop_launcher" 2>/dev/null && [ -x "$stopper" ] && grep -Fq "$stopper" "$desktop_stopper" 2>/dev/null; then
    if cmp -s "$root/scripts/desktop-launch-firefox-hd-camera.sh" "$launcher" && cmp -s "$root/scripts/desktop-stop-firefox-hd-camera.sh" "$stopper"; then
        echo 'FIREFOX_DESKTOP_LAUNCHERS=ready-current'
    else
        echo 'FIREFOX_DESKTOP_LAUNCHERS=ready-stale-rerun-installer'
    fi
else
    echo 'FIREFOX_DESKTOP_LAUNCHERS=missing-or-unexpected'
fi
