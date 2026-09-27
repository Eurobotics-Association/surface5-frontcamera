#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-only
# Deploy the browser-neutral Surface5 HD V4L2 camera.  --system is the default:
# it gives every desktop user global menu entries without touching profiles.
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
. "$root/config/v4l2-deployment-version.env"
scope=system
mode=install
usage() {
    cat <<EOF
Usage: $0 [--system|--user] [--status|--rollback|--legacy-rollback|--version]

Default --system installs the native V4L2 policy, global menu entries and
diagnostic assets for every desktop user.  It asks for sudo when needed.
--user installs only current-user launchers/shortcuts and needs an existing
system V4L2 policy.
--legacy-rollback removes only the retired project PipeWire/old-Brave V4L2
deployment in the selected scope, before a clean new installation.
EOF
}
for arg in "$@"; do
    case "$arg" in
        --system) scope=system ;;
        --user) scope=user ;;
        --status) mode=status ;;
        --rollback) mode=rollback ;;
        --legacy-rollback) mode=legacy-rollback ;;
        --version) mode=version ;;
        --help) usage; exit 0 ;;
        *) usage >&2; exit 2 ;;
    esac
done
if [ "$mode" = version ]; then printf '%s %s\n' "$DEPLOYMENT_PRODUCT" "$DEPLOYMENT_VERSION"; exit 0; fi

user_paths() {
    data_home=${XDG_DATA_HOME:-$HOME/.local/share}
    state_dir="$data_home/surface5-frontcamera"
    applications="$data_home/applications"
    desktop_dir=$(xdg-user-dir DESKTOP 2>/dev/null || printf '%s/Desktop' "$HOME")
    user_unit="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user/surface5-frontcamera-v4l2-bridge.service"
    manifest="$state_dir/v4l2-deployment.env"
}
status() {
    printf 'DEPLOYMENT_EXPECTED=%s %s\n' "$DEPLOYMENT_PRODUCT" "$DEPLOYMENT_VERSION"
    if [ -f /etc/surface5-frontcamera/v4l2.env ]; then cat /etc/surface5-frontcamera/v4l2.env; else echo 'SYSTEM_RECORD=missing'; fi
    user_paths
    grep -E '^DEPLOYMENT_(PRODUCT|VERSION)=' "$manifest" 2>/dev/null || echo 'USER_RECORD=missing'
    v4l2-ctl --device=/dev/video20 --all 2>&1 | grep -E 'Card type|Video (Capture|Output)|Width/Height|Frames per second' || true
    systemctl --user --no-pager --full status surface5-frontcamera-v4l2-bridge.service 2>&1 || true
}
if [ "$mode" = status ]; then status; exit 0; fi

system_current() {
    [ -f /etc/surface5-frontcamera/v4l2.env ] &&
        grep -Fxq "DEPLOYMENT_PRODUCT=$DEPLOYMENT_PRODUCT" /etc/surface5-frontcamera/v4l2.env &&
        grep -Fxq "DEPLOYMENT_VERSION=$DEPLOYMENT_VERSION" /etc/surface5-frontcamera/v4l2.env &&
        cmp -s "$root/config/modprobe/surface5-frontcamera-v4l2loopback.conf" /etc/modprobe.d/surface5-frontcamera-v4l2loopback.conf &&
        cmp -s "$root/config/modules-load.d/surface5-frontcamera-v4l2loopback.conf" /etc/modules-load.d/surface5-frontcamera-v4l2loopback.conf &&
        cmp -s "$root/systemd/user/surface5-frontcamera-v4l2-bridge.service" /etc/systemd/user/surface5-frontcamera-v4l2-bridge.service &&
        cmp -s "$root/scripts/desktop-launch-v4l2-browser.sh" /usr/lib/surface5-frontcamera/bin/launch-v4l2-browser &&
        cmp -s "$root/scripts/desktop-stop-surface5-hd-camera.sh" /usr/lib/surface5-frontcamera/bin/stop-surface5-hd-camera &&
        cmp -s "$root/scripts/launch-v4l2-camera-diagnostic.sh" /usr/lib/surface5-frontcamera/bin/launch-v4l2-camera-diagnostic &&
        cmp -s "$root/tests/webrtc-camera-test.html" /usr/lib/surface5-frontcamera/tests/webrtc-camera-test.html &&
        cmp -s "$root/tests/browser-webrtc-server.py" /usr/lib/surface5-frontcamera/tests/browser-webrtc-server.py &&
        [ -c /dev/video20 ]
}

