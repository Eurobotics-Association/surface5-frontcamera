#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-only
# Check that the kernel graph and libcamera enumerate the SP5 front camera.
set -u -o pipefail

work="${TMPDIR:-/tmp}/surface-camera-enumeration-$(date -u +%Y%m%dT%H%M%SZ)"
mkdir -p "$work"
log="$work/cam-list.txt"
fail=0

note() { printf '%s\n' "$*"; }

note "Diagnostics directory: $work"
note "Kernel: $(uname -r)"
if compgen -G '/dev/media*' >/dev/null; then note 'PASS: media device node exists'; else note 'FAIL: no /dev/media* node'; fail=1; fi
if [ -L /sys/bus/i2c/devices/i2c-INT33BE:00/driver ]; then note 'PASS: OV5693 is bound'; else note 'FAIL: OV5693 is not bound'; fail=1; fi
if [ -L /sys/bus/pci/devices/0000:00:14.3/driver ]; then note 'PASS: IPU3 CIO2 is bound'; else note 'FAIL: IPU3 CIO2 is not bound'; fail=1; fi
if [ -L /sys/bus/i2c/devices/i2c-INT347A:00-VCM/driver ]; then note 'PASS: DW9719 VCM is bound'; else note 'FAIL: DW9719 VCM is unbound'; fail=1; fi

cam -l >"$log" 2>&1
cam_status=$?
cat "$log"
if [ "$cam_status" -ne 0 ]; then
    note "FAIL: cam -l exited $cam_status"
    fail=1
elif grep -qiE 'Internal front camera|front camera' "$log"; then
    note 'PASS: libcamera lists a front camera'
else
    note 'FAIL: libcamera does not list a front camera'
    fail=1
fi

if [ "$fail" -ne 0 ]; then
    note "Enumeration failed; see $log"
    exit 1
fi
note 'Enumeration passed.'
