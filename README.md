# Sailfish OS emulator on Apple Silicon

## Current working setup

**Real Sailfish OS 5.1.0.11 userspace and Silica UI run on this Apple Silicon Mac in
QEMU software emulation. Sailmate's provider page has been displayed successfully.**
This is experimental, not an official SDK emulator configuration: it uses an Ubuntu
6.8.0-147-generic x86_64 kernel/initrd with i686 Sailfish userspace and LLVMpipe graphics.
It is not a browser simulation. Performance is slower than a physical phone.

The notes under **Original investigation** below preserve early results, not current blockers.

### Start, use and stop (existing SSD installation)

Prerequisites: macOS, the ANIKT9-VMs SSD mounted, Homebrew `qemu`, and the prepared
`qemu-root.qcow2`, `vmlinuz`, `initrd.img` files in the SSD emulator directory.
The repository alone does **not** contain a ready-to-boot OS image.

```bash
cd ~/Documents/GitHub/sailfish-utm-emulator
bash run.sh
```

The QEMU window is the real emulator. Allow 1–3 minutes for software-rendered startup.
Do not run this command if that emulator is already open. In another terminal:

```bash
ssh -F ssh.config sailfish-qemu 'systemctl is-active qemu-network qemu-sshd'
bash launch-sailmate.sh
```

Unlock the guest screen if necessary. Mouse clicks act as taps; hold and drag for swipes.
The pointer is mapped as an **absolute USB tablet**; see [POINTER.md](POINTER.md).
Sailmate runs as `defaultuser`, not root. Its launch helper starts the real binary directly
for development; this does not validate a sandboxed launcher start or Harbour compliance.
No API keys are provided and live provider calls remain unverified.

To stop:

```bash
bash stop.sh
```

Wait for QEMU to exit before disconnecting the SSD. The Ubuntu build VM is separate and
must also be stopped before ejecting. No helper stops that VM automatically.

### Install a new Sailmate build

Build an **i486** RPM in the Sailmate project (`bash scripts/build-rpm.sh i486`), then:

```bash
scp -F ssh.config /path/to/harbour-sailmate-VERSION-RELEASE.i486.rpm sailfish-qemu:/tmp/
ssh -F ssh.config sailfish-qemu 'pkcon -y install libsailfishsecrets sailfishsecretsdaemon sailfishsecretsdaemon-secretsplugins-default'
ssh -F ssh.config sailfish-qemu 'rpm -Uvh /tmp/harbour-sailmate-VERSION-RELEASE.i486.rpm'
bash launch-sailmate.sh
```

Replace VERSION/RELEASE. Do not install the phone's aarch64 RPM in this emulator.
SQLite's runtime package is `qt5-plugin-sqldriver-sqlite` (already present in the image).
Dependencies must resolve normally; do not use `--nodeps`.

### What is persisted and tracked

- [run.sh](run.sh): portrait 540×960 display, virtio GPU/network/disk, x86 CPU emulation.
- [ssh.config](ssh.config): localhost-only port 2233 and SSD credential paths; no key material.
- [stop.sh](stop.sh), [launch-sailmate.sh](launch-sailmate.sh): operational helpers.
- [guest/](guest/): exact added guest service/environment/udev files, including the 300-second
  Lipstick startup timeout needed for software rendering.
- All large disks, kernel/initrd files, logs, SSH keys and built RPMs remain outside Git.
  The repository does not redistribute Sailfish OS or Ubuntu binary images.

### Reconstructing the experimental guest

This is a record of the verified manual adaptation, **not a tested one-click installer**.
Use disposable copies and stop the guest before mounting or converting its disk.

1. Download/check the official archive using the source information below; extract its VDI.
2. Convert the disk to raw using `qemu-img`. The original partition begins at byte 512.
   Extract that ext4 partition to a separate file and mount it on a Linux helper machine.
3. Obtain a matching x86_64 Linux kernel/initrd with IA32 compatibility and virtio GPU,
   disk and networking support. This setup used the existing Ubuntu build VM's
   `/boot/vmlinuz-6.8.0-147-generic` and `/boot/initrd.img-6.8.0-147-generic`.
   Copy its matching `/lib/modules/6.8.0-147-generic` into the guest filesystem.
   Other versions have not been verified.
4. Copy the tracked `guest/` files into their matching absolute paths in the guest root.
   Make the files under `/home/defaultuser/` owned by UID/GID 100000.
5. Enable `qemu-network.service` and `qemu-sshd.service` via symlinks in
   `/etc/systemd/system/multi-user.target.wants/`. Mask `sdk-emulan.service`,
   `sdk-restart-connman.service` and `sshd.socket` with `/dev/null` symlinks under
   `/etc/systemd/system/`. These changes apply only to the experimental guest.
6. Generate a dedicated SSH key on the SSD (never commit it). Put only its public key in
   `/etc/ssh/emulator-keys/root`, mode 600. Change `AuthorizedKeysFile` in the guest's
   `/etc/ssh/sshd_config.sdk` to `/etc/ssh/emulator-keys/%u`; keep password login disabled.
7. Cleanly unmount ext4 and convert the extracted partition to `qemu-root.qcow2`.
   It is a filesystem-only disk, hence `root=/dev/vda`, not `/dev/vda1`.
8. Start with `run.sh`; verify the guest's SSH host fingerprint before recording it in the
   SSD `known_hosts`. Strict host-key checking is enabled in the supplied SSH config.
9. If DNS resolution fails, check the emulator's resolver; QEMU's default DNS is `10.0.2.3`.
   The static guest address is `10.0.2.15/24`, gateway `10.0.2.2`.
10. Install app dependencies and RPM, then verify native rendering. Installing software
    or modifying networking is restricted to this guest, not the phone or host network.

### Known limitations

- CPU and graphics are software-rendered; startup can be slow.
- The stock Sailfish kernel lacks virtio GPU support; do not revert to it with this configuration.
- Secrets persistence, API authentication and every gesture have not been end-to-end tested.
- Keyboard service warnings and launcher icon packaging were observed; app UI display is
  verified, not complete platform parity with a phone.
- Changing `SAILFISH_EMULATOR_HOME` changes launcher disk paths only; update `ssh.config`
  separately if moving keys/known-hosts. Keep SSH bound to localhost.

## Original investigation (historical)


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
