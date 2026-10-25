#!/bin/bash
set -euo pipefail
ROOT="${SAILFISH_EMULATOR_HOME:-/Volumes/ANIKT9-VMs/sailfish-dev/emulator}"
command -v qemu-system-x86_64 >/dev/null
for file in qemu-root.qcow2 vmlinuz initrd.img; do
  [[ -f "$ROOT/$file" ]] || { echo "Missing emulator file: $ROOT/$file" >&2; exit 1; }
done
# Foreground execution keeps shutdown and disk ownership explicit. QEMU locks the disk.
exec qemu-system-x86_64 \
  -name Sailfish-Sailmate -machine q35,accel=tcg -cpu max -smp 2 -m 2048 \
  -kernel "$ROOT/vmlinuz" -initrd "$ROOT/initrd.img" \
  -append 'root=/dev/vda rw console=tty0 console=ttyS0,115200 video=Virtual-1:540x960' \
  -drive "file=$ROOT/qemu-root.qcow2,format=qcow2,if=virtio" \
  -device virtio-vga -display cocoa \
  -nic user,model=virtio-net-pci,hostfwd=tcp:127.0.0.1:2233-:22 \
  -device qemu-xhci -device usb-tablet \
  -serial "file:$ROOT/serial-modern.log" \
  -monitor "unix:$ROOT/monitor.sock,server=on,wait=off"
