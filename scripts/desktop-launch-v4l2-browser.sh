#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-only
# Start the neutral V4L2 bridge, then one supported browser.  It never edits a
# browser profile or enables experimental browser features.
set -euo pipefail

browser=${1:?usage: $0 firefox|brave}
unit=surface5-frontcamera-v4l2-bridge.service
case "$browser" in
    firefox) executable=$(command -v firefox 2>/dev/null || true); label=Firefox ;;
    brave) executable=$(command -v brave-browser-stable 2>/dev/null || command -v brave-browser 2>/dev/null || true); label=Brave ;;
    *) echo "Surface5 HD camera: unsupported browser: $browser" >&2; exit 2 ;;
esac
[ -n "$executable" ] || { echo "Surface5 HD camera: $label is not installed" >&2; exit 1; }
[ -c /dev/video20 ] || { echo 'Surface5 HD camera: /dev/video20 is absent; run the system installer first' >&2; exit 1; }

systemctl --user daemon-reload
systemctl --user start "$unit"
for _ in $(seq 1 15); do
    camera=$(v4l2-ctl --device=/dev/video20 --all 2>&1 || true)
    if systemctl --user --quiet is-active "$unit" && grep -Fq 'Video Capture' <<<"$camera" && grep -Fq 'Width/Height      : 1280/720' <<<"$camera"; then
        systemd-run --user --quiet --collect --service-type=exec --unit="surface5-${browser}-hd-camera" "$executable" about:blank || true
        exit 0
    fi
    sleep 1
done
systemctl --user --no-pager --full status "$unit" >&2 || true
echo 'Surface5 HD camera: V4L2 camera did not become ready' >&2
exit 1
