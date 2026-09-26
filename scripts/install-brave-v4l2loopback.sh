#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-only
# Install only the native-kernel V4L2 loopback policy required by Brave.
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
version_file="$root/config/brave-v4l2-deployment-version.env"
modprobe_file=/etc/modprobe.d/surface5-frontcamera-v4l2loopback.conf
modules_file=/etc/modules-load.d/surface5-frontcamera-v4l2loopback.conf
record=/etc/surface5-frontcamera/brave-v4l2.env
. "$version_file"

usage() { echo "Usage: sudo $0 [--status|--rollback|--version]"; }
case "${1:-}" in
    '') mode=install ;;
    --status) mode=status ;;
    --rollback) mode=rollback ;;
    --version) printf '%s %s\n' "$DEPLOYMENT_PRODUCT" "$DEPLOYMENT_VERSION"; exit 0 ;;
    --help) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
esac
[ "$#" -le 1 ] || { usage >&2; exit 2; }

status() {
    printf 'BRAVE_V4L2_EXPECTED=%s %s\n' "$DEPLOYMENT_PRODUCT" "$DEPLOYMENT_VERSION"
    modinfo -n v4l2loopback 2>&1 || true
    [ -f "$record" ] && cat "$record" || echo "BRAVE_V4L2_RECORD=missing $record"
    [ -f "$modprobe_file" ] && echo "BRAVE_V4L2_MODPROBE=present $modprobe_file" || echo "BRAVE_V4L2_MODPROBE=missing"
    [ -f "$modules_file" ] && echo "BRAVE_V4L2_MODULES_LOAD=present $modules_file" || echo "BRAVE_V4L2_MODULES_LOAD=missing"
    [ -c /dev/video20 ] && udevadm info --query=property --name=/dev/video20 2>/dev/null | grep -E '^(DEVNAME|ID_V4L_PRODUCT|ID_V4L_CAPABILITIES)=' || true
}
[ "$mode" != status ] || { status; exit 0; }

# The normal user-facing installer calls this helper when the native policy is
# absent. Re-exec through sudo so the terminal requests a password only for a
# state-changing install or rollback; read-only status needs no elevation.
if [ "$(id -u)" -ne 0 ]; then
    exec sudo -- "$0" "$@"
fi

if [ "$mode" = rollback ]; then
    if lsmod | grep -q '^v4l2loopback '; then
        modprobe -r v4l2loopback || { echo 'error: v4l2loopback is in use; stop the Brave bridge first' >&2; exit 1; }
    fi
    rm -f "$modprobe_file" "$modules_file" "$record"
    rmdir /etc/surface5-frontcamera 2>/dev/null || true
    echo 'BRAVE_V4L2=rolled-back; native loopback policy removed.'
    exit 0
fi

kernel=$(uname -r)
module_path=$(modinfo -n v4l2loopback 2>/dev/null || true)
case "$module_path" in
    "/lib/modules/$kernel/kernel/v4l2loopback/"*) ;;
    *) echo "error: required native v4l2loopback module is unavailable for $kernel; do not install a DKMS substitute automatically" >&2; exit 1 ;;
esac
if [ -e /dev/video20 ]; then
    label=$(udevadm info --query=property --name=/dev/video20 2>/dev/null | sed -n 's/^ID_V4L_PRODUCT=//p')
    [ "$label" = Surface5_Front_Camera_HD ] || { echo "error: /dev/video20 is already owned by: ${label:-unknown}" >&2; exit 1; }
fi
install -D -m 644 "$root/config/modprobe/surface5-frontcamera-v4l2loopback.conf" "$modprobe_file"
install -D -m 644 "$root/config/modules-load.d/surface5-frontcamera-v4l2loopback.conf" "$modules_file"
if ! lsmod | grep -q '^v4l2loopback '; then
    modprobe v4l2loopback
fi
[ -c /dev/video20 ] || { echo 'error: v4l2loopback did not create /dev/video20' >&2; exit 1; }
label=$(udevadm info --query=property --name=/dev/video20 2>/dev/null | sed -n 's/^ID_V4L_PRODUCT=//p')
[ "$label" = Surface5_Front_Camera_HD ] || { echo "error: loopback label is unexpected: ${label:-unknown}" >&2; exit 1; }
install -d -m 755 /etc/surface5-frontcamera
umask 022
{
    printf 'DEPLOYMENT_PRODUCT=%s\n' "$DEPLOYMENT_PRODUCT"
    printf 'DEPLOYMENT_VERSION=%s\n' "$DEPLOYMENT_VERSION"
    printf 'DEPLOYMENT_KERNEL=%s\n' "$kernel"
} > "$record"
chmod 644 "$record"
echo 'BRAVE_V4L2=installed; native loopback will be loaded at boot.'
