#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-only
set -euo pipefail
systemctl --user stop surface5-frontcamera-brave-v4l2-bridge.service
echo 'BRAVE_V4L2_BRIDGE=stopped; the physical camera source was released.'
