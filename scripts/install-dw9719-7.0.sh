#!/usr/bin/env bash
# Privileged helper: install an already inspected DW9719 module, but do not load it.
set -euo pipefail

module="${1:?usage: sudo install-dw9719-7.0.sh /absolute/path/to/dw9719.ko}"
kernel=$(uname -r)
destination="/lib/modules/$kernel/updates/dkms/dw9719.ko"

[ "$(id -u)" -eq 0 ] || { echo 'error: run via sudo after operator approval' >&2; exit 2; }
[ "$kernel" = '7.0.0-31-generic' ] || { echo "error: target is 7.0.0-31-generic, running $kernel" >&2; exit 2; }
[ -f "$module" ] || { echo "error: module not found: $module" >&2; exit 2; }
modinfo "$module" | grep -q '^alias:[[:space:]]*i2c:dw9719$' || {
    echo 'error: refusing a module without i2c:dw9719' >&2
    exit 1
}
modinfo -F vermagic "$module" | grep -qx "$kernel SMP preempt mod_unload modversions" || {
    echo 'error: vermagic does not match the running kernel' >&2
    exit 1
}

install -D -m 0644 "$module" "$destination"
depmod -a "$kernel"
echo "Installed but did not load: $destination"
echo 'Next, with no camera consumer active: sudo modprobe dw9719'
