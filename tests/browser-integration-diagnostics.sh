#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-only
# Read-only host diagnostic for PipeWire/portal/browser WebRTC camera exposure.
set -u -o pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
if [ "${1:-}" = '--help' ]; then echo 'Usage: browser-integration-diagnostics.sh'; exit 0; fi
[ "$#" -eq 0 ] || { echo 'error: no arguments accepted' >&2; exit 2; }
umask 077
out="${HOME}/Pictures/surface5-frontcamera-tests/$(date -u +%Y%m%dT%H%M%SZ)-browser-diagnostics"
mkdir -p "$out" || { echo "error: cannot create $out" >&2; exit 2; }
report="$out/browser-integration.txt"
run() { echo -e "\n===== $1 =====" >>"$report"; shift; "$@" >>"$report" 2>&1 || echo "[exit $?]" >>"$report"; }
run 'cam -l' cam -l
run 'wpctl status -n' wpctl status -n
run 'pw-cli ls Device' pw-cli ls Device
run 'pw-cli ls Node' pw-cli ls Node
run 'PipeWire user services' systemctl --user --no-pager --full status pipewire pipewire-pulse wireplumber xdg-desktop-portal
run 'WirePlumber journal' journalctl --user -b -u wireplumber --no-pager
run 'PipeWire journal' journalctl --user -b -u pipewire --no-pager
run 'Portal journal' journalctl --user -b -u xdg-desktop-portal --no-pager
run 'relevant packages' dpkg-query -W -f='${binary:Package}\t${Version}\t${db:Status-Abbrev}\n' pipewire pipewire-libcamera libspa-0.2-libcamera wireplumber xdg-desktop-portal xdg-desktop-portal-gnome libcamera0.2 libcamera-ipa gstreamer1.0-libcamera
run 'libcamera SPA files' dpkg -L libspa-0.2-libcamera
run 'portal introspection' gdbus introspect --session --dest org.freedesktop.portal.Desktop --object-path /org/freedesktop/portal/desktop
run 'portal Camera property' gdbus call --session --dest org.freedesktop.portal.Desktop --object-path /org/freedesktop/portal/desktop --method org.freedesktop.DBus.Properties.Get org.freedesktop.portal.Camera IsCameraPresent
run 'browser processes' bash -c "ps -eo pid=,comm=,args= | grep -Ei '[f]irefox|[c]hrom|[b]rave|[e]piphany|[o]pera' || true"
run 'browser packages' bash -c "dpkg-query -W -f='\${binary:Package}\t\${Version}\n' 'firefox*' 'chromium*' 'google-chrome*' 'brave*' 2>/dev/null || true; snap list 2>/dev/null || true; flatpak list 2>/dev/null || true"
if pw-dump >"$out/pw-dump.json" 2>"$out/pw-dump.stderr"; then python3 "$root/tools/pipewire-camera-report.py" "$out/pw-dump.json" >"$out/pipewire-camera-report.txt"; cat "$out/pipewire-camera-report.txt" >>"$report"; fi
grep -iE 'libcamera|camera|video|spa|api\.libcamera|enum\.manager|portal|error|fail' "$report" >"$out/highlights.txt" || true
printf 'BROWSER INTEGRATION RESULTS:\n%s\nRead-only logs: %s\n' "$out" "$report"
