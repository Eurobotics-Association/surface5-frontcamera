#!/usr/bin/env bash
# Privileged helper: remove the external module file; reboot restores packaged state.
set -euo pipefail

kernel=$(uname -r)
destination="/lib/modules/$kernel/updates/dkms/dw9719.ko"

[ "$(id -u)" -eq 0 ] || { echo 'error: run via sudo after operator approval' >&2; exit 2; }
[ "$kernel" = '7.0.0-31-generic' ] || { echo "error: target is 7.0.0-31-generic, running $kernel" >&2; exit 2; }
[ -e "$destination" ] || { echo "error: no external module at $destination" >&2; exit 1; }

rm "$destination"
depmod -a "$kernel"
echo 'Removed external module file. Reboot to guarantee the packaged module is active again.'
