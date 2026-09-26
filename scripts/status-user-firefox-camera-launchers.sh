#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-only
# Report only the user-owned Firefox HD-camera desktop launchers.
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
data_home="${XDG_DATA_HOME:-$HOME/.local/share}"
applications="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
desktop_dir=$(xdg-user-dir DESKTOP 2>/dev/null || printf '%s/Desktop' "$HOME")
launcher="$data_home/surface5-frontcamera/bin/firefox-surface5-hd-camera"
stopper="$data_home/surface5-frontcamera/bin/stop-surface5-hd-camera"
desktop_launcher="$applications/surface5-firefox-hd-camera.desktop"
desktop_stopper="$applications/surface5-stop-hd-camera.desktop"
desktop_shortcut_launcher="$desktop_dir/Firefox — Surface5 HD Front Camera.desktop"
desktop_shortcut_stopper="$desktop_dir/Stop Surface5 HD Front Camera.desktop"
case "${1:-}" in
    '') quiet=false ;;
    --quiet) quiet=true ;;
    --help) echo "Usage: $0 [--quiet]"; exit 0 ;;
    *) echo 'error: unknown argument' >&2; exit 2 ;;
esac
[ "$#" -le 1 ] || { echo 'error: too many arguments' >&2; exit 2; }

for item in "$launcher" "$stopper" "$desktop_launcher" "$desktop_stopper" "$desktop_shortcut_launcher" "$desktop_shortcut_stopper"; do
    if [ "$quiet" = false ] && [ -e "$item" ]; then
        printf 'FIREFOX_DESKTOP_ITEM=present %s\n' "$item"
    elif [ "$quiet" = false ]; then
        printf 'FIREFOX_DESKTOP_ITEM=missing %s\n' "$item"
    fi
done
if [ -x "$launcher" ] && grep -Fq "$launcher" "$desktop_launcher" 2>/dev/null && [ -x "$stopper" ] && grep -Fq "$stopper" "$desktop_stopper" 2>/dev/null && [ -x "$desktop_shortcut_launcher" ] && [ -x "$desktop_shortcut_stopper" ]; then
    if cmp -s "$root/scripts/desktop-launch-firefox-hd-camera.sh" "$launcher" && cmp -s "$root/scripts/desktop-stop-firefox-hd-camera.sh" "$stopper"; then
        [ "$quiet" = true ] || echo 'FIREFOX_DESKTOP_LAUNCHERS=ready-current'
        exit 0
    else
        [ "$quiet" = true ] || echo 'FIREFOX_DESKTOP_LAUNCHERS=ready-stale-rerun-installer'
    fi
else
    [ "$quiet" = true ] || echo 'FIREFOX_DESKTOP_LAUNCHERS=missing-or-unexpected'
fi
exit 1
