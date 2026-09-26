#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-only
# Check the Firefox desktop-launcher deployment without changing the real user profile.
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
test_data=$(mktemp -d /tmp/surface5-firefox-launchers.XXXXXX)
trap 'rm -rf "$test_data"' EXIT
test_home="$test_data/home"
test_data_home="$test_home/data"

command -v firefox >/dev/null 2>&1 || { echo 'SKIP: system Firefox is unavailable'; exit 0; }
mkdir -p "$test_data_home/surface5-frontcamera/firefox-pipewire-profile"
printf '%s\n' 'user_pref("media.webrtc.camera.allow-pipewire", true);' > "$test_data_home/surface5-frontcamera/firefox-pipewire-profile/user.js"

HOME="$test_home" XDG_DATA_HOME="$test_data_home" "$root/scripts/install-user-firefox-camera-launchers.sh"
launcher="$test_data_home/surface5-frontcamera/bin/firefox-surface5-hd-camera"
stopper="$test_data_home/surface5-frontcamera/bin/stop-surface5-hd-camera"
desktop_launcher="$test_data_home/applications/surface5-firefox-hd-camera.desktop"
desktop_stopper="$test_data_home/applications/surface5-stop-hd-camera.desktop"
desktop_shortcut_launcher="$test_home/Desktop/Firefox — Surface5 HD Front Camera.desktop"
desktop_shortcut_stopper="$test_home/Desktop/Stop Surface5 HD Front Camera.desktop"

test -x "$launcher"
test -x "$stopper"
grep -Fqx "Exec=\"$launcher\"" "$desktop_launcher"
grep -Fqx "Exec=\"$stopper\"" "$desktop_stopper"
grep -Fqx 'Categories=Network;' "$desktop_launcher"
grep -Fqx 'Categories=Utility;' "$desktop_stopper"
grep -Fqx 'StartupWMClass=firefox' "$desktop_launcher"
test -x "$desktop_shortcut_launcher"
test -x "$desktop_shortcut_stopper"
if command -v desktop-file-validate >/dev/null 2>&1; then
    desktop-file-validate "$desktop_launcher" "$desktop_stopper"
fi
HOME="$test_home" XDG_DATA_HOME="$test_data_home" "$root/scripts/status-user-firefox-camera-launchers.sh" | grep -Fxq 'FIREFOX_DESKTOP_LAUNCHERS=ready-current'
HOME="$test_home" XDG_DATA_HOME="$test_data_home" "$root/scripts/uninstall-user-firefox-camera-launchers.sh"
test ! -e "$launcher"
test ! -e "$stopper"
test ! -e "$desktop_launcher"
test ! -e "$desktop_stopper"
test ! -e "$desktop_shortcut_launcher"
test ! -e "$desktop_shortcut_stopper"
printf 'FIREFOX_DESKTOP_LAUNCHER_TEST=passed\n'
