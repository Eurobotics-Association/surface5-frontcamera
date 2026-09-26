#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-only
set -euo pipefail

data_home="${XDG_DATA_HOME:-$HOME/.local/share}"
state_dir="$data_home/surface5-frontcamera"
applications="$data_home/applications"
desktop_dir=$(xdg-user-dir DESKTOP 2>/dev/null || printf '%s/Desktop' "$HOME")
unit=surface5-frontcamera-brave-v4l2-bridge.service
systemctl --user disable --now "$unit" 2>/dev/null || true
rm -f "${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user/$unit" "$state_dir/bin/brave-surface5-hd-camera" "$state_dir/bin/stop-brave-surface5-hd-camera" "$applications/surface5-brave-v4l2-camera.desktop" "$applications/surface5-stop-brave-v4l2-camera.desktop" "$desktop_dir/Brave — Surface5 HD Front Camera.desktop" "$desktop_dir/Stop Brave Surface5 HD Front Camera.desktop" "$state_dir/brave-v4l2-deployment.env"
systemctl --user daemon-reload
rmdir "$state_dir/bin" "$state_dir" 2>/dev/null || true
echo 'Removed the user-level Brave V4L2 bridge and launchers. Run the root rollback separately to remove the native loopback policy.'
