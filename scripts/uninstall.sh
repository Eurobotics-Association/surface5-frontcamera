#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-only
# Remove only the per-kernel DW9719 override; never remove a packaged module.
set -euo pipefail

usage() { echo 'Usage: sudo uninstall.sh [kernel-release]'; }
kernel="${1:-$(uname -r)}"
[ "$#" -le 1 ] || { usage >&2; exit 2; }
[ "$(id -u)" -eq 0 ] || { echo 'error: run via sudo; this command removes a local override' >&2; exit 2; }
destination="/lib/modules/$kernel/updates/dkms/dw9719.ko"
[ -f "$destination" ] || { echo "error: no local DW9719 override at $destination" >&2; exit 1; }

rm "$destination"
depmod -a "$kernel"
echo "WORKAROUND_REMOVED: $destination"
echo 'Reboot, or unload the module only after confirming no camera consumer is active, to guarantee the packaged module is in use.'
