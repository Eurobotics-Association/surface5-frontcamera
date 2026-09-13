#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-only
# Exercise repeated fresh libcamera start/stop cycles without retaining frames.
set -u -o pipefail

cycles=5
frames=4
width=1280
height=720
usage() { echo 'Usage: restart-stream.sh [--cycles N] [--frames N] [--width W] [--height H]'; }
while (($#)); do
    case "$1" in
        --cycles) cycles="$2"; shift 2 ;;
        --frames) frames="$2"; shift 2 ;;
        --width) width="$2"; shift 2 ;;
        --height) height="$2"; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "error: unknown argument: $1" >&2; usage >&2; exit 2 ;;
    esac
done
[[ "$cycles" =~ ^[1-9][0-9]*$ ]] || { echo 'error: cycles must be positive' >&2; exit 2; }

work=$(mktemp -d "${TMPDIR:-/tmp}/surface-camera-restart.XXXXXX")
trap 'rm -rf "$work"' EXIT

for ((cycle = 1; cycle <= cycles; cycle++)); do
    echo "== start/stop cycle $cycle of $cycles =="
    log="$work/cycle-$cycle.txt"
    if ! "$(dirname "$0")/capture.sh" --frames "$frames" --width "$width" --height "$height" >"$log" 2>&1; then
        cat "$log"
        echo "FAIL: cycle $cycle failed" >&2
        exit 1
    fi
    cat "$log"
    first_hash=$(awk -F= '/^first_frame_sha256=/ { print $2; exit }' "$log")
    [ -n "$first_hash" ] || { echo "FAIL: cycle $cycle did not report a first-frame hash" >&2; exit 1; }
    printf '%s\t%s\n' "$cycle" "$first_hash" >>"$work/first-frame-hashes.tsv"
done
unique_first=$(awk '{print $2}' "$work/first-frame-hashes.tsv" | sort -u | wc -l)
if [ "$unique_first" -lt "$cycles" ]; then
    echo 'WARNING: one or more independent cycles share an identical first-frame hash.' >&2
    echo 'This can be an initialization/stale-frame symptom or a deterministic scene; inspect NV12 statistics and repeat while changing the scene.' >&2
    sort -k2,2 "$work/first-frame-hashes.tsv" | uniq -f1 -c >&2
fi
echo "PASS: all $cycles start/stop cycles completed."
