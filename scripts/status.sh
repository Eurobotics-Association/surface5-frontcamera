#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-only
# Report native DW9719 fix state without treating a local override as native.
set -euo pipefail

usage() { echo 'Usage: status.sh [kernel-release]'; }
kernel="${1:-$(uname -r)}"
[ "$#" -le 1 ] || { usage >&2; exit 2; }
module_root="/lib/modules/$kernel"
native_dir="$module_root/kernel/drivers/media/i2c"
override="$module_root/updates/dkms/dw9719.ko"

[ -d "$module_root" ] || { echo "error: kernel modules are unavailable: $module_root" >&2; exit 2; }
native=$(find "$native_dir" -maxdepth 1 -type f -name 'dw9719.ko*' -print -quit 2>/dev/null || true)
[ -n "$native" ] || { echo "error: native packaged dw9719 module not found under $native_dir" >&2; exit 2; }

has_i2c_alias() {
    modinfo "$1" 2>/dev/null | grep -qE '^alias:[[:space:]]+i2c:dw9719$'
}

printf 'kernel=%s\n' "$kernel"
printf 'native_module=%s\n' "$native"
printf 'native_vermagic=%s\n' "$(modinfo -F vermagic "$native" 2>/dev/null || true)"
if [ -f "$override" ]; then
    printf 'override_module=%s\n' "$override"
    printf 'override_vermagic=%s\n' "$(modinfo -F vermagic "$override" 2>/dev/null || true)"
    if has_i2c_alias "$override"; then
        echo 'override_i2c_dw9719_alias=yes'
    else
        echo 'override_i2c_dw9719_alias=no'
    fi
else
    echo 'override_module=absent'
fi

if has_i2c_alias "$native"; then
    echo 'NATIVE_FIX_PRESENT'
    if [ -f "$override" ]; then
        echo 'ACTION: native module is fixed; remove the obsolete per-kernel override with sudo ./scripts/uninstall.sh' >&2
    fi
    exit 0
fi

echo 'NATIVE_FIX_MISSING'
echo 'ACTION: this kernel may need the reviewed workaround; run the installer only after its source/API guard accepts this kernel.' >&2
exit 10
