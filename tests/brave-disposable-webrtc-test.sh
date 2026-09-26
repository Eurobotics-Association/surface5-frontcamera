#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-only
# Static guard for the reversible Brave control harness.
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
target="$root/tests/brave-disposable-webrtc.sh"

bash -n "$target"
grep -Fq 'mktemp -d "${TMPDIR:-/tmp}/surface5-brave-webrtc.XXXXXX"' "$target"
grep -Fq 'rm -rf -- "$state_dir"' "$target"
grep -Fq 'surface5-brave-webrtc-control.env' "$target"
grep -Fq 'stop_detached_control' "$target"
grep -Fq 'stop_detached_control
    exit 0' "$target"
grep -Fq 'BRAVE_CONTROL=stopped; temporary profile removed and camera bridge released.' "$target"
grep -Fq -- '--user-data-dir=$profile' "$target"
grep -Fq 'WebRtcPipeWireCamera' "$target"
grep -Fq 'systemd-run --user --quiet --collect --service-type=exec' "$target"
grep -Fq 'start-user-hd-camera-bridge.sh' "$target"
grep -Fq 'BRAVE_CONTROL_RESULTS=' "$target"
printf 'brave disposable WebRTC harness static checks passed\n'
