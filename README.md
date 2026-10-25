# Experimental Sailfish emulator on Apple Silicon

Local QEMU tooling, not a new emulator implementation and not an officially supported
Sailfish SDK configuration. No upstream OS binaries are committed or redistributed here.

## Verified progress

- Official SailfishOS 5.1.0.11 i686 emulator image downloaded and converted from VDI.
- Immutable-by-convention base plus separate writable QCOW2 overlay on the SSD.
- QEMU 11.1.2 `qemu32`, single-core, SATA configuration boots Linux and systemd to a
  **Sailfish OS 5.1.0.11 login prompt**. This is the real guest, not an HTML mockup.
- The Lipstick graphical shell aborts (`sig=6`). GUI and Sailmate are NOT running.
- SSH forwarding is localhost-only port 2233; the guest did not answer SSH banners.
- Experimental VM shut down successfully using ACPI after the probe.
- Existing Ubuntu build VM and Sailmate source were not modified.

## Files

Tooling: `~/Documents/GitHub/sailfish-utm-emulator`.
Images/logs: `/Volumes/ANIKT9-VMs/sailfish-dev/emulator`.

- `downloads/Sailfish_OS-5.1.0.11.7z`: official archive
- `base/sailfishos.vdi`: extracted original
- `base/sailfishos.qcow2`: converted base (do not boot writable)
- `sailfishos-working.qcow2`: experimental overlay
- `serial.log`: boot diagnostics
- `boot.png`: actual console screenshot, not a successful graphical session

## Reproduce the current probe

Prerequisites: Homebrew `qemu` and `sevenzip` (already installed on this Mac).
Run `bash run.sh` in a terminal. The Cocoa window is the actual QEMU display.
At the boot menu press Tab, append the following to the existing kernel arguments,
then press Enter:

```text
 vga=normal console=tty0 console=ttyS0,115200 loglevel=7
```

This manual boot-argument edit is not yet persisted to the image. It avoids the
VirtualBox-specific video mode prompt and records early boot diagnostics.

Keep the SSD mounted while ANY VM using it runs. Never run the same disk on two hosts.
Do not run the overlay twice. The launcher runs in the foreground and QEMU locks the disk.
The monitor is a local Unix socket at `monitor.sock`; send `system_powerdown` for ACPI
shutdown and verify QEMU exits before ejecting. Do not treat process startup as GUI readiness.

## Source and integrity

Official catalog:
https://releases.sailfishos.org/sdk/repository-3.13.5/common/Updates.xml

Archive:
https://releases.sailfishos.org/sdk/repository-3.13.5/common/org.merproject.emulators.emulator_latest/2026.06.16-1Sailfish_OS-5.1.0.11-Sailfish_SDK_Emulator.7z

Archive SHA-1 verified against its official `.sha1` file:
`1f5cddadb155e743e0910c1afe03417673c90e8c`.
This legacy checksum verifies transfer consistency; it is not a modern signature.

## Failed configurations and next investigation

- Default IDE/CD configuration: video prompt and optical-device I/O errors.
- `-cpu max -smp 2` with SATA: stalled early boot in the time observed.
- `-cpu qemu32 -smp 1`, SATA and generic console: reaches userspace; Lipstick aborts.

Next steps: obtain authenticated guest console access, inspect Lipstick journal/core reason,
check VirtualBox-specific graphics configuration, test supported framebuffer/graphics paths,
and investigate guest networking. Software-rendering compatibility remains unverified.
Only after a working GUI should an i486 Sailmate RPM be built and installed. The phone's
aarch64 RPM cannot run in this i686 guest.
