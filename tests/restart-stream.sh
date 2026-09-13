#!/usr/bin/env bash
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

for ((cycle = 1; cycle <= cycles; cycle++)); do
    echo "== start/stop cycle $cycle of $cycles =="
    if ! "$(dirname "$0")/capture.sh" --frames "$frames" --width "$width" --height "$height"; then
        echo "FAIL: cycle $cycle failed" >&2
        exit 1
    fi
done
echo "PASS: all $cycles start/stop cycles completed."
