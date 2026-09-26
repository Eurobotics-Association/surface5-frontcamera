#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-only
# Verify the versioned Firefox deployment interface without changing user state.
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
version_file="$root/config/deployment-version.env"

# shellcheck disable=SC1090
. "$version_file"
case "${DEPLOYMENT_PRODUCT:-}:${DEPLOYMENT_VERSION:-}" in
    EBtx-surface5-HDCam-patch:[0-9]*.[0-9]*.[0-9]*) ;;
    *) echo 'invalid versioned deployment identity' >&2; exit 1 ;;
esac
test "$("$root/scripts/install-firefox-pipewire.sh" --version)" = "$DEPLOYMENT_PRODUCT $DEPLOYMENT_VERSION"
"$root/scripts/install-firefox-pipewire.sh" --help | grep -Fq -- '--status'
"$root/scripts/install-firefox-pipewire.sh" --help | grep -Fq -- '--rollback'
"$root/scripts/status-user-firefox-camera-launchers.sh" --help | grep -Fq -- '--quiet'
printf 'FIREFOX_DEPLOYMENT_VERSION_TEST=passed %s %s\n' "$DEPLOYMENT_PRODUCT" "$DEPLOYMENT_VERSION"
