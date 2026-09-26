#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-only
# Launch the system Firefox in the managed, isolated PipeWire camera profile.
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
profile="${XDG_DATA_HOME:-$HOME/.local/share}/surface5-frontcamera/firefox-pipewire-profile"
[ "${1:-}" != '--help' ] || { echo "Usage: $0 [Firefox URL or arguments...]"; exit 0; }
[ -f "$profile/user.js" ] || { echo 'error: integration is not installed; run ./scripts/install-firefox-pipewire.sh first' >&2; exit 2; }
firefox=$(command -v firefox 2>/dev/null) || { echo 'error: system Firefox is required but was not found in PATH' >&2; exit 2; }
"$root/scripts/start-user-hd-camera-bridge.sh"
exec "$firefox" --no-remote --profile "$profile" "$@"
