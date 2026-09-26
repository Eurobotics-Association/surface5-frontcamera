#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-only
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
. "$root/config/brave-v4l2-deployment-version.env"
data_home="${XDG_DATA_HOME:-$HOME/.local/share}"
echo "DEPLOYMENT_EXPECTED=$DEPLOYMENT_PRODUCT $DEPLOYMENT_VERSION"
grep -E '^DEPLOYMENT_(PRODUCT|VERSION)=' "$data_home/surface5-frontcamera/brave-v4l2-deployment.env" 2>/dev/null || true
brave=$(command -v brave-browser-stable 2>/dev/null || command -v brave-browser 2>/dev/null || true)
[ -n "$brave" ] && { echo "BRAVE=$brave"; "$brave" --version; } || echo 'BRAVE=missing'
v4l2-ctl --device=/dev/video20 --all 2>&1 | grep -E 'Card type|Video (Capture|Output)|Width/Height|Frames per second' || true
systemctl --user --no-pager --full status surface5-frontcamera-brave-v4l2-bridge.service 2>&1 || true
