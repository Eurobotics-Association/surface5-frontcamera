#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-only
# Launch the deployed Firefox HD-camera profile from a desktop entry.
set -euo pipefail

data_home="${XDG_DATA_HOME:-$HOME/.local/share}"
profile="$data_home/surface5-frontcamera/firefox-pipewire-profile"
unit=surface5-frontcamera-hd-bridge.service
virtual_source=surface5_frontcamera_hd
firefox_unit=surface5-firefox-hd-camera

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
command -v systemd-run >/dev/null 2>&1 || fail 'systemd-run is unavailable'
systemctl --user --quiet is-active pipewire wireplumber xdg-desktop-portal || fail 'PipeWire, WirePlumber, or the camera portal is inactive'

if systemctl --user --quiet is-active "$firefox_unit.service"; then
    notify 'Surface5 HD Front Camera' 'Managed Firefox is already running.'
    exit 0
fi
systemctl --user reset-failed "$firefox_unit.service" 2>/dev/null || true

systemctl --user start "$unit" || fail 'could not start the fixed-HD camera bridge'
for _ in $(seq 1 15); do
    if systemctl --user --quiet is-active "$unit" && wpctl status -n | grep -Fq "$virtual_source"; then
        break
    fi
    sleep 1
done

systemctl --user --quiet is-active "$unit" && wpctl status -n | grep -Fq "$virtual_source" || {
    systemctl --user stop "$unit" || true
    fail 'the fixed-HD camera source did not appear; run the repository status command'
}

# GNOME's Wayland Camera portal rejects Firefox when the browser remains in a
# custom app-menu scope.  A transient user service is neutral, persists after
# the short desktop launcher exits, and is removed automatically after Firefox
# closes.  It does not grant portal permission or change Firefox settings.
systemd-run --user --quiet --collect --service-type=exec --unit="$firefox_unit" \
    "$firefox" --no-remote --profile "$profile" about:blank || fail 'could not start managed Firefox service'
for _ in $(seq 1 5); do
    if systemctl --user --quiet is-active "$firefox_unit.service"; then
        notify 'Surface5 HD Front Camera' 'Firefox started. Select Surface5_Front_Camera_HD in the call site.'
        exit 0
    fi
    sleep 1
done
fail 'managed Firefox did not remain active; run the repository status command'
