#!/usr/bin/env bash
# Capture and sanity-check a short libcamera front-camera sequence.
set -u -o pipefail

frames=8
width=1280
height=720
keep=0
camera=""
usage() { echo 'Usage: capture.sh [--camera INDEX] [--frames N] [--width W] [--height H] [--keep]'; }
while (($#)); do
    case "$1" in
        --camera) camera="$2"; shift 2 ;;
        --frames) frames="$2"; shift 2 ;;
        --width) width="$2"; shift 2 ;;
        --height) height="$2"; shift 2 ;;
        --keep) keep=1; shift ;;
        -h|--help) usage; exit 0 ;;
        *) echo "error: unknown argument: $1" >&2; usage >&2; exit 2 ;;
    esac
done
[[ "$frames" =~ ^[1-9][0-9]*$ && "$width" =~ ^[1-9][0-9]*$ && "$height" =~ ^[1-9][0-9]*$ ]] || { echo 'error: dimensions and frames must be positive integers' >&2; exit 2; }

work=$(mktemp -d "${TMPDIR:-/tmp}/surface-camera-capture.XXXXXX")
cleanup() { [ "$keep" -eq 1 ] || rm -rf "$work"; }
trap cleanup EXIT
listing="$work/cam-list.txt"
cam -l >"$listing" 2>&1 || { cat "$listing"; echo 'error: libcamera enumeration failed' >&2; exit 1; }
cat "$listing"
if [ -z "$camera" ]; then
    camera=$(awk '/^[[:space:]]*[0-9]+:.*[Ff]ront camera/ {sub(/:.*/, "", $1); print $1; exit}' "$listing")
fi
[ -n "$camera" ] || { echo 'error: unable to identify a front camera; pass --camera INDEX' >&2; exit 1; }

echo "Capturing $frames frames from camera $camera at requested ${width}x${height}"
set +e
timeout 45s cam --camera "$camera" --capture="$frames" --file="$work/" --stream="role=viewfinder,width=$width,height=$height" >"$work/cam-capture.txt" 2>&1
status=$?
set -e
cat "$work/cam-capture.txt"
[ "$status" -eq 0 ] || { echo "error: cam capture exited $status; artifacts: $work" >&2; keep=1; exit 1; }

mapfile -t output_frames < <(find "$work" -maxdepth 1 -type f -name 'frame-*' -size +0c | sort)
count=${#output_frames[@]}
if [ "$count" -lt "$frames" ]; then
    echo "error: only $count nonempty frame files, expected at least $frames; artifacts: $work" >&2
    keep=1
    exit 1
fi
sha256sum "${output_frames[@]}" | tee "$work/hashes.txt"
unique=$(awk '{print $1}' "$work/hashes.txt" | sort -u | wc -l)
if [ "$unique" -lt 2 ] && [ "$frames" -gt 1 ]; then
    echo "error: every captured frame has the same SHA-256; probable frozen output; artifacts: $work" >&2
    keep=1
    exit 1
fi
echo "PASS: $count nonempty frames; $unique distinct hashes."
if [ "$keep" -eq 1 ]; then echo "Kept private artifacts in $work"; fi
