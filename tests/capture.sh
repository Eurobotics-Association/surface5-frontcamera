#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-only
# Capture and sanity-check a short libcamera front-camera sequence.
set -u -o pipefail

frames=8 width=1280 height=720 keep=0 camera="" output="" visual_output=""
project_root=$(cd "$(dirname "$0")/.." && pwd)
stats_tool="$project_root/tools/nv12-stats.py"
usage() { echo 'Usage: capture.sh [--camera INDEX] [--frames N] [--width W] [--height H] [--keep] [--output DIRECTORY] [--visual-output DIRECTORY]'; }
while (($#)); do
    case "$1" in
        --camera) camera="$2"; shift 2 ;; --frames) frames="$2"; shift 2 ;;
        --width) width="$2"; shift 2 ;; --height) height="$2"; shift 2 ;;
        --keep) keep=1; shift ;; --output) output="$2"; shift 2 ;;
        --visual-output) visual_output="$2"; shift 2 ;;
        -h|--help) usage; exit 0 ;; *) echo "error: unknown argument: $1" >&2; usage >&2; exit 2 ;;
    esac
done
[[ "$frames" =~ ^[1-9][0-9]*$ && "$width" =~ ^[1-9][0-9]*$ && "$height" =~ ^[1-9][0-9]*$ ]] || { echo 'error: dimensions and frames must be positive integers' >&2; exit 2; }

if [ -n "$output" ]; then
    [ ! -e "$output" ] || [ -d "$output" ] || { echo "error: output is not a directory: $output" >&2; exit 2; }
    mkdir -p "$output"
    [ -z "$(find "$output" -mindepth 1 -maxdepth 1 -print -quit)" ] || { echo "error: output directory must be empty: $output" >&2; exit 2; }
    work="$output"; keep=1
else
    work=$(mktemp -d "${TMPDIR:-/tmp}/surface-camera-capture.XXXXXX")
fi
if [ -n "$visual_output" ]; then
    mkdir -p "$visual_output"
    command -v gst-launch-1.0 >/dev/null || { echo 'error: visual output needs GStreamer; gst-launch-1.0 is missing' >&2; exit 2; }
    gst-inspect-1.0 rawvideoparse >/dev/null 2>&1 && gst-inspect-1.0 jpegenc >/dev/null 2>&1 || { echo 'error: visual output needs GStreamer rawvideoparse and jpegenc plugins' >&2; exit 2; }
    if command -v ffmpeg >/dev/null; then jpeg_converter=ffmpeg
    else jpeg_converter=gstreamer; echo 'INFO: ffmpeg is unavailable; using GStreamer rawvideoparse + jpegenc for JPEG conversion.' >&2; fi
fi
cleanup() { [ "$keep" -eq 1 ] || rm -rf "$work"; }
trap cleanup EXIT

listing="$work/cam-list.txt"
cam -l >"$listing" 2>&1 || { cat "$listing"; echo 'error: libcamera enumeration failed' >&2; exit 1; }
cat "$listing"
if [ -z "$camera" ]; then camera=$(awk '/^[[:space:]]*[0-9]+:.*[Ff]ront camera/ {sub(/:.*/, "", $1); print $1; exit}' "$listing"); fi
[ -n "$camera" ] || { echo 'error: unable to identify a front camera; pass --camera INDEX' >&2; exit 1; }
[ -x "$stats_tool" ] || { echo "error: NV12 statistics tool is not executable: $stats_tool" >&2; exit 1; }

echo "Capturing $frames frames from camera $camera at requested ${width}x${height} NV12"
set +e
timeout 45s cam --camera "$camera" --capture="$frames" --file="$work/" --stream="role=viewfinder,width=$width,height=$height,pixelformat=NV12" >"$work/cam-capture.txt" 2>&1
status=$?
set -e
cat "$work/cam-capture.txt"
[ "$status" -eq 0 ] || { echo "error: cam capture exited $status; artifacts: $work" >&2; keep=1; exit 1; }

