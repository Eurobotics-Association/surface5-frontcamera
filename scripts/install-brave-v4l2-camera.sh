#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-only
# Deploy the user-level Brave V4L2 bridge and launchers, never Brave settings.
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
. "$root/config/brave-v4l2-deployment-version.env"
data_home="${XDG_DATA_HOME:-$HOME/.local/share}"
state_dir="$data_home/surface5-frontcamera"
unit=surface5-frontcamera-brave-v4l2-bridge.service
unit_destination="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user/$unit"
launcher_dir="$state_dir/bin"
applications="$data_home/applications"
desktop_dir=$(xdg-user-dir DESKTOP 2>/dev/null || printf '%s/Desktop' "$HOME")
manifest="$state_dir/brave-v4l2-deployment.env"

usage() { echo "Usage: $0 [--status|--rollback|--version]"; }
case "${1:-}" in
    '') mode=install ;;
    --status) exec "$root/scripts/status-brave-v4l2-camera.sh" ;;
    --rollback) exec "$root/scripts/uninstall-brave-v4l2-camera.sh" ;;
    --version) printf '%s %s\n' "$DEPLOYMENT_PRODUCT" "$DEPLOYMENT_VERSION"; exit 0 ;;
    --help) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
esac
[ "$#" -le 1 ] || { usage >&2; exit 2; }

brave=$(command -v brave-browser-stable 2>/dev/null || command -v brave-browser 2>/dev/null || true)
[ -n "$brave" ] || { echo 'error: Brave is not installed' >&2; exit 2; }
for command in systemctl systemd-run gst-inspect-1.0 v4l2-ctl wpctl xdg-user-dir; do
    command -v "$command" >/dev/null 2>&1 || { echo "error: required command is missing: $command" >&2; exit 2; }
done
for plugin in pipewiresrc v4l2sink videoconvert; do
    gst-inspect-1.0 "$plugin" >/dev/null 2>&1 || { echo "error: required GStreamer element is missing: $plugin" >&2; exit 1; }
done
if [ ! -f /etc/modprobe.d/surface5-frontcamera-v4l2loopback.conf ] || [ ! -f /etc/modules-load.d/surface5-frontcamera-v4l2loopback.conf ]; then
    echo 'Preparing the native V4L2 loopback policy; sudo may request your password.'
    "$root/scripts/install-brave-v4l2loopback.sh"
fi
node=$(v4l2-ctl --device=/dev/video20 --all 2>&1 || true)
grep -Fq 'Card type        : Surface5_Front_Camera_HD' <<<"$node" || { echo 'error: /dev/video20 is not prepared; first run sudo ./scripts/install-brave-v4l2loopback.sh' >&2; exit 1; }
wpctl status -n | grep -Fq 'libcamera_input.__SB_.PCI0.I2C2.CAMF' || { echo 'error: physical front PipeWire source is absent' >&2; exit 1; }

launcher="$launcher_dir/brave-surface5-hd-camera"
stopper="$launcher_dir/stop-surface5-hd-camera"
desktop_launcher="$applications/surface5-brave-v4l2-camera.desktop"
desktop_stopper="$applications/surface5-stop-hd-camera.desktop"
shortcut_launcher="$desktop_dir/Brave — Surface5 HD Front Camera.desktop"
shortcut_stopper="$desktop_dir/Stop Surface5 HD Front Camera.desktop"
legacy_stopper="$launcher_dir/stop-brave-surface5-hd-camera"
legacy_desktop_stopper="$applications/surface5-stop-brave-v4l2-camera.desktop"
legacy_shortcut_stopper="$desktop_dir/Stop Brave Surface5 HD Front Camera.desktop"
if [ -f "$manifest" ] && grep -Fxq "DEPLOYMENT_PRODUCT=$DEPLOYMENT_PRODUCT" "$manifest" && grep -Fxq "DEPLOYMENT_VERSION=$DEPLOYMENT_VERSION" "$manifest" && cmp -s "$root/systemd/user/$unit" "$unit_destination" && cmp -s "$root/scripts/desktop-launch-brave-v4l2-camera.sh" "$launcher" && cmp -s "$root/scripts/desktop-stop-surface5-hd-camera.sh" "$stopper" && grep -Fxq 'Categories=Network;' "$desktop_stopper" && [ -x "$shortcut_launcher" ] && [ -x "$shortcut_stopper" ] && grep -Fxq 'Categories=Network;' "$shortcut_stopper" && [ ! -e "$legacy_stopper" ] && [ ! -e "$legacy_desktop_stopper" ] && [ ! -e "$legacy_shortcut_stopper" ]; then
    echo "DEPLOYMENT=$DEPLOYMENT_PRODUCT $DEPLOYMENT_VERSION already-current; no services or files changed."
    exit 0
fi
install -D -m 644 "$root/systemd/user/$unit" "$unit_destination"
install -D -m 755 "$root/scripts/desktop-launch-brave-v4l2-camera.sh" "$launcher"
install -D -m 755 "$root/scripts/desktop-stop-surface5-hd-camera.sh" "$stopper"
install -D -m 644 "$root/desktop/surface5-brave-v4l2-camera.desktop.in" "$desktop_launcher"
install -D -m 644 "$root/desktop/surface5-stop-hd-camera.desktop.in" "$desktop_stopper"
sed "s|@LAUNCHER@|$launcher|g" "$desktop_launcher" > "$desktop_launcher.tmp" && mv "$desktop_launcher.tmp" "$desktop_launcher"
sed "s|@STOPPER@|$stopper|g" "$desktop_stopper" > "$desktop_stopper.tmp" && mv "$desktop_stopper.tmp" "$desktop_stopper"
chmod 644 "$desktop_launcher" "$desktop_stopper"
install -D -m 755 "$desktop_launcher" "$shortcut_launcher"
install -D -m 755 "$desktop_stopper" "$shortcut_stopper"
rm -f "$legacy_stopper" "$legacy_desktop_stopper" "$legacy_shortcut_stopper"
command -v gio >/dev/null 2>&1 && { gio set "$shortcut_launcher" metadata::trusted true 2>/dev/null || true; gio set "$shortcut_stopper" metadata::trusted true 2>/dev/null || true; }
systemctl --user daemon-reload
systemctl --user disable --now "$unit" 2>/dev/null || true
umask 077
mkdir -p "$state_dir"
printf 'DEPLOYMENT_PRODUCT=%s\nDEPLOYMENT_VERSION=%s\n' "$DEPLOYMENT_PRODUCT" "$DEPLOYMENT_VERSION" > "$manifest"
chmod 600 "$manifest"
command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "$applications" >/dev/null 2>&1 || true
echo "DEPLOYMENT=$DEPLOYMENT_PRODUCT $DEPLOYMENT_VERSION installed-or-repaired."
