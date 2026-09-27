#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-only
# Release every project-owned Surface5 front-camera bridge; browsers stay open.
set -euo pipefail

systemctl --user stop surface5-frontcamera-hd-bridge.service 2>/dev/null || true
systemctl --user stop surface5-frontcamera-brave-v4l2-bridge.service 2>/dev/null || true
echo 'SURFACE5_HD_CAMERA=stopped; all project camera bridges were released.'
