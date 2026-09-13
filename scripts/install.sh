#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-only
# Build/install a workaround only when the active kernel's native module lacks it.
set -euo pipefail

usage() { echo 'Usage: sudo install.sh [kernel-release]'; }
project_root=$(cd "$(dirname "$0")/.." && pwd)
kernel="${1:-$(uname -r)}"
[ "$#" -le 1 ] || { usage >&2; exit 2; }
[ "$(id -u)" -eq 0 ] || { echo 'error: run via sudo; this command installs a kernel module' >&2; exit 2; }
[ "$kernel" = "$(uname -r)" ] || { echo "error: boot $kernel before installing an override for it" >&2; exit 2; }

set +e
status_output="$($project_root/scripts/status.sh "$kernel" 2>&1)"
status=$?
set -e
printf '%s\n' "$status_output"
if [ "$status" -eq 0 ]; then
    echo 'NATIVE FIX PRESENT: no workaround was built or installed.'
    exit 0
fi
[ "$status" -eq 10 ] || { echo "error: cannot determine native fix state (status $status)" >&2; exit "$status"; }

[ -r "/lib/modules/$kernel/build/Makefile" ] || { echo "error: matching headers are missing for $kernel" >&2; exit 2; }
case "$kernel" in
    7.0.0-31-generic) ;;
    *)
        echo "error: native fix is missing, but the vendored source is audited only for 7.0.0-31-generic; refusing an unreviewed ABI" >&2
        exit 3
        ;;
esac

build_root=$(mktemp -d "${TMPDIR:-/tmp}/surface5-dw9719-install.XXXXXX")
trap 'rm -rf "$build_root"' EXIT
OUTPUT_ROOT="$build_root" "$project_root/scripts/build-dw9719-7.0.sh" "$kernel"
artifact=$(find "$build_root" -type f -name dw9719.ko -print -quit)
[ -n "$artifact" ] || { echo 'error: build succeeded without a dw9719.ko artifact' >&2; exit 1; }
"$project_root/scripts/install-dw9719-7.0.sh" "$artifact"
echo 'WORKAROUND_INSTALLED: run sudo modprobe dw9719 to bind an existing unbound VCM.'
