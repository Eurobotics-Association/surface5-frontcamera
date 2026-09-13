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
    startup_hash=$(awk -F= '/^startup_frame_000001_sha256=/ { print $2; exit }' "$log")
    [ -n "$startup_hash" ] || { echo "FAIL: cycle $cycle did not report frame-000001 hash" >&2; exit 1; }
    printf '%s\t%s\n' "$cycle" "$startup_hash" >>"$work/startup-frame-hashes.tsv"
done
unique_startup=$(awk '{print $2}' "$work/startup-frame-hashes.tsv" | sort -u | wc -l)
known_startup_hash='9ee1d13fd6ed345f060ab756351293df8c9fedf100c25a4366a9c249bc9c95f6'
if [ "$unique_startup" -eq 1 ] && [ "$(awk 'NR == 1 { print $2 }' "$work/startup-frame-hashes.tsv")" = "$known_startup_hash" ]; then
    echo 'INFO: every cycle produced the known all-zero frame-000001 startup frame.' >&2
elif [ "$unique_startup" -lt "$cycles" ]; then
    echo 'WARNING: independent cycles share a frame-000001 hash other than the documented canonical black startup frame.' >&2
    sort -k2,2 "$work/startup-frame-hashes.tsv" | uniq -f1 -c >&2
fi
echo "PASS: all $cycles start/stop cycles completed."
