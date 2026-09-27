#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-only
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
for file in "$root"/scripts/*brave*v4l2*.sh "$root"/scripts/desktop-*brave*v4l2*.sh; do bash -n "$file"; done
grep -Fq 'exclusive_caps=1' "$root/config/modprobe/surface5-frontcamera-v4l2loopback.conf"
grep -Fq 'v4l2sink device=/dev/video20' "$root/systemd/user/surface5-frontcamera-brave-v4l2-bridge.service"
grep -Fq 'video_nr=20' "$root/config/modprobe/surface5-frontcamera-v4l2loopback.conf"
grep -Fq -- '--rollback' "$root/scripts/install-brave-v4l2loopback.sh"
grep -Fq -- '--rollback' "$root/scripts/install-brave-v4l2-camera.sh"
grep -Fq 'all project camera bridges were released' "$root/scripts/desktop-stop-surface5-hd-camera.sh"
grep -Fq 'exec sudo -- "$0" "$@"' "$root/scripts/install-brave-v4l2loopback.sh"
grep -Fq 'Preparing the native V4L2 loopback policy; sudo may request your password.' "$root/scripts/install-brave-v4l2-camera.sh"
grep -Fq -- '--user-data-dir' "$root/scripts/desktop-launch-brave-v4l2-camera.sh" && exit 1 || true
echo 'Brave V4L2 deployment static checks passed'
