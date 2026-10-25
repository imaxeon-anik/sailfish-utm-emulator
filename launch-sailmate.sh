#!/bin/bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ssh -F "$HERE/ssh.config" sailfish-qemu 'bash -s' <<'GUEST'
set -e
rpm -q harbour-sailmate
# Wake the display without changing any configured device-lock credentials.
dbus-send --system --type=method_call --dest=com.nokia.mce /com/nokia/mce/request com.nokia.mce.request.req_display_state_on
if runuser -u defaultuser -- env XDG_RUNTIME_DIR=/run/user/100000 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/100000/dbus/user_bus_socket systemctl --user cat sailmate-preview.service >/dev/null 2>&1; then
    runuser -u defaultuser -- env XDG_RUNTIME_DIR=/run/user/100000 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/100000/dbus/user_bus_socket systemctl --user restart sailmate-preview
else
    runuser -u defaultuser -- env XDG_RUNTIME_DIR=/run/user/100000 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/100000/dbus/user_bus_socket systemd-run --user --unit=sailmate-preview --setenv=QT_QPA_PLATFORM=wayland --setenv=WAYLAND_DISPLAY=../../display/wayland-0 --setenv=LIBGL_ALWAYS_SOFTWARE=1 /usr/bin/harbour-sailmate
fi
GUEST