retire_legacy_user() {
    user_paths
    # The old isolated profile may contain browser state. It was created only
    # by the previous project deployment; never broaden this target.
    case "$state_dir/firefox-pipewire-profile" in "$data_home/surface5-frontcamera/firefox-pipewire-profile") ;; *) echo 'error: unsafe legacy profile path' >&2; exit 2;; esac
    systemctl --user disable --now surface5-frontcamera-hd-bridge.service surface5-frontcamera-brave-v4l2-bridge.service surface5-wireplumber-camera-recovery.service 2>/dev/null || true
    rm -f "${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user/surface5-frontcamera-hd-bridge.service" "${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user/surface5-frontcamera-brave-v4l2-bridge.service" "${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user/surface5-wireplumber-camera-recovery.service" "$state_dir/bin/firefox-surface5-hd-camera" "$state_dir/bin/brave-surface5-hd-camera" "$state_dir/bin/stop-brave-surface5-hd-camera" "$state_dir/bin/stop-surface5-hd-camera" "$applications/surface5-firefox-hd-camera.desktop" "$applications/surface5-brave-v4l2-camera.desktop" "$applications/surface5-stop-brave-v4l2-camera.desktop" "$applications/surface5-stop-hd-camera.desktop" "$desktop_dir/Firefox — Surface5 HD Front Camera.desktop" "$desktop_dir/Brave — Surface5 HD Front Camera.desktop" "$desktop_dir/Stop Brave Surface5 HD Front Camera.desktop" "$desktop_dir/Stop Surface5 HD Front Camera.desktop" "$state_dir/deployment.env" "$state_dir/brave-v4l2-deployment.env"
    rm -rf "$state_dir/firefox-pipewire-profile"
    systemctl --user daemon-reload
}

