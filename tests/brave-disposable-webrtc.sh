#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-only
# Run a reversible Brave WebRTC camera control with a temporary profile.
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
mode=normal
close_existing=false
stop_only=false
control_record="${XDG_RUNTIME_DIR:-/tmp}/surface5-brave-webrtc-control.env"

usage() {
    cat <<'EOF'
Usage: ./tests/brave-disposable-webrtc.sh [--pipewire-camera] --close-existing
       ./tests/brave-disposable-webrtc.sh --stop

Runs Brave as a temporary, project-named user service using a new disposable
profile. It neither reads nor writes the normal Brave profile. Brave's normal
processes must be closed because Chromium permits only one instance per user.

--pipewire-camera  add the experimental WebRtcPipeWireCamera feature for this
                    run only; it creates no persistent Brave preference.
--close-existing   close running Brave processes before the test.
--stop              stop a detached temporary test, release its bridge, and
                    remove its recorded disposable profile.

The script starts the known-good fixed-HD virtual source and a localhost-only
WebRTC test. In the temporary Brave window, grant the prompt and click “Run
virtual HD camera test”. Close every temporary Brave window when finished; the
script then releases the bridge and removes the temporary profile.
EOF
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --pipewire-camera) mode=pipewire-camera ;;
        --close-existing) close_existing=true ;;
        --stop) stop_only=true ;;
        --help) usage; exit 0 ;;
        *) usage >&2; exit 2 ;;
    esac
    shift
done

stop_detached_control() {
    [ -f "$control_record" ] || { echo 'BRAVE_CONTROL=not-running'; exit 0; }
    control_value() {
        sed -n "s/^$1=//p" "$control_record" | tail -n 1
    }
    recorded_state=$(control_value CONTROL_STATE_DIR)
    recorded_server_pid=$(control_value CONTROL_SERVER_PID)
    recorded_bridge_was_active=$(control_value CONTROL_BRIDGE_WAS_ACTIVE)
    case "$recorded_state" in
        "${TMPDIR:-/tmp}"/surface5-brave-webrtc.*) ;;
        *) echo "error: refusing unexpected temporary-control path: $recorded_state" >&2; exit 1 ;;
    esac
    systemctl --user stop surface5-brave-webrtc-control.service 2>/dev/null || true
    if [[ "$recorded_server_pid" =~ ^[0-9]+$ ]] && [ -r "/proc/$recorded_server_pid/cmdline" ] && tr '\0' ' ' < "/proc/$recorded_server_pid/cmdline" | grep -Fq 'browser-webrtc-server.py'; then
        kill "$recorded_server_pid" 2>/dev/null || true
    fi
    if [ "$recorded_bridge_was_active" != true ]; then
        systemctl --user stop surface5-frontcamera-hd-bridge.service 2>/dev/null || true
    fi
    rm -rf -- "$recorded_state"
    rm -f -- "$control_record"
    echo 'BRAVE_CONTROL=stopped; temporary profile removed and camera bridge released.'
}

if [ "$stop_only" = true ]; then
    [ "$mode" = normal ] && [ "$close_existing" != true ] || { usage >&2; exit 2; }
    stop_detached_control
fi

brave=$(command -v brave-browser-stable 2>/dev/null || command -v brave-browser 2>/dev/null || true)
[ -n "$brave" ] && [ -x "$brave" ] || { echo 'error: Brave is not installed' >&2; exit 2; }
for command in python3 systemctl systemd-run wpctl; do
    command -v "$command" >/dev/null 2>&1 || { echo "error: required command is missing: $command" >&2; exit 2; }
done
systemctl --user --quiet is-active pipewire wireplumber xdg-desktop-portal || {
    echo 'error: PipeWire, WirePlumber, or the Camera portal is inactive' >&2
    exit 1
}

brave_process_pattern='/opt/brave.com/brave/brave'
if pgrep -f "$brave_process_pattern" >/dev/null 2>&1; then
    if [ "$close_existing" != true ]; then
        echo 'error: Brave is already running; rerun with --close-existing after saving browser work' >&2
        exit 1
    fi
    echo 'Closing existing Brave processes for the disposable test.'
    pkill -TERM -f "$brave_process_pattern" || true
    for _ in $(seq 1 10); do
        pgrep -f "$brave_process_pattern" >/dev/null 2>&1 || break
        sleep 1
    done
    pgrep -f "$brave_process_pattern" >/dev/null 2>&1 && {
        echo 'error: Brave did not close; close it manually before retrying' >&2
        exit 1
    }
