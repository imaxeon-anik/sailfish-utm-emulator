# Absolute pointer mapping

The QEMU USB tablet reports absolute coordinates, but Qt 5.6's evdev mouse handler
requires explicit `abs` mode to scale them to screen coordinates. Without it, pointer
motion may be interpreted as very large relative movements.

The experimental guest now contains:

```text
/etc/udev/rules.d/99-sailfish-qemu-tablet.rules
SUBSYSTEM=="input", KERNEL=="event*", ATTRS{name}=="QEMU QEMU USB Tablet", SYMLINK+="input/sailfish-tablet"
```

In `/var/lib/environment/compositor/90-qemu.conf`:

```text
QT_QPA_EVDEV_MOUSE_PARAMETERS=/dev/input/sailfish-tablet:abs
```

The stable symlink avoids relying on a fixed event number. QEMU's selected device was
verified as `QEMU HID Tablet (absolute)`. After restarting Lipstick, its process environment
was verified to contain the setting above. Interactive pointer feel still needs user confirmation.

This changes only the experimental guest; macOS mouse speed is unchanged.