install_user() {
    user_paths
    command -v systemctl >/dev/null && command -v systemd-run >/dev/null && command -v v4l2-ctl >/dev/null && command -v xdg-user-dir >/dev/null || { echo 'error: required user-session tools are missing' >&2; exit 1; }
    [ -c /dev/video20 ] || { echo 'error: /dev/video20 is absent; an administrator must first run the default system install' >&2; exit 1; }
    if [ -f "$manifest" ] && grep -Fxq "DEPLOYMENT_PRODUCT=$DEPLOYMENT_PRODUCT" "$manifest" && grep -Fxq "DEPLOYMENT_VERSION=$DEPLOYMENT_VERSION" "$manifest" && cmp -s "$root/systemd/user/surface5-frontcamera-v4l2-bridge.service" "$user_unit" && cmp -s "$root/scripts/desktop-launch-v4l2-browser.sh" "$state_dir/bin/launch-v4l2-browser" && cmp -s "$root/scripts/desktop-stop-surface5-hd-camera.sh" "$state_dir/bin/stop-surface5-hd-camera" && [ -x "$desktop_dir/Firefox — Surface5 HD Front Camera.desktop" ] && [ -x "$desktop_dir/Brave — Surface5 HD Front Camera.desktop" ] && [ -x "$desktop_dir/Stop Surface5 HD Front Camera.desktop" ]; then
        echo "DEPLOYMENT=$DEPLOYMENT_PRODUCT $DEPLOYMENT_VERSION user already-current; no files or services changed."
        return
    fi
    if [ -e "$state_dir/firefox-pipewire-profile" ] || [ -e "${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user/surface5-frontcamera-hd-bridge.service" ]; then
        echo 'Migrating retired project PipeWire integration: removing only its isolated profile, units, launchers and trace.'
    fi
    retire_legacy_user
    mkdir -p "$state_dir/bin"
    install -D -m 644 "$root/systemd/user/surface5-frontcamera-v4l2-bridge.service" "$user_unit"
    install -D -m 755 "$root/scripts/desktop-launch-v4l2-browser.sh" "$state_dir/bin/launch-v4l2-browser"
    install -D -m 755 "$root/scripts/desktop-stop-surface5-hd-camera.sh" "$state_dir/bin/stop-surface5-hd-camera"
    install -D -m 755 "$root/scripts/launch-v4l2-camera-diagnostic.sh" "$state_dir/bin/launch-v4l2-camera-diagnostic"
    for browser in firefox brave; do
        install -D -m 644 "$root/desktop/surface5-${browser}-v4l2-camera.desktop.in" "$applications/surface5-${browser}-v4l2-camera.desktop"
        sed "s|@LAUNCHER@|$state_dir/bin/launch-v4l2-browser|g" "$applications/surface5-${browser}-v4l2-camera.desktop" > "$applications/surface5-${browser}-v4l2-camera.desktop.tmp" && mv "$applications/surface5-${browser}-v4l2-camera.desktop.tmp" "$applications/surface5-${browser}-v4l2-camera.desktop"
        install -D -m 755 "$applications/surface5-${browser}-v4l2-camera.desktop" "$desktop_dir/${browser^} — Surface5 HD Front Camera.desktop"
    done
    install -D -m 644 "$root/desktop/surface5-stop-hd-camera.desktop.in" "$applications/surface5-stop-hd-camera.desktop"
    sed "s|@STOPPER@|$state_dir/bin/stop-surface5-hd-camera|g" "$applications/surface5-stop-hd-camera.desktop" > "$applications/surface5-stop-hd-camera.desktop.tmp" && mv "$applications/surface5-stop-hd-camera.desktop.tmp" "$applications/surface5-stop-hd-camera.desktop"
    install -D -m 755 "$applications/surface5-stop-hd-camera.desktop" "$desktop_dir/Stop Surface5 HD Front Camera.desktop"
    install -D -m 644 "$root/desktop/surface5-camera-diagnostic.desktop.in" "$applications/surface5-camera-diagnostic.desktop"
    sed "s|@LAUNCHER@|$state_dir/bin/launch-v4l2-camera-diagnostic|g" "$applications/surface5-camera-diagnostic.desktop" > "$applications/surface5-camera-diagnostic.desktop.tmp" && mv "$applications/surface5-camera-diagnostic.desktop.tmp" "$applications/surface5-camera-diagnostic.desktop"
    systemctl --user daemon-reload
    umask 077
    printf 'DEPLOYMENT_PRODUCT=%s\nDEPLOYMENT_VERSION=%s\nDEPLOYMENT_SCOPE=user\n' "$DEPLOYMENT_PRODUCT" "$DEPLOYMENT_VERSION" > "$manifest"
    chmod 600 "$manifest"
    command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "$applications" >/dev/null 2>&1 || true
}
rollback_user() {
    user_paths
    systemctl --user disable --now surface5-frontcamera-v4l2-bridge.service 2>/dev/null || true
    rm -f "$user_unit" "$state_dir/bin/launch-v4l2-browser" "$state_dir/bin/stop-surface5-hd-camera" "$state_dir/bin/launch-v4l2-camera-diagnostic" "$applications/surface5-firefox-v4l2-camera.desktop" "$applications/surface5-brave-v4l2-camera.desktop" "$applications/surface5-stop-hd-camera.desktop" "$applications/surface5-camera-diagnostic.desktop" "$desktop_dir/Firefox — Surface5 HD Front Camera.desktop" "$desktop_dir/Brave — Surface5 HD Front Camera.desktop" "$desktop_dir/Stop Surface5 HD Front Camera.desktop" "$manifest"
    systemctl --user daemon-reload
}

if [ "$scope" = user ]; then
    if [ "$mode" = rollback ]; then
        rollback_user
        echo 'DEPLOYMENT=user rollback complete.'
    elif [ "$mode" = legacy-rollback ]; then
        retire_legacy_user
        echo 'LEGACY_DEPLOYMENT=user rollback complete; retired project browser integration removed.'
    else
        install_user
        echo "DEPLOYMENT=$DEPLOYMENT_PRODUCT $DEPLOYMENT_VERSION user installed-or-repaired."
    fi
    exit 0
