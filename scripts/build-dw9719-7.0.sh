#!/usr/bin/env bash
# Build, but never install, the patched DW9719 external module.
set -euo pipefail

kernel="${1:-$(uname -r)}"
project_root=$(cd "$(dirname "$0")/.." && pwd)
source_dir="$project_root/dkms/dw9719-ipu3-7.0-1.0"
output_root="${OUTPUT_ROOT:-$project_root/build}"
header_dir="/lib/modules/$kernel/build"

[ -r "$header_dir/Makefile" ] || { echo "error: headers missing for $kernel: $header_dir" >&2; exit 1; }
[ -r "$source_dir/dw9719.c" ] || { echo 'error: vendored module source is missing' >&2; exit 1; }
case "$kernel" in
    7.0.0-31-generic) ;;
    *) echo "error: this source is audited only for 7.0.0-31-generic, not $kernel" >&2; exit 2 ;;
esac

mkdir -p "$output_root"
work=$(mktemp -d "$output_root/dw9719-$kernel.XXXXXX")
cp "$source_dir/dw9719.c" "$source_dir/Makefile" "$work/"

echo "Building against $kernel in $work"
make -C "$header_dir" M="$work" modules
module="$work/dw9719.ko"
[ -f "$module" ] || { echo "error: expected module not produced: $module" >&2; exit 1; }
echo "Built module: $module"
modinfo "$module" | rg '^(filename|vermagic|name|alias):'
modinfo "$module" | rg -q '^alias:[[:space:]]+i2c:dw9719$' || {
    echo 'error: built module lacks i2c:dw9719 alias' >&2
    exit 1
}
echo 'PASS: built module exports i2c:dw9719 and was not installed.'
