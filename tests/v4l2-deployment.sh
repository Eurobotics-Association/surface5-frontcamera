#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-only
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
for file in "$root"/scripts/install-v4l2-camera.sh "$root"/scripts/install-from-github.sh "$root"/scripts/desktop-launch-v4l2-browser.sh "$root"/scripts/desktop-stop-surface5-hd-camera.sh "$root"/scripts/launch-v4l2-camera-diagnostic.sh; do
    bash -n "$file"
done
grep -Fq 'DEPLOYMENT_PRODUCT=EBtx-surface5-HDCam-V4L2' "$root/config/v4l2-deployment-version.env"
grep -Fq 'v4l2sink device=/dev/video20' "$root/systemd/user/surface5-frontcamera-v4l2-bridge.service"
grep -Fq 'exclusive_caps=1' "$root/config/modprobe/surface5-frontcamera-v4l2loopback.conf"
grep -Fq -- '--system|--user' "$root/scripts/install-v4l2-camera.sh"
grep -Fq -- '--legacy-rollback' "$root/scripts/install-v4l2-camera.sh"
grep -Fq 'browser-webrtc-server.py' "$root/scripts/install-v4l2-camera.sh"
grep -Fq 'archive/refs/heads' "$root/scripts/install-from-github.sh"
grep -Fq 'surface5-frontcamera-v4l2-bridge.service' "$root/scripts/desktop-stop-surface5-hd-camera.sh"
grep -Fq 'allBlack:false' "$root/docs/v4l2-deployment.md"
echo 'V4L2 deployment static checks passed'