fi

if [ "$(id -u)" -ne 0 ]; then
    echo 'Preparing system-wide Surface5 HD camera integration; sudo may request the administrator password.'
    if [ "$mode" = rollback ]; then
        exec sudo -- "$0" --system --rollback
    fi
    if [ "$mode" = legacy-rollback ]; then
        exec sudo -- "$0" --system --legacy-rollback
    fi
    exec sudo -- "$0" --system
fi
if [ "$mode" = install ] && system_current; then
    echo "DEPLOYMENT=$DEPLOYMENT_PRODUCT $DEPLOYMENT_VERSION system already-current; no files or services changed."
    exit 0
fi
if [ "$mode" = rollback ]; then
    systemctl --global disable surface5-frontcamera-v4l2-bridge.service 2>/dev/null || true
    rm -f /etc/modprobe.d/surface5-frontcamera-v4l2loopback.conf /etc/modules-load.d/surface5-frontcamera-v4l2loopback.conf /etc/systemd/user/surface5-frontcamera-v4l2-bridge.service /usr/share/applications/surface5-firefox-v4l2-camera.desktop /usr/share/applications/surface5-brave-v4l2-camera.desktop /usr/share/applications/surface5-stop-hd-camera.desktop /usr/share/applications/surface5-camera-diagnostic.desktop /etc/surface5-frontcamera/v4l2.env
    rm -rf /usr/lib/surface5-frontcamera
    if lsmod | grep -q '^v4l2loopback '; then
        modprobe -r v4l2loopback || { echo 'error: v4l2loopback is in use; it was not unloaded' >&2; exit 1; }
        lsmod | grep -q '^v4l2loopback ' && { echo 'error: v4l2loopback remained loaded after rollback' >&2; exit 1; }
    fi
    rmdir /etc/surface5-frontcamera 2>/dev/null || true
    echo 'DEPLOYMENT=system rollback complete; user-level shortcuts, if installed, remain owned by their users.'
    exit 0
fi
if [ "$mode" = legacy-rollback ]; then
    if [ -f /etc/surface5-frontcamera/v4l2.env ]; then
        echo 'error: the current V4L2 product is installed; use --rollback instead of legacy rollback' >&2
        exit 1
    fi
    if [ -c /dev/video20 ]; then
        label=$(udevadm info --query=property --name=/dev/video20 2>/dev/null | sed -n 's/^ID_V4L_PRODUCT=//p')
        [ "$label" = Surface5_Front_Camera_HD ] || { echo "error: refusing to unload v4l2loopback; /dev/video20 belongs to ${label:-unknown}" >&2; exit 1; }
    fi
    rm -f /etc/modprobe.d/surface5-frontcamera-v4l2loopback.conf /etc/modules-load.d/surface5-frontcamera-v4l2loopback.conf /etc/surface5-frontcamera/brave-v4l2.env /etc/systemd/user/surface5-frontcamera-brave-v4l2-bridge.service
    if lsmod | grep -q '^v4l2loopback '; then
        modprobe -r v4l2loopback || { echo 'error: v4l2loopback is still in use; stop the project bridge before retrying' >&2; exit 1; }
        lsmod | grep -q '^v4l2loopback ' && { echo 'error: v4l2loopback remained loaded after legacy rollback' >&2; exit 1; }
    fi
    [ ! -e /dev/video20 ] || { echo 'error: /dev/video20 remained after legacy rollback' >&2; exit 1; }
    rmdir /etc/surface5-frontcamera 2>/dev/null || true
    echo 'LEGACY_DEPLOYMENT=system rollback complete; old project loopback policy removed.'
    exit 0
