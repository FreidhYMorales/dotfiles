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
- L4 test list approved (owner: "si"): 1 UKI cmdline on both paths; 2 UKI preset and firmware entry; 3 GRUB gone from bootstrap (deletes story 20 test_kernel_cmdline_on_both_paths and its helper, approved); 4 docs; 5 manual BootNext check on this machine.
- L5 pair so far: 319029a→c06178f (UKI cmdline; the red commit also carries an unused zram-unused fake, harmless); 7fa1378→f9ec425 (preset + firmware entry); 47115d3→4588292 (GRUB removed; grub/os-prober added to bootstrap-excluded.txt as the F12 fallback); 1808569→aeb77eb (docs). Test command passes at aeb77eb.
- L6 stop (rule 3): system.test.sh test_live_hibernate_prereqs fails "mkinitcpio runs the resume hook" on the live machine since story 20 switched it to systemd hooks (systemd resumes by itself from resume= on the cmdline). A story 20 regression: its suites ran before the owner applied the hooks live and were not rerun. Fixing it means changing that existing assertion; waiting for the owner.
- L7 regression round (owner: "si"): fix 05f0e3f changes system.test.sh test_live_hibernate_prereqs to accept the systemd hook ("the initramfs can resume (resume or systemd hook)"); system.test.sh all passed. Introduced by story 20 (systemd hooks applied live after its suites ran).
- L8 live trial found a bug: the first run wrote "resume=UUID=" empty (blkid prints no UUID without root; the faked blkid always answered). Red 867f12d (fake blkid answers only through sudo) → fix 761962f (sudo blkid). Owner reran the cmdline step and mkinitcpio -P.
- L9 manual check (owner, live): BootNext=0006 boot came up on the new entry ("BootCurrent: 0006"), /proc/cmdline = "root=PARTUUID=25230648-… rw zswap.enabled=0 quiet loglevel=3 nowatchdog splash resume=UUID=8ab819b6-…" (the real swap partition); owner then set BootOrder 0006,0004,… (Arch Linux first, GRUB second as the F12 fallback). Every suite passed afterwards (hypr-session only the known nwg-displays files). Hibernate/resume was not exercised live in this story; resume= names the active swap (system.test.sh). The LUKS path is checked at the reinstall (story 21).
- L10 verifier: NEEDS DECISION (refs unchanged, HEAD 682f133). C1 PASS (live BootCurrent 0006, /proc/cmdline; bgrt splash and greeter not named in L9). C2 LUKS boot only pinned in the sandbox (deferred to story 21). C3: no test covers a kernel-update rebuild; hibernate/resume not exercised live. Surviving mutants: ESP hard-coded to /boot/efi (the fake bootctl answers the same path); dropping the final mkinitcpio -P (nothing pins that the UKI is built after the cmdline and preset steps). Note: the firmware entry is created before the UKI is built; an abort in between leaves the first entry pointing at a missing file (firmware falls through). Waiting for the owner.
