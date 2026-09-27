#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-only
# Install only the user-owned desktop launchers for the managed Firefox camera profile.
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
data_home="${XDG_DATA_HOME:-$HOME/.local/share}"
applications="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
desktop_dir=$(xdg-user-dir DESKTOP 2>/dev/null || printf '%s/Desktop' "$HOME")
launcher_dir="$data_home/surface5-frontcamera/bin"
launcher="$launcher_dir/firefox-surface5-hd-camera"
stopper="$launcher_dir/stop-surface5-hd-camera"
desktop_launcher="$applications/surface5-firefox-hd-camera.desktop"
desktop_stopper="$applications/surface5-stop-hd-camera.desktop"
desktop_shortcut_launcher="$desktop_dir/Firefox — Surface5 HD Front Camera.desktop"
desktop_shortcut_stopper="$desktop_dir/Stop Surface5 HD Front Camera.desktop"

usage() { echo "Usage: $0"; }
[ "${1:-}" != '--help' ] || { usage; exit 0; }
[ "$#" -eq 0 ] || { usage >&2; exit 2; }

firefox=$(command -v firefox 2>/dev/null || true)
[ -n "$firefox" ] && [ -x "$firefox" ] || { echo 'error: system Firefox is required for the Surface5 HD camera launchers' >&2; exit 2; }
[ -f "$data_home/surface5-frontcamera/firefox-pipewire-profile/user.js" ] || { echo 'error: managed Firefox integration is not installed' >&2; exit 2; }
for command in systemctl systemd-run wpctl xdg-user-dir; do
    command -v "$command" >/dev/null 2>&1 || { echo "error: required command is unavailable: $command" >&2; exit 2; }
done

install -D -m 755 "$root/scripts/desktop-launch-firefox-hd-camera.sh" "$launcher"
install -D -m 755 "$root/scripts/desktop-stop-surface5-hd-camera.sh" "$stopper"
install -D -m 644 "$root/desktop/surface5-firefox-hd-camera.desktop.in" "$desktop_launcher"
install -D -m 644 "$root/desktop/surface5-stop-hd-camera.desktop.in" "$desktop_stopper"
while IFS= read -r line || [ -n "$line" ]; do
    printf '%s\n' "${line/@LAUNCHER@/$launcher}"
done < "$desktop_launcher" > "$desktop_launcher.tmp"
mv "$desktop_launcher.tmp" "$desktop_launcher"
while IFS= read -r line || [ -n "$line" ]; do
    printf '%s\n' "${line/@STOPPER@/$stopper}"
done < "$desktop_stopper" > "$desktop_stopper.tmp"
mv "$desktop_stopper.tmp" "$desktop_stopper"
chmod 644 "$desktop_launcher" "$desktop_stopper"
install -D -m 755 "$desktop_launcher" "$desktop_shortcut_launcher"
install -D -m 755 "$desktop_stopper" "$desktop_shortcut_stopper"
if command -v gio >/dev/null 2>&1; then
    gio set "$desktop_shortcut_launcher" metadata::trusted true 2>/dev/null || true
    gio set "$desktop_shortcut_stopper" metadata::trusted true 2>/dev/null || true
fi

command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "$applications" >/dev/null 2>&1 || true
printf 'FIREFOX_DESKTOP_LAUNCHERS=installed\n'
printf 'FIREFOX_DESKTOP_LAUNCHER=%s\n' "$desktop_launcher"
printf 'FIREFOX_DESKTOP_STOPPER=%s\n' "$desktop_stopper"
printf 'FIREFOX_DESKTOP_SHORTCUT=%s\n' "$desktop_shortcut_launcher"
printf 'FIREFOX_DESKTOP_STOP_SHORTCUT=%s\n' "$desktop_shortcut_stopper"
