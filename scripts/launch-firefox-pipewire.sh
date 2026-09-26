#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-only
# Start the requested portable Firefox with an isolated PipeWire-camera profile.
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
firefox=${FIREFOX_BINARY:-"$HOME/Applications/firefox-test/firefox/firefox"}
profile="${XDG_DATA_HOME:-$HOME/.local/share}/surface5-frontcamera/firefox-pipewire-profile"
[ "${1:-}" != '--help' ] || {
    cat <<'EOF'
Usage: launch-firefox-pipewire.sh [Firefox URL or arguments...]

Uses the portable Firefox under ~/Applications/firefox-test by default and an
isolated profile under ~/.local/share/surface5-frontcamera/. Set FIREFOX_BINARY
to use another executable. Remove that profile to roll back this configuration.
EOF
    exit 0
}
[ -x "$firefox" ] || { echo "error: portable Firefox is not executable: $firefox" >&2; exit 2; }
umask 077
mkdir -p "$profile"
if [ ! -e "$profile/user.js" ]; then
    install -m 600 "$root/tests/firefox-pipewire-user.js" "$profile/user.js"
elif ! cmp -s "$root/tests/firefox-pipewire-user.js" "$profile/user.js"; then
    echo "warning: preserving existing $profile/user.js" >&2
fi
exec "$firefox" --no-remote --profile "$profile" "$@"
