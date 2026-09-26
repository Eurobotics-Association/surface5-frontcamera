#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-only
# Launch the deployed Firefox HD-camera profile from a desktop entry.
set -euo pipefail

data_home="${XDG_DATA_HOME:-$HOME/.local/share}"
profile="$data_home/surface5-frontcamera/firefox-pipewire-profile"
unit=surface5-frontcamera-hd-bridge.service
virtual_source=surface5_frontcamera_hd

notify() {
    command -v notify-send >/dev/null 2>&1 || return 0
    notify-send --app-name='Surface5 front camera' "$@" || true
}

fail() {
    printf 'Surface5 HD Front Camera: %s\n' "$*" >&2
    notify --urgency=critical 'Surface5 HD Front Camera' "$*"
    exit 1
}

[ "$#" -eq 0 ] || fail 'the desktop launcher does not accept arguments'
[ -f "$profile/user.js" ] || fail 'integration is not installed; run the repository installer first'
firefox=$(command -v firefox 2>/dev/null || true)
[ -n "$firefox" ] && [ -x "$firefox" ] || fail 'system Firefox is not available'
systemctl --user --quiet is-active pipewire wireplumber xdg-desktop-portal || fail 'PipeWire, WirePlumber, or the camera portal is inactive'

systemctl --user start "$unit" || fail 'could not start the fixed-HD camera bridge'
for _ in $(seq 1 15); do
    if systemctl --user --quiet is-active "$unit" && wpctl status -n | grep -Fq "$virtual_source"; then
        notify 'Surface5 HD Front Camera' 'Camera bridge started. Select Surface5_Front_Camera_HD in Firefox.'
        exec "$firefox" --no-remote --profile "$profile"
    fi
    sleep 1
done

systemctl --user stop "$unit" || true
fail 'the fixed-HD camera source did not appear; run the repository status command'
