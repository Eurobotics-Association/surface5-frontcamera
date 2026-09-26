#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-only
# Explicit rollback for the isolated portable-Firefox PipeWire profile.
set -euo pipefail
profile="${XDG_DATA_HOME:-$HOME/.local/share}/surface5-frontcamera/firefox-pipewire-profile"
if [ "${1:-}" != '--purge-profile' ] || [ "$#" -ne 1 ]; then
    echo "Usage: $0 --purge-profile" >&2
    echo "This removes only: $profile" >&2
    exit 2
fi
case "$profile" in
    "$HOME"/.local/share/surface5-frontcamera/firefox-pipewire-profile|"${XDG_DATA_HOME:-$HOME/.local/share}"/surface5-frontcamera/firefox-pipewire-profile) ;;
    *) echo 'error: unsafe profile path' >&2; exit 2 ;;
esac
rm -rf "$profile"
printf 'Removed %s\n' "$profile"
