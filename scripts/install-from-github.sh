#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-only
# Bootstrap the complete, versioned system deployment from GitHub.  This file
# is intentionally small because it is the only source fetched directly by the
# documented curl command; all install assets come from the same source archive.
set -euo pipefail

repository=${SURFACE5_FRONT_CAMERA_REPOSITORY:-Eurobotics-Association/surface5-frontcamera}
revision=${SURFACE5_FRONT_CAMERA_REVISION:-main}
command -v curl >/dev/null 2>&1 || { echo 'error: curl is required to download the release archive' >&2; exit 1; }
command -v tar >/dev/null 2>&1 || { echo 'error: tar is required to unpack the release archive' >&2; exit 1; }
stage=$(mktemp -d "${TMPDIR:-/tmp}/surface5-frontcamera.XXXXXX")
cleanup() { rm -rf -- "$stage"; }
trap cleanup EXIT INT TERM

printf 'Downloading %s at %s from GitHub…\n' "$repository" "$revision"
curl --fail --location --show-error --silent \
    "https://github.com/$repository/archive/refs/heads/$revision.tar.gz" |
    tar -xz --strip-components=1 -C "$stage"
[ -x "$stage/scripts/install-v4l2-camera.sh" ] || { echo 'error: downloaded archive has no V4L2 installer' >&2; exit 1; }
printf '%s\n' 'Starting the system-wide installer; sudo will now request the administrator password if needed.'
sudo -- "$stage/scripts/install-v4l2-camera.sh" --system
