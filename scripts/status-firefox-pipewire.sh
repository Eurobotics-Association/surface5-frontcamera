#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-only
# Report only the managed system-Firefox PipeWire integration state.
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
data_home="${XDG_DATA_HOME:-$HOME/.local/share}"
state_dir="$data_home/surface5-frontcamera"
profile="$state_dir/firefox-pipewire-profile"
version_file="$root/config/deployment-version.env"
manifest="$state_dir/deployment.env"
[ "${1:-}" != '--help' ] || { echo "Usage: $0"; exit 0; }
[ "$#" -eq 0 ] || { echo 'error: no arguments accepted' >&2; exit 2; }

if [ -f "$version_file" ]; then
    # shellcheck disable=SC1090
    . "$version_file"
    printf 'DEPLOYMENT_EXPECTED=%s %s\n' "${DEPLOYMENT_PRODUCT:-invalid}" "${DEPLOYMENT_VERSION:-invalid}"
else
    echo 'DEPLOYMENT_EXPECTED=missing-version-file'
fi
if [ -f "$manifest" ]; then
    grep -E '^DEPLOYMENT_(PRODUCT|VERSION|REVISION|INSTALLED_AT)=' "$manifest" || true
else
    echo "DEPLOYMENT_RECORD=missing $manifest"
fi

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
if systemctl --user --quiet is-active surface5-firefox-hd-camera.service; then
    echo 'MANAGED_FIREFOX=active-transient-service'
else
    echo 'MANAGED_FIREFOX=inactive'
fi
wpctl status -n | grep -F 'libcamera_input.__SB_.PCI0.I2C2.CAMF' || true
gdbus call --session --dest org.freedesktop.portal.Desktop \
    --object-path /org/freedesktop/portal/desktop \
    --method org.freedesktop.DBus.Properties.Get \
    org.freedesktop.portal.Camera IsCameraPresent 2>&1 || true
"$(cd "$(dirname "$0")" && pwd)/status-user-hd-camera-bridge.sh" || true
"$root/scripts/status-user-firefox-camera-launchers.sh" || true
