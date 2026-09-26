#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-only
# Check the Firefox desktop-launcher deployment without changing the real user profile.
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
test_data=$(mktemp -d /tmp/surface5-firefox-launchers.XXXXXX)
trap 'rm -rf "$test_data"' EXIT

command -v firefox >/dev/null 2>&1 || { echo 'SKIP: system Firefox is unavailable'; exit 0; }
mkdir -p "$test_data/surface5-frontcamera/firefox-pipewire-profile"
printf '%s\n' 'user_pref("media.webrtc.camera.allow-pipewire", true);' > "$test_data/surface5-frontcamera/firefox-pipewire-profile/user.js"

XDG_DATA_HOME="$test_data" "$root/scripts/install-user-firefox-camera-launchers.sh"
launcher="$test_data/surface5-frontcamera/bin/firefox-surface5-hd-camera"
stopper="$test_data/surface5-frontcamera/bin/stop-surface5-hd-camera"
desktop_launcher="$test_data/applications/surface5-firefox-hd-camera.desktop"
desktop_stopper="$test_data/applications/surface5-stop-hd-camera.desktop"

test -x "$launcher"
test -x "$stopper"
grep -Fqx "Exec=\"$launcher\"" "$desktop_launcher"
grep -Fqx "Exec=\"$stopper\"" "$desktop_stopper"
grep -Fqx 'Categories=Network;' "$desktop_launcher"
grep -Fqx 'Categories=Utility;' "$desktop_stopper"
grep -Fqx 'StartupWMClass=firefox' "$desktop_launcher"
if command -v desktop-file-validate >/dev/null 2>&1; then
    desktop-file-validate "$desktop_launcher" "$desktop_stopper"
fi
XDG_DATA_HOME="$test_data" "$root/scripts/status-user-firefox-camera-launchers.sh" | grep -Fxq 'FIREFOX_DESKTOP_LAUNCHERS=ready-current'
XDG_DATA_HOME="$test_data" "$root/scripts/uninstall-user-firefox-camera-launchers.sh"
test ! -e "$launcher"
test ! -e "$stopper"
test ! -e "$desktop_launcher"
test ! -e "$desktop_stopper"
printf 'FIREFOX_DESKTOP_LAUNCHER_TEST=passed\n'
