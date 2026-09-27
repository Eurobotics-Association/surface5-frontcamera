#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-only
# Serve only the repository's textual WebRTC diagnostic on loopback.  It never
# captures or stores image pixels; browser events go to the private test area.
set -euo pipefail

root=${SURFACE5_FRONT_CAMERA_PREFIX:-/usr/lib/surface5-frontcamera}
[ -f "$root/tests/browser-webrtc-server.py" ] || root=$(cd "$(dirname "$0")/.." && pwd)
output_base="${XDG_PICTURES_DIR:-$HOME/Pictures}/surface5-frontcamera-tests"
mkdir -p "$output_base"
output="$output_base/$(date -u +%Y%m%dT%H%M%SZ)-browser-webrtc"
mkdir -p "$output"
port=${SURFACE5_CAMERA_TEST_PORT:-46080}
unit=surface5-frontcamera-browser-diagnostic
systemctl --user daemon-reload
systemctl --user start surface5-frontcamera-v4l2-bridge.service
systemctl --user stop "$unit.service" 2>/dev/null || true
systemd-run --user --quiet --collect --unit="$unit" /usr/bin/python3 "$root/tests/browser-webrtc-server.py" --root "$root/tests" --output "$output" --port "$port"
printf 'SURFACE5_CAMERA_DIAGNOSTIC_URL=http://127.0.0.1:%s/webrtc-camera-test.html\n' "$port"
printf 'SURFACE5_CAMERA_DIAGNOSTIC_LOGS=%s\n' "$output"
command -v xdg-open >/dev/null 2>&1 && xdg-open "http://127.0.0.1:$port/webrtc-camera-test.html" >/dev/null 2>&1 &
