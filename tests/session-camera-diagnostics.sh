#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-only
# Read-only timing/ACL evidence for WirePlumber libcamera startup races.
set -u -o pipefail
[ "${1:-}" != '--help' ] || { echo 'Usage: session-camera-diagnostics.sh'; exit 0; }
out="${HOME}/Pictures/surface5-frontcamera-tests/$(date -u +%Y%m%dT%H%M%SZ)-session-acl-diagnostics"
umask 077; mkdir -p "$out" || exit 2
report="$out/report.txt"
run() { echo -e "\n===== $1 =====" >>"$report"; shift; "$@" >>"$report" 2>&1 || echo "[exit $?]" >>"$report"; }
run 'media node stat' stat /dev/media0 /dev/media1
run 'media node ACL' getfacl /dev/media0 /dev/media1
run 'udev media0' udevadm info --query=all --name=/dev/media0
run 'udev media1' udevadm info --query=all --name=/dev/media1
run 'login session' loginctl session-status
run 'seat0' loginctl seat-status seat0
run 'WirePlumber start timestamps' systemctl --user show wireplumber -p ActiveEnterTimestamp -p ExecMainStartTimestamp
run 'boot journal timing' bash -c "journalctl -b --no-pager | grep -Ei 'media0|media1|uaccess|ACL|logind|seat|wireplumber' || true"
printf 'SESSION ACL RESULTS:\n%s\n' "$out"
