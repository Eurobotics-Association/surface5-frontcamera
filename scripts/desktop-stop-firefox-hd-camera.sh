#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-only
# Release the fixed-HD camera bridge from a desktop entry.
set -euo pipefail

unit=surface5-frontcamera-hd-bridge.service

notify() {
    command -v notify-send >/dev/null 2>&1 || return 0
    notify-send --app-name='Surface5 front camera' "$@" || true
}

[ "$#" -eq 0 ] || { printf 'Surface5 HD Front Camera: no arguments accepted\n' >&2; exit 2; }
systemctl --user stop "$unit"
notify 'Surface5 HD Front Camera' 'Camera bridge stopped; the physical camera was released.'