fi
kernel=$(uname -r)
module_path=$(modinfo -n v4l2loopback 2>/dev/null || true)
case "$module_path" in "/lib/modules/$kernel/kernel/v4l2loopback/"*) ;; *) echo "error: native v4l2loopback is unavailable for $kernel; a DKMS substitute is intentionally not installed" >&2; exit 1;; esac
install -D -m 644 "$root/config/modprobe/surface5-frontcamera-v4l2loopback.conf" /etc/modprobe.d/surface5-frontcamera-v4l2loopback.conf
install -D -m 644 "$root/config/modules-load.d/surface5-frontcamera-v4l2loopback.conf" /etc/modules-load.d/surface5-frontcamera-v4l2loopback.conf
lsmod | grep -q '^v4l2loopback ' || modprobe v4l2loopback
[ -c /dev/video20 ] || { echo 'error: native loopback did not create /dev/video20' >&2; exit 1; }
label=$(udevadm info --query=property --name=/dev/video20 2>/dev/null | sed -n 's/^ID_V4L_PRODUCT=//p')
[ "$label" = Surface5_Front_Camera_HD ] || { echo "error: /dev/video20 label is unexpected: ${label:-unknown}" >&2; exit 1; }
install -D -m 644 "$root/systemd/user/surface5-frontcamera-v4l2-bridge.service" /etc/systemd/user/surface5-frontcamera-v4l2-bridge.service
install -D -m 755 "$root/scripts/desktop-launch-v4l2-browser.sh" /usr/lib/surface5-frontcamera/bin/launch-v4l2-browser
install -D -m 755 "$root/scripts/desktop-stop-surface5-hd-camera.sh" /usr/lib/surface5-frontcamera/bin/stop-surface5-hd-camera
install -D -m 755 "$root/scripts/launch-v4l2-camera-diagnostic.sh" /usr/lib/surface5-frontcamera/bin/launch-v4l2-camera-diagnostic
install -D -m 644 "$root/tests/webrtc-camera-test.html" /usr/lib/surface5-frontcamera/tests/webrtc-camera-test.html
install -D -m 644 "$root/tests/browser-webrtc-server.py" /usr/lib/surface5-frontcamera/tests/browser-webrtc-server.py
for browser in firefox brave; do
    sed 's|@LAUNCHER@|/usr/lib/surface5-frontcamera/bin/launch-v4l2-browser|g' "$root/desktop/surface5-${browser}-v4l2-camera.desktop.in" > "/usr/share/applications/surface5-${browser}-v4l2-camera.desktop"
done
sed 's|@STOPPER@|/usr/lib/surface5-frontcamera/bin/stop-surface5-hd-camera|g' "$root/desktop/surface5-stop-hd-camera.desktop.in" > /usr/share/applications/surface5-stop-hd-camera.desktop
sed 's|@LAUNCHER@|/usr/lib/surface5-frontcamera/bin/launch-v4l2-camera-diagnostic|g' "$root/desktop/surface5-camera-diagnostic.desktop.in" > /usr/share/applications/surface5-camera-diagnostic.desktop
install -d -m 755 /etc/surface5-frontcamera
printf 'DEPLOYMENT_PRODUCT=%s\nDEPLOYMENT_VERSION=%s\nDEPLOYMENT_SCOPE=system\nDEPLOYMENT_KERNEL=%s\n' "$DEPLOYMENT_PRODUCT" "$DEPLOYMENT_VERSION" "$kernel" > /etc/surface5-frontcamera/v4l2.env
chmod 644 /etc/surface5-frontcamera/v4l2.env
rm -f /etc/surface5-frontcamera/brave-v4l2.env
command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database /usr/share/applications >/dev/null 2>&1 || true
for browser in firefox brave; do
    if command -v "$browser" >/dev/null 2>&1 || { [ "$browser" = brave ] && { command -v brave-browser-stable >/dev/null 2>&1 || command -v brave-browser >/dev/null 2>&1; }; }; then
        echo "BROWSER_${browser^^}=detected"
    else
        echo "BROWSER_${browser^^}=missing; its global launcher remains available after the browser is installed and this installer is rerun."
    fi
done
echo "DEPLOYMENT=$DEPLOYMENT_PRODUCT $DEPLOYMENT_VERSION system installed-or-repaired. Each user may run $0 --user for Desktop shortcuts."
