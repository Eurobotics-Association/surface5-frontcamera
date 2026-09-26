#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-only
# Report only the managed system-Firefox PipeWire integration state.
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
profile="${XDG_DATA_HOME:-$HOME/.local/share}/surface5-frontcamera/firefox-pipewire-profile"
[ "${1:-}" != '--help' ] || { echo "Usage: $0"; exit 0; }
[ "$#" -eq 0 ] || { echo 'error: no arguments accepted' >&2; exit 2; }

firefox=$(command -v firefox 2>/dev/null || true)
if [ -n "$firefox" ]; then printf 'FIREFOX=%s\n' "$firefox"; "$firefox" --version; else echo 'FIREFOX=missing'; fi
brave=$(command -v brave-browser-stable 2>/dev/null || command -v brave-browser 2>/dev/null || true)
if [ -n "$brave" ]; then printf 'BRAVE=present-unsupported %s\n' "$brave"; "$brave" --version 2>&1 || true; else echo 'BRAVE=missing'; fi
if [ -f "$profile/user.js" ] && grep -Fxq 'user_pref("media.webrtc.camera.allow-pipewire", true);' "$profile/user.js"; then
    echo "MANAGED_PROFILE=present $profile"
else
    echo "MANAGED_PROFILE=missing-or-unexpected $profile"
fi
systemctl --user is-enabled surface5-wireplumber-camera-recovery.service 2>&1 || true
systemctl --user --quiet is-active pipewire wireplumber xdg-desktop-portal && echo 'USER_SERVICES=active' || echo 'USER_SERVICES=inactive'
wpctl status -n | grep -F 'libcamera_input.__SB_.PCI0.I2C2.CAMF' || true
gdbus call --session --dest org.freedesktop.portal.Desktop \
    --object-path /org/freedesktop/portal/desktop \
    --method org.freedesktop.DBus.Properties.Get \
    org.freedesktop.portal.Camera IsCameraPresent 2>&1 || true
"$(cd "$(dirname "$0")" && pwd)/status-user-hd-camera-bridge.sh" || true
"$root/scripts/status-user-firefox-camera-launchers.sh" || true
