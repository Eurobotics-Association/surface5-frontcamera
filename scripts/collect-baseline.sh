#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-only
# Collect a sanitised, non-privileged snapshot of the Surface camera stack.
set -u -o pipefail

usage() {
    cat <<'EOF'
Usage: collect-baseline.sh [--output DIRECTORY]

Writes a timestamped report. No sudo is used and no system state is changed.
EOF
}

out_root="${TMPDIR:-/tmp}"
while (($#)); do
    case "$1" in
        --output) out_root="$2"; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "error: unknown argument: $1" >&2; usage >&2; exit 2 ;;
    esac
done

mkdir -p "$out_root"
report_dir="$out_root/surface-camera-baseline-$(date -u +%Y%m%dT%H%M%SZ)"
mkdir -p "$report_dir" || exit 1
report="$report_dir/report.txt"

run() {
    printf '\n===== %s =====\n' "$1" >>"$report"
    shift
    "$@" >>"$report" 2>&1 || printf '[command exited %s]\n' "$?" >>"$report"
}

{
    printf 'Generated UTC: '; date -u +%FT%TZ
    printf 'Script: %s\n' "$0"
} >"$report"

run 'kernel' uname -a
run 'operating system' cat /etc/os-release
{
    printf '\n===== DMI (serial deliberately redacted) =====\n'
    for item in sys_vendor product_name product_sku product_family board_name board_vendor; do
        printf '%s=' "$item"
        cat "/sys/class/dmi/id/$item" 2>/dev/null || true
    done
} >>"$report"
run 'CPU' lscpu
run 'PCI IPU3 function' lspci -nnk -d 8086:9d32
run 'module list' bash -c "lsmod | grep -iE 'ipu|cio2|imgu|ov5693|ov8865|ov7251|dw9719|int3472|v4l|videodev|mc' || true"
run 'module aliases' bash -c 'for m in ipu3_cio2 ipu3_imgu ov5693 dw9719; do echo "[$m]"; modinfo "$m" 2>&1 | grep -E "^(filename|firmware|alias|version|srcversion):" || true; done'
run 'device nodes' bash -c 'ls -l /dev/media* /dev/video* /dev/v4l-subdev* 2>&1 || true'
run 'V4L2 device listing' v4l2-ctl --list-devices
run 'libcamera enumeration' cam -l
run 'media topology' bash -c 'shopt -s nullglob; devices=(/dev/media*); ((${#devices[@]})) || { echo "no media devices"; exit 1; }; for d in "${devices[@]}"; do echo "[$d]"; media-ctl -d "$d" -p; done'
run 'relevant I2C devices' bash -c 'for d in /sys/bus/i2c/devices/*; do [ -r "$d/name" ] || continue; n=$(cat "$d/name" 2>/dev/null); case "${d##*/}:$n" in *INT33BE*|*INT347A*|*INT347E*|*ov5693*|*ov8865*|*ov7251*|*dw9719*) printf "%s name=%s modalias=" "${d##*/}" "$n"; cat "$d/modalias" 2>/dev/null || true; if [ -L "$d/driver" ]; then printf "driver="; basename "$(readlink -f "$d/driver")"; else echo "driver=<unbound>"; fi;; esac; done'
run 'relevant packages' bash -c "dpkg-query -W -f='\${binary:Package}\t\${Version}\t\${Status}\n' 2>/dev/null | grep -iE 'linux-(image|modules|headers|surface)|libcamera|pipewire|wireplumber|v4l|media' | sort || true"
run 'libcamera package version' dpkg-query -W -f='${Version}\n' libcamera0.2
run 'PipeWire version' pw-cli --version
run 'kernel journal access check' journalctl -b -k --no-pager -n 120

printf 'Report written to %s\n' "$report"
