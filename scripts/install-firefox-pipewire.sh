#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-only
# Deploy system-Firefox PipeWire camera support in an isolated managed profile.
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
data_home="${XDG_DATA_HOME:-$HOME/.local/share}"
state_dir="$data_home/surface5-frontcamera"
profile="$state_dir/firefox-pipewire-profile"
template="$root/config/firefox/firefox-pipewire-user.js"
version_file="$root/config/deployment-version.env"
manifest="$state_dir/deployment.env"
recovery_unit=surface5-wireplumber-camera-recovery.service
bridge_unit=surface5-frontcamera-hd-bridge.service

[ -f "$version_file" ] || { echo "error: missing deployment version file: $version_file" >&2; exit 2; }
# shellcheck disable=SC1090
. "$version_file"
case "${DEPLOYMENT_PRODUCT:-}:${DEPLOYMENT_VERSION:-}" in
    EBtx-surface5-HDCam-patch:[0-9]*.[0-9]*.[0-9]*) ;;
    *) echo 'error: invalid deployment product or version' >&2; exit 2 ;;
esac

usage() {
    cat <<EOF
Usage: $0 [--status|--rollback|--version]

Without options, installs or repairs the Firefox HD-camera deployment.
--status    reports the installed deployment record and component state.
--rollback  removes only this project-owned Firefox deployment.
--version   prints the deployment product and version.
EOF
}
case "${1:-}" in
    '') mode=install ;;
    --status) exec "$root/scripts/status-firefox-pipewire.sh" ;;
    --rollback) exec "$root/scripts/uninstall-firefox-pipewire.sh" ;;
    --version) printf '%s %s\n' "$DEPLOYMENT_PRODUCT" "$DEPLOYMENT_VERSION"; exit 0 ;;
    --help) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
esac
[ "$#" -le 1 ] || { usage >&2; exit 2; }

manifest_value() {
    sed -n "s/^$1=//p" "$manifest" 2>/dev/null | tail -n 1
}

components_current() {
    [ -f "$profile/user.js" ] && cmp -s "$template" "$profile/user.js" || return 1
    cmp -s "$root/systemd/user/$recovery_unit" "${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user/$recovery_unit" || return 1
    cmp -s "$root/systemd/user/$bridge_unit" "${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user/$bridge_unit" || return 1
    "$root/scripts/status-user-firefox-camera-launchers.sh" --quiet
}

write_manifest() {
    local revision installed_at temp_manifest
    revision=$(git -C "$root" rev-parse --short=12 HEAD 2>/dev/null || printf 'source-tree')
    installed_at=$(date --iso-8601=seconds)
    umask 077
    mkdir -p "$state_dir"
    temp_manifest=$(mktemp "$state_dir/deployment.XXXXXX")
    {
        printf 'DEPLOYMENT_PRODUCT=%s\n' "$DEPLOYMENT_PRODUCT"
        printf 'DEPLOYMENT_VERSION=%s\n' "$DEPLOYMENT_VERSION"
        printf 'DEPLOYMENT_REVISION=%s\n' "$revision"
        printf 'DEPLOYMENT_INSTALLED_AT=%s\n' "$installed_at"
    } > "$temp_manifest"
    chmod 600 "$temp_manifest"
    mv "$temp_manifest" "$manifest"
}

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

if [ -f "$manifest" ] && [ "$(manifest_value DEPLOYMENT_PRODUCT)" != "$DEPLOYMENT_PRODUCT" ]; then
    echo "error: unexpected deployment record product at $manifest; inspect it before replacing it" >&2
    exit 1
fi
if components_current; then
    if [ "$(manifest_value DEPLOYMENT_PRODUCT)" = "$DEPLOYMENT_PRODUCT" ] && [ "$(manifest_value DEPLOYMENT_VERSION)" = "$DEPLOYMENT_VERSION" ]; then
        printf 'DEPLOYMENT=%s %s already-current; no services or files changed.\n' "$DEPLOYMENT_PRODUCT" "$DEPLOYMENT_VERSION"
    else
        write_manifest
        printf 'DEPLOYMENT=%s %s adopted-current; no services or files changed.\n' "$DEPLOYMENT_PRODUCT" "$DEPLOYMENT_VERSION"
    fi
    exit 0
fi

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
write_manifest

printf 'DEPLOYMENT=%s %s installed-or-repaired.\n' "$DEPLOYMENT_PRODUCT" "$DEPLOYMENT_VERSION"
printf 'Installed Firefox PipeWire integration and desktop launchers.\n'
printf 'Open “Firefox — Surface5 HD Front Camera” from the application menu.\n'
printf 'After a call, open “Stop Surface5 HD Front Camera” to release the LED.\n'
