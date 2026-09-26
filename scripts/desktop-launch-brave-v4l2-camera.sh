#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-only
set -euo pipefail

unit=surface5-frontcamera-brave-v4l2-bridge.service
brave=$(command -v brave-browser-stable 2>/dev/null || command -v brave-browser 2>/dev/null || true)
[ -n "$brave" ] || { echo 'Surface5 Brave camera: Brave is not installed' >&2; exit 1; }
[ -c /dev/video20 ] || { echo 'Surface5 Brave camera: /dev/video20 is absent; run the root installer first' >&2; exit 1; }
if systemctl --user --quiet is-active surface5-frontcamera-hd-bridge.service; then
    echo 'Surface5 Brave camera: Firefox HD bridge is active; stop it before starting Brave' >&2
    exit 1
fi
systemctl --user start "$unit"
for _ in $(seq 1 15); do
    camera=$(v4l2-ctl --device=/dev/video20 --all 2>&1 || true)
    if systemctl --user --quiet is-active "$unit" && grep -Fq 'Video Capture' <<<"$camera" && grep -Fq 'Width/Height      : 1280/720' <<<"$camera"; then
        systemd-run --user --quiet --collect --service-type=exec --unit=surface5-brave-v4l2-browser "$brave" about:blank || true
        exit 0
    fi
    sleep 1
done
systemctl --user --no-pager --full status "$unit" >&2 || true
echo 'Surface5 Brave camera: V4L2 camera did not become ready' >&2
exit 1
