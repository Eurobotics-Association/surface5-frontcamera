#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-only
# Run host-only front-camera validation; never changes kernel or module state.
set -u -o pipefail

project_root=$(cd "$(dirname "$0")/.." && pwd)
if [ "${1:-}" = '-h' ] || [ "${1:-}" = '--help' ]; then
    echo 'Usage: host-validation.sh'
    echo 'Run only from the normal Zorin desktop host session; it writes private results below ~/Pictures.'
    exit 0
fi
[ "$#" -eq 0 ] || { echo 'error: host-validation.sh accepts no arguments' >&2; exit 2; }
timestamp=$(date -u +%Y%m%dT%H%M%SZ)
result_root="${HOME}/Pictures/surface5-frontcamera-tests/${timestamp}"
umask 077
mkdir -p "$result_root" || { echo "error: cannot create private host result directory: $result_root" >&2; exit 2; }
summary="$result_root/summary.txt"
failures=0

cam -l >"$result_root/cam-list-before-validation.txt" 2>&1 || true
front_id=$(sed -n '/Internal front camera/ { s/.*(\(.*\)).*/\1/p; q; }' "$result_root/cam-list-before-validation.txt")
[ -n "$front_id" ] || { echo 'error: could not parse the exact Internal front camera ID from cam -l' >&2; cat "$result_root/cam-list-before-validation.txt" >&2; exit 1; }

note() { printf '%s\n' "$*" | tee -a "$summary"; }
run_step() {
    local name=$1; shift
    local log="$result_root/${name}.log"
    note "== $name =="
    set +e; "$@" >"$log" 2>&1; local status=$?; set -e
    cat "$log" | tee -a "$summary"
    if [ "$status" -eq 0 ]; then note "RESULT $name: PASS"
    else note "RESULT $name: FAIL (exit $status)"; failures=$((failures + 1)); fi
}

{
    echo "timestamp_utc=$timestamp"
    echo "kernel=$(uname -r)"
    . /etc/os-release 2>/dev/null || true
    echo "os=${PRETTY_NAME:-unknown}"
    echo "front_camera_id=$front_id"
    echo "git_commit=$(git -C "$project_root" rev-parse HEAD)"
    echo "dw9719_module=$(modinfo -n dw9719 2>/dev/null || true)"
    "$project_root/scripts/status.sh" || status=$?
    [ "${status:-0}" -eq 10 ] || true
} >"$result_root/environment.txt" 2>&1
cat "$result_root/environment.txt" | tee "$summary"

note "Privacy: this directory contains personal camera images and raw frames. It is outside Git and must not be shared accidentally."
run_step enumeration "$project_root/tests/enumeration.sh"
run_step capture "$project_root/tests/capture.sh" --frames 16 --width 1280 --height 720 --output "$result_root/raw-capture" --visual-output "$result_root"
run_step restart-stream "$project_root/tests/restart-stream.sh" --cycles 5 --frames 8 --width 1280 --height 720

run_front_gstreamer() {
    local log="$result_root/gstreamer-front.log"
    note '== gstreamer-front =='
    printf 'camera-name=%s\n' "$front_id" >"$log"
    set +e
    GST_DEBUG=libcamerasrc:4 gst-launch-1.0 -e libcamerasrc camera-name="$front_id" ! video/x-raw,format=NV12,width=1280,height=720 ! identity eos-after=30 ! fakesink sync=false >>"$log" 2>&1
    local status=$?
    set -e
    cat "$log" | tee -a "$summary"
    if [ "$status" -eq 0 ]; then note 'RESULT gstreamer-front: PASS'
    else note "RESULT gstreamer-front: FAIL (exit $status)"; failures=$((failures + 1)); fi
}
run_front_gstreamer

run_front_gstreamer_jpegs() {
    local log="$result_root/gstreamer-front-jpegs.log"
    note '== gstreamer-front-jpegs =='
    printf 'camera-name=%s\n' "$front_id" >"$log"
    set +e
    GST_DEBUG=libcamerasrc:4 gst-launch-1.0 -e libcamerasrc camera-name="$front_id" ! video/x-raw,format=NV12,width=1280,height=720 ! identity eos-after=3 ! jpegenc quality=90 ! multifilesink location="$result_root/gstreamer-front-%02d.jpg" next-file=buffer >>"$log" 2>&1
    local status=$?
    set -e
    cat "$log" | tee -a "$summary"
    local jpeg_count; jpeg_count=$(find "$result_root" -maxdepth 1 -type f -name 'gstreamer-front-*.jpg' -size +0c | wc -l)
    if [ "$status" -eq 0 ] && [ "$jpeg_count" -ge 1 ]; then note "RESULT gstreamer-front-jpegs: PASS ($jpeg_count JPEGs)"
    else note "RESULT gstreamer-front-jpegs: FAIL (exit $status, JPEGs $jpeg_count)"; failures=$((failures + 1)); fi
}
run_front_gstreamer_jpegs

run_pipewire_report() {
    local log="$result_root/pipewire-portal.log"
    note '== pipewire-portal =='
    {
        echo '== installed packages =='
        dpkg-query -W -f='${binary:Package}\t${Version}\t${db:Status-Abbrev}\n' pipewire pipewire-libcamera wireplumber xdg-desktop-portal 2>&1 || true
        echo '== user services =='
        systemctl --user --no-pager --plain is-active pipewire wireplumber xdg-desktop-portal 2>&1 || true
        echo '== portal interfaces =='
        gdbus introspect --session --dest org.freedesktop.portal.Desktop --object-path /org/freedesktop/portal/desktop 2>&1 || true
        echo '== PipeWire nodes =='
        if pw-dump >"$result_root/pw-dump.json" 2>&1; then python3 "$project_root/tools/pipewire-camera-report.py" "$result_root/pw-dump.json"; else cat "$result_root/pw-dump.json"; fi
    } >"$log" 2>&1
    cat "$log" | tee -a "$summary"
    note 'RESULT pipewire-portal: INFO (inspect the Video/* node report and portal interfaces; absence of a matching name is not alone a capture failure)'
}
run_pipewire_report

note '== FINAL SUMMARY =='
note "VISUAL RESULTS:"
note "$result_root"
note "Open with: xdg-open \"$result_root\""
note "Logs, raw frames, hashes, NV12 statistics, and JPEGs are private and were not written to the repository."
if [ "$failures" -eq 0 ]; then note 'HOST VALIDATION: PASS'; exit 0; fi
note "HOST VALIDATION: FAIL ($failures required layer(s)); inspect the retained logs above."
exit 1
