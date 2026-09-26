#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-only
# Serve the deterministic, local-only WebRTC diagnostic in a host desktop session.
set -euo pipefail

project_root=$(cd "$(dirname "$0")/.." && pwd)
timestamp=$(date -u +%Y%m%dT%H%M%SZ)
result_root="${HOME}/Pictures/surface5-frontcamera-tests/${timestamp}-webrtc-browser"
server_stdout="${result_root}/server.stdout"
server_stderr="${result_root}/server.stderr"
umask 077
mkdir -p "$result_root"

server_pid=''
cleanup() {
    if [ -n "$server_pid" ] && kill -0 "$server_pid" 2>/dev/null; then
        kill "$server_pid" 2>/dev/null || true
        wait "$server_pid" 2>/dev/null || true
    fi
}
trap cleanup EXIT INT TERM

python3 "$project_root/tests/browser-webrtc-server.py" \
    --root "$project_root/tests" --output "$result_root" >"$server_stdout" 2>"$server_stderr" &
server_pid=$!
for _ in $(seq 1 50); do
    if [ -s "$server_stdout" ]; then break; fi
    if ! kill -0 "$server_pid" 2>/dev/null; then
        cat "$server_stderr" >&2 || true
        exit 1
    fi
    sleep 0.1
done
url=$(sed -n 's/^LISTENING //p' "$server_stdout" | head -n 1)
[ -n "$url" ] || { echo "error: local server did not publish a URL" >&2; exit 1; }

printf 'WebRTC diagnostic URL: %s\n' "$url"
printf 'Private textual results: %s\n' "$result_root"
printf 'Open the URL in one browser at a time, grant its camera prompt, and leave this helper running. Press Ctrl-C when finished; the localhost server is then stopped.\n'
wait "$server_pid"