mapfile -t output_frames < <(find "$work" -maxdepth 1 -type f -name 'frame-*' -size +0c | sort)
count=${#output_frames[@]}
[ "$count" -ge "$frames" ] || { echo "error: only $count nonempty frame files, expected at least $frames; artifacts: $work" >&2; keep=1; exit 1; }
expected_nv12_bytes=$((width * height * 3 / 2))
for frame in "${output_frames[@]}"; do
    frame_bytes=$(stat -c '%s' "$frame")
    [ "$frame_bytes" -eq "$expected_nv12_bytes" ] || { echo "error: unexpected raw-frame size ($frame_bytes bytes; expected tightly packed ${width}x${height} NV12 = $expected_nv12_bytes): $frame" >&2; keep=1; exit 1; }
done
printf 'requested_stream=role=viewfinder,width=%s,height=%s,pixelformat=NV12\nvalidated_raw_frame_bytes=%s\nconversion_format=NV12\nconversion_size=%sx%s\n' "$width" "$height" "$expected_nv12_bytes" "$width" "$height" >"$work/capture-format.txt"

sha256sum "${output_frames[@]}" | tee "$work/hashes.txt"
unique=$(awk '{print $1}' "$work/hashes.txt" | sort -u | wc -l)
first_hash=$(awk 'NR == 1 { print $1 }' "$work/hashes.txt")
startup_hash=$(while read -r hash path; do
    name=${path##*/}; sequence=${name##*-}; sequence=${sequence%%.*}
    [ "$sequence" = '000001' ] && { printf '%s\n' "$hash"; break; }
done <"$work/hashes.txt")
printf 'first_frame_sha256=%s\n' "$first_hash"
[ -z "$startup_hash" ] || printf 'startup_frame_000001_sha256=%s\n' "$startup_hash"
[ "$unique" -ge 2 ] || [ "$frames" -eq 1 ] || { echo "error: every captured frame has the same SHA-256; probable frozen output; artifacts: $work" >&2; keep=1; exit 1; }
if ! python3 "$stats_tool" --width "$width" --height "$height" "${output_frames[@]}" | tee "$work/nv12-stats.txt"; then echo "error: unable to calculate NV12 statistics; artifacts: $work" >&2; keep=1; exit 1; fi
suspicious=$(awk -F= '/^SUMMARY suspicious_black_or_uniform_frames=/ { split($2, value, "/"); print value[1] }' "$work/nv12-stats.txt")
startup_black=$(awk -F= '/^SUMMARY canonical_startup_black_frames=/ { split($2, value, "/"); print value[1] }' "$work/nv12-stats.txt")
exact_repeats=$(awk -F'\t' '$1 !~ /^#/ && $1 != "frame" && $11 == "yes" { count++ } END { print count + 0 }' "$work/nv12-stats.txt")
[ -n "$suspicious" ] && [ -n "$startup_black" ] || { echo "error: NV12 statistics did not provide required summaries; artifacts: $work" >&2; keep=1; exit 1; }

if [ -n "$visual_output" ]; then
    printf 'source_frame\tjpeg\n' >"$visual_output/visual-manifest.tsv"
    declare -A selected=()
    for index in 0 1 2 $((count / 2)) $((count - 1)); do
        [ "$index" -lt "$count" ] || continue; [ -z "${selected[$index]:-}" ] || continue; selected[$index]=1
        frame="${output_frames[$index]}"; stem=$(basename "$frame"); stem=${stem%.*}; jpeg="$visual_output/$stem.jpg"
        sequence=${stem##*-}; [ "$sequence" != '000001' ] || jpeg="$visual_output/$stem-BLACK-STARTUP.jpg"
        [ ! -e "$jpeg" ] || { echo "error: refusing to overwrite visual result: $jpeg" >&2; keep=1; exit 1; }
        if [ "$jpeg_converter" = ffmpeg ]; then
            ffmpeg -hide_banner -loglevel error -f rawvideo -pixel_format nv12 -video_size "${width}x${height}" -i "$frame" -frames:v 1 -q:v 2 "$jpeg"
        else
            gst-launch-1.0 -q filesrc location="$frame" ! rawvideoparse format=nv12 width="$width" height="$height" framerate=1/1 ! jpegenc quality=90 ! filesink location="$jpeg"
        fi
        [ -s "$jpeg" ] || { echo "error: JPEG conversion produced no file: $jpeg" >&2; keep=1; exit 1; }
        printf '%s\t%s\n' "$(basename "$frame")" "$(basename "$jpeg")" >>"$visual_output/visual-manifest.tsv"
    done
    printf 'VISUAL RESULTS:\n%s\nOpen with: xdg-open "%s"\n' "$visual_output" "$visual_output"
fi

[ "$suspicious" -lt "$count" ] || { echo "error: every captured Y plane is black or nearly uniform; artifacts: $work" >&2; keep=1; exit 1; }
if [ "$frames" -gt 1 ] && [ "$exact_repeats" -ge "$((count - 1))" ]; then echo "error: every successive Y plane is identical; probable frozen output; artifacts: $work" >&2; keep=1; exit 1; fi
[ "$startup_black" -eq 0 ] || echo "INFO: observed $startup_black canonical frame-000001 black startup frame(s); not classified as a frozen stream." >&2
if [ "$suspicious" -gt "$startup_black" ] || [ "$exact_repeats" -gt 0 ]; then echo "WARNING: NV12 statistics found $((suspicious - startup_black)) unexpected black/uniform frame(s) and $exact_repeats exact successive Y-plane repeat(s)." >&2; fi
echo "PASS: $count size-validated NV12 frames; $unique distinct whole-frame hashes."
[ "$keep" -eq 0 ] || echo "Kept private artifacts in $work"
