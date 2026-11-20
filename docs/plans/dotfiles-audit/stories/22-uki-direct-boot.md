# Story 22: Boot the UKI straight from the firmware, no GRUB

## Story

22. As the owner, I want every install (LUKS or not) to boot the unified kernel image straight from the firmware, with no GRUB, and its kernel cmdline (splash, resume, LUKS mapping) in /etc/kernel/cmdline so that Arch boots directly and the cmdline cannot be edited at a boot menu. Requires: #20

## Acceptance criteria

- [ ] Given a fresh install without LUKS, when bootstrap finishes and I reboot, then the firmware boots Arch straight into the bgrt splash with no boot menu, and the notch-lock greeter asks for the password.
- [ ] Given a fresh install with root on LUKS, when bootstrap finishes and I reboot, then the splash asks the LUKS passphrase and unlocks the disk with no boot menu in between.
- [ ] Given an installed system, when a kernel update rebuilds the image or I hibernate and resume, then the next boot still goes straight to Arch and resume returns to my session.

## Plan

- Bootstrap writes the whole kernel cmdline into the UKI's cmdline file: the root device, rw, resume, the quiet boot options and splash, plus the LUKS mapping on a LUKS root.
- Enable the UKI in the kernel preset and register it as the first firmware boot entry on the ESP the system reports.
- Remove GRUB from bootstrap: its packages, theme, os-prober, menu settings, the GRUB cmdline step and the GRUB-only flags.
- The hibernation step writes resume into that same cmdline file only.
- Pin it with bash tests on the steps (sandboxed, faked tools); check it live on this machine with a one-time boot of the new entry before making it first; CLAUDE.md, the login plan and install.sh follow.

## Out of scope

- Signing the UKI, Secure Boot keys and LUKS formatting (story 21).
- Removing the other distros or their firmware entries from this machine (that happens at the reinstall).
- A fallback UKI or any other bootloader (systemd-boot included).
- Changing the initramfs hooks or the Plymouth theme (story 20).

## Suggestions (your call)

- Keep the GRUB entry in the firmware menu (F12 boot menu) on this machine until the reinstall: it is the way back if the new entry does not boot.

## Size

normal
Risk: item 3, 5, 6 (bootstrap and install.sh flags removed; kernel cmdline, UKI preset and firmware boot order; booting only verifiable on real firmware)

## Log

- L1 request: /flow:story 22
- L2 owner decision ("si, saquemoslo"): GRUB leaves bootstrap entirely (packages, Star Wars theme, os-prober, menu config, the story 20 GRUB cmdline step, `--no-grub`/`--grub-res`), no opt-in flag. A future dual boot comes from another distro's GRUB detecting Arch.
- L3 assumptions (for approval): this machine already builds the UKI at `/boot/efi/EFI/Linux/arch-linux.efi` from `/etc/kernel/cmdline` (written by archinstall), but the firmware boots GRUB; a stock `linux.preset` ships `default_uki` commented, so bootstrap must enable it. The cmdline keeps today's options (`quiet loglevel=3 nowatchdog`, `resume=`) plus `splash`, with `root=` from the root device (PARTUUID on a plain root, the LUKS mapping on LUKS). The ESP is the one `bootctl --print-esp-path` reports; the firmware entry is labelled "Arch Linux". Existing GRUB tests (story 20's cmdline test, any test reading the GRUB steps) change or go away: listed for approval in `/flow:pair`. The verifier's story 20 note (--no-grub on LUKS writing no rd.luks.name) is closed here, since the LUKS mapping moves to the UKI cmdline.
