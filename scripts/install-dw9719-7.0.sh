#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-only
# Privileged helper: install an already inspected DW9719 module, but do not load it.
set -euo pipefail

module="${1:?usage: sudo install-dw9719-7.0.sh /absolute/path/to/dw9719.ko}"
kernel=$(uname -r)
destination="/lib/modules/$kernel/updates/dkms/dw9719.ko"
stock_module=$(find "/lib/modules/$kernel/kernel/drivers/media/i2c" -maxdepth 1 -type f -name 'dw9719.ko*' -print -quit 2>/dev/null || true)

normalized_vermagic() {
    # modinfo may leave insignificant spaces before its terminating newline.
    # Do not normalize anything except trailing whitespace.
    modinfo -F vermagic "$1" 2>/dev/null | sed 's/[[:space:]]*$//'
}

[ "$(id -u)" -eq 0 ] || { echo 'error: run via sudo after operator approval' >&2; exit 2; }
[ "$kernel" = '7.0.0-31-generic' ] || { echo "error: target is 7.0.0-31-generic, running $kernel" >&2; exit 2; }
[ -f "$module" ] || { echo "error: module not found: $module" >&2; exit 2; }
[ -n "$stock_module" ] || { echo "error: packaged stock dw9719 module not found for $kernel" >&2; exit 1; }
[ -f "$stock_module" ] || { echo "error: packaged stock dw9719 module is not a regular file: $stock_module" >&2; exit 1; }
modinfo "$module" | grep -q '^alias:[[:space:]]*i2c:dw9719$' || {
    echo 'error: refusing a module without i2c:dw9719' >&2
    exit 1
}

patched_vermagic=$(normalized_vermagic "$module")
stock_vermagic=$(normalized_vermagic "$stock_module")
[ -n "$patched_vermagic" ] || { echo "error: unable to read patched module vermagic: $module" >&2; exit 1; }
[ -n "$stock_vermagic" ] || { echo "error: unable to read packaged stock module vermagic: $stock_module" >&2; exit 1; }
if [ "$patched_vermagic" != "$stock_vermagic" ]; then
    echo 'error: patched and packaged stock vermagic differ after trailing-whitespace normalization' >&2
    printf 'patched=<%s>\nstock=<%s>\n' "$patched_vermagic" "$stock_vermagic" >&2
    exit 1
fi

install -D -m 0644 "$module" "$destination"
depmod -a "$kernel"
echo "Verified packaged stock module: $stock_module"
echo "Verified normalized vermagic: <$patched_vermagic>"
echo "Installed but did not load: $destination"
echo 'Next, with no camera consumer active: sudo modprobe dw9719'
