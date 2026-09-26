#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-only
# Deploy system-Firefox PipeWire camera support in an isolated managed profile.
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
profile="${XDG_DATA_HOME:-$HOME/.local/share}/surface5-frontcamera/firefox-pipewire-profile"
template="$root/config/firefox/firefox-pipewire-user.js"

usage() { echo "Usage: $0"; }
[ "${1:-}" != '--help' ] || { usage; exit 0; }
[ "$#" -eq 0 ] || { usage >&2; exit 2; }

firefox=$(command -v firefox 2>/dev/null || true)
brave=''
for candidate in brave-browser-stable brave-browser; do
    candidate_path=$(command -v "$candidate" 2>/dev/null || true)
    if [ -n "$candidate_path" ]; then
        brave="$candidate_path"
        break
    fi
done
if [ -n "$firefox" ] && [ -x "$firefox" ]; then
    printf 'BROWSER_FIREFOX=present %s\n' "$firefox"
    "$firefox" --version 2>&1 || true
else
    echo 'BROWSER_FIREFOX=missing'
fi
if [ -n "$brave" ]; then
    printf 'BROWSER_BRAVE=present-unsupported %s\n' "$brave"
    "$brave" --version 2>&1 || true
else
    echo 'BROWSER_BRAVE=missing'
fi
[ -n "$firefox" ] && [ -x "$firefox" ] || { echo 'error: system Firefox is required; Brave is detected but not supported by this deployment' >&2; exit 2; }
for service in pipewire wireplumber xdg-desktop-portal; do
    systemctl --user --quiet is-active "$service" || { echo "error: user service is not active: $service" >&2; exit 1; }
done

umask 077
mkdir -p "$profile"
chmod 700 "$profile"
if [ -e "$profile/user.js" ] && ! cmp -s "$template" "$profile/user.js"; then
    echo "error: managed profile has an unexpected user.js; run ./scripts/uninstall-firefox-pipewire.sh first" >&2
    exit 1
fi
if [ ! -e "$profile/user.js" ]; then
    install -m 600 "$template" "$profile/user.js"
fi

wireplumber_pid_before=$(systemctl --user show wireplumber.service --property=MainPID --value)
"$root/scripts/install-user-camera-recovery.sh" --no-start
systemctl --user restart wireplumber.service
restarted=false
for _ in $(seq 1 20); do
    wireplumber_pid_after=$(systemctl --user show wireplumber.service --property=MainPID --value)
    if [ "$wireplumber_pid_after" != 0 ] && [ "$wireplumber_pid_after" != "$wireplumber_pid_before" ] && systemctl --user --quiet is-active wireplumber.service; then
        restarted=true
        break
    fi
    sleep 1
done
[ "$restarted" = true ] || {
    echo 'error: WirePlumber did not complete the requested restart' >&2
    exit 1
}

recovered=false
stable_checks=0
for _ in $(seq 1 25); do
    sources=$(wpctl status -n 2>&1 || true)
    portal=$(gdbus call --session --dest org.freedesktop.portal.Desktop \
        --object-path /org/freedesktop/portal/desktop \
        --method org.freedesktop.DBus.Properties.Get \
        org.freedesktop.portal.Camera IsCameraPresent 2>&1 || true)
    if grep -Fq 'libcamera_input.__SB_.PCI0.I2C2.CAMF' <<<"$sources" && grep -Fq 'true' <<<"$portal"; then
        stable_checks=$((stable_checks + 1))
        if [ "$stable_checks" -eq 3 ]; then
            recovered=true
            break
        fi
    else
        stable_checks=0
    fi
    sleep 1
done
[ "$recovered" = true ] || {
    echo 'error: PipeWire front-camera source or Camera portal did not remain healthy after recovery' >&2
    exit 1
}

"$root/scripts/install-user-hd-camera-bridge.sh"
"$root/scripts/install-user-firefox-camera-launchers.sh"

printf 'Installed Firefox PipeWire integration and desktop launchers.\n'
printf 'Open “Firefox — Surface5 HD Front Camera” from the application menu.\n'
printf 'After a call, open “Stop Surface5 HD Front Camera” to release the LED.\n'