fi

bridge_unit=surface5-frontcamera-hd-bridge.service
brave_unit=surface5-brave-webrtc-control
bridge_was_active=false
if systemctl --user --quiet is-active "$bridge_unit"; then
    bridge_was_active=true
fi

timestamp=$(date -u +%Y%m%dT%H%M%SZ)
result_root="${HOME}/Pictures/surface5-frontcamera-tests/${timestamp}-brave-webrtc-${mode}"
state_dir=$(mktemp -d "${TMPDIR:-/tmp}/surface5-brave-webrtc.XXXXXX")
profile="$state_dir/profile"
server_stdout="$state_dir/server.stdout"
server_stderr="$state_dir/server.stderr"
server_pid=''

cleanup() {
    systemctl --user stop "${brave_unit}.service" 2>/dev/null || true
    if [ -n "$server_pid" ] && kill -0 "$server_pid" 2>/dev/null; then
        kill "$server_pid" 2>/dev/null || true
        wait "$server_pid" 2>/dev/null || true
    fi
    if [ "$bridge_was_active" != true ]; then
        systemctl --user stop "$bridge_unit" 2>/dev/null || true
    fi
    rm -rf -- "$state_dir"
    rm -f -- "$control_record"
}
trap cleanup EXIT INT TERM

umask 077
mkdir -p "$result_root" "$profile"
"$root/scripts/start-user-hd-camera-bridge.sh"

python3 "$root/tests/browser-webrtc-server.py" --root "$root/tests" --output "$result_root" \
    >"$server_stdout" 2>"$server_stderr" &
server_pid=$!
for _ in $(seq 1 50); do
    [ -s "$server_stdout" ] && break
    kill -0 "$server_pid" 2>/dev/null || {
        cat "$server_stderr" >&2 || true
        echo 'error: localhost WebRTC server failed' >&2
        exit 1
    }
    sleep 0.1
done
url=$(sed -n 's/^LISTENING //p' "$server_stdout" | head -n 1)
[ -n "$url" ] || { echo 'error: localhost WebRTC server did not publish a URL' >&2; exit 1; }
{
    printf 'CONTROL_STATE_DIR=%s\n' "$state_dir"
    printf 'CONTROL_SERVER_PID=%s\n' "$server_pid"
    printf 'CONTROL_BRIDGE_WAS_ACTIVE=%s\n' "$bridge_was_active"
} > "$control_record"
chmod 600 "$control_record"

args=(--no-first-run --no-default-browser-check "--user-data-dir=$profile" "$url")
if [ "$mode" = pipewire-camera ]; then
    args=(--enable-features=WebRtcPipeWireCamera "${args[@]}")
fi
systemctl --user reset-failed "${brave_unit}.service" 2>/dev/null || true
systemd-run --user --quiet --collect --service-type=exec --unit="$brave_unit" \
    "$brave" "${args[@]}"
for _ in $(seq 1 10); do
    systemctl --user --quiet is-active "${brave_unit}.service" && break
    sleep 1
done
systemctl --user --quiet is-active "${brave_unit}.service" || {
    systemctl --user --no-pager --full status "${brave_unit}.service" || true
    echo 'error: temporary Brave did not remain active' >&2
    exit 1
}

printf 'BRAVE_CONTROL=running mode=%s\n' "$mode"
printf 'BRAVE_CONTROL_URL=%s\n' "$url"
printf 'BRAVE_CONTROL_RESULTS=%s\n' "$result_root"
printf '%s\n' 'In the temporary Brave window, grant camera access and click “Run virtual HD camera test”.'
printf '%s\n' 'Close the temporary Brave window when finished. If this terminal disconnects, run this script with --stop to release the bridge and remove its disposable profile.'

while systemctl --user --quiet is-active "${brave_unit}.service"; do
    sleep 1
done
printf 'BRAVE_CONTROL=closed; temporary profile removed and camera bridge released.\n'
