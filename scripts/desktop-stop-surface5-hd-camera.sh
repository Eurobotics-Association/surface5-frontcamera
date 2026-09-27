#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-only
# Release every project-owned Surface5 front-camera bridge; browsers stay open.
set -euo pipefail

systemctl --user stop surface5-frontcamera-v4l2-bridge.service 2>/dev/null || true
echo 'SURFACE5_HD_CAMERA=stopped; the project V4L2 bridge was released.'
