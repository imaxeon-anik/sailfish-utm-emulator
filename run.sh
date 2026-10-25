#!/bin/bash
set -euo pipefail
ROOT="${SAILFISH_EMULATOR_HOME:-/Volumes/ANIKT9-VMs/sailfish-dev/emulator}"
command -v qemu-system-i386 >/dev/null
[[ -f "$ROOT/sailfishos-working.qcow2" ]] || { echo "Missing emulator overlay: $ROOT" >&2; exit 1; }
# Foreground execution keeps shutdown and disk ownership explicit. QEMU locks the disk.
exec qemu-system-i386 \
  -name Sailfish-5.1-Experimental -machine pc,accel=tcg -cpu qemu32 -smp 1 -m 1024 \
  -nodefaults -device VGA -device ich9-ahci,id=sata \
  -drive "file=$ROOT/sailfishos-working.qcow2,format=qcow2,if=none,id=disk" \
  -device ide-hd,drive=disk,bus=sata.0 -display cocoa \
  -nic user,model=e1000,hostfwd=tcp:127.0.0.1:2233-:22 \
  -device usb-ehci -device usb-tablet \
  -serial "file:$ROOT/serial.log" \
  -monitor "unix:$ROOT/monitor.sock,server=on,wait=off"
