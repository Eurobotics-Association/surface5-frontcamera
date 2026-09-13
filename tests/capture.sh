#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-only
# Capture and sanity-check a short libcamera front-camera sequence.
set -u -o pipefail

frames=8
width=1280
height=720
keep=0
camera=""
project_root=$(cd "$(dirname "$0")/.." && pwd)
stats_tool="$project_root/tools/nv12-stats.py"
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
[ -x "$stats_tool" ] || { echo "error: NV12 statistics tool is not executable: $stats_tool" >&2; exit 1; }

echo "Capturing $frames frames from camera $camera at requested ${width}x${height}"
set +e
timeout 45s cam --camera "$camera" --capture="$frames" --file="$work/" --stream="role=viewfinder,width=$width,height=$height,pixelformat=NV12" >"$work/cam-capture.txt" 2>&1
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
minimum_nv12_bytes=$((width * height * 3 / 2))
for frame in "${output_frames[@]}"; do
    frame_bytes=$(stat -c '%s' "$frame")
    if [ "$frame_bytes" -lt "$minimum_nv12_bytes" ]; then
        echo "error: truncated NV12 frame ($frame_bytes bytes; need at least $minimum_nv12_bytes): $frame" >&2
        keep=1
        exit 1
    fi
done
sha256sum "${output_frames[@]}" | tee "$work/hashes.txt"
unique=$(awk '{print $1}' "$work/hashes.txt" | sort -u | wc -l)
first_hash=$(awk 'NR == 1 { print $1 }' "$work/hashes.txt")
printf 'first_frame_sha256=%s\n' "$first_hash"
if [ "$unique" -lt 2 ] && [ "$frames" -gt 1 ]; then
    echo "error: every captured frame has the same SHA-256; probable frozen output; artifacts: $work" >&2
    keep=1
    exit 1
fi
if ! python3 "$stats_tool" --width "$width" --height "$height" "${output_frames[@]}" | tee "$work/nv12-stats.txt"; then
    echo "error: unable to calculate NV12 statistics; artifacts: $work" >&2
    keep=1
    exit 1
fi
suspicious=$(awk -F= '/^SUMMARY suspicious_black_or_uniform_frames=/ { split($2, value, "/"); print value[1] }' "$work/nv12-stats.txt")
exact_repeats=$(awk -F'\t' '$1 !~ /^#/ && $1 != "frame" && $10 == "yes" { count++ } END { print count + 0 }' "$work/nv12-stats.txt")
[ -n "$suspicious" ] || { echo "error: NV12 statistics did not provide a summary; artifacts: $work" >&2; keep=1; exit 1; }
if [ "$suspicious" -eq "$count" ]; then
    echo "error: every captured Y plane is black or nearly uniform; artifacts: $work" >&2
    keep=1
    exit 1
fi
if [ "$frames" -gt 1 ] && [ "$exact_repeats" -ge "$((count - 1))" ]; then
    echo "error: every successive Y plane is identical; probable frozen output; artifacts: $work" >&2
    keep=1
    exit 1
fi
if [ "$suspicious" -gt 0 ] || [ "$exact_repeats" -gt 0 ]; then
    echo "WARNING: NV12 statistics found $suspicious black/uniform frame(s) and $exact_repeats exact successive Y-plane repeat(s)." >&2
fi
echo "PASS: $count nonempty frames; $unique distinct hashes."
if [ "$keep" -eq 1 ]; then echo "Kept private artifacts in $work"; fi
