#!/bin/bash
set -euo pipefail
ROOT="${SAILFISH_EMULATOR_HOME:-/Volumes/ANIKT9-VMs/sailfish-dev/emulator}"
python3 - "$ROOT/monitor.sock" <<'PY'
import socket, sys
s = socket.socket(socket.AF_UNIX)
s.settimeout(5)
s.connect(sys.argv[1])
s.recv(4096)
s.sendall(b'system_powerdown\n')
s.close()
print('ACPI shutdown requested. Wait for the QEMU window/process to exit before ejecting the SSD.')
PY
