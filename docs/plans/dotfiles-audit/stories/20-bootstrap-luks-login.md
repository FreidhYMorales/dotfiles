# Story 20: Bootstrap login flow for LUKS and plain installs

## Story

20. As the owner, I want bootstrap.sh to set up the Plymouth splash on every install, and SDDM autologin with the LUKS-unlocked keyring only when root is on LUKS, so that a reinstall with or without encryption both end in a working login (see login-reinstall-plan.md).

## Acceptance criteria

- [ ] Given a reinstall with root on LUKS, when bootstrap finishes and I reboot, then the bgrt splash asks the LUKS passphrase, keeps its image until the desktop paints, and the Hyprland session starts with no greeter and the keyring unlocked.
- [ ] Given a reinstall without LUKS (or a re-run on this machine), when bootstrap finishes and I reboot, then the bgrt splash shows during boot, there is no autologin, and the notch-lock greeter asks for the password.
- [ ] Given either install, when I log out, then the notch-lock greeter asks for the password (autologin runs once per boot).

## Plan

- Detect whether root sits on LUKS; the encryption-only pieces below hang on that one answer.
- Both paths: Plymouth with the bgrt theme, a systemd-based initramfs and the splash on the kernel cmdline.
- LUKS path only: the initramfs unlocks the disk through Plymouth, the cmdline carries the LUKS mapping, and Plymouth quits keeping its last frame until the session takes the display.
- LUKS path: SDDM autologin into the uwsm Hyprland session once per boot, its PAM stack handing the LUKS passphrase to the keyring, and SDDM allowed to read that passphrase.
- Plain path: no autologin; the notch-lock greeter keeps asking for the password.
- Pin both paths with bash tests on the bootstrap steps (detection faked); the plan's checklist and CLAUDE.md follow.

## Out of scope

- Partitioning, `luksFormat`, moving the swap inside LUKS, Secure Boot, sbctl, the UKI and the firmware password (story 21).
- A notch-themed Plymouth splash (bgrt for now; a theme of our own is a separate idea).
- Hyprland `misc:background_color` / logo tweaks to match the splash.
- greetd and any display manager other than SDDM.

## Suggestions (your call)

- Before rebooting this machine on the new initramfs, keep an Arch USB at hand: a broken initramfs is recovered by chrooting and rerunning `mkinitcpio -P`.

## Size

normal
Risk: item 2, 5, 6 (autologin and the sddm-autologin PAM stack; initramfs hooks and kernel cmdline, now also on this unencrypted machine; the LUKS boot path is only verifiable on a reinstall)

## Log

- L1 request: /flow:story 13
- L2 split (owner: "si, preparemos el repo primero"): story 13 needs a reinstall with LUKS whose drive is not chosen yet. Split into #20 (this: the repo prepared for both a LUKS and a plain reinstall) and #21 (the reinstall itself: LUKS2, swap inside, Secure Boot, signed UKI, live verification).
- L3 owner decisions ("si, usemos bgrt por ahora, hagamos dos configs una para cuando se cifre y otra cuando no"): Plymouth uses the stock bgrt theme; bootstrap carries two configurations chosen by whether root is on LUKS, so a trial reinstall without encryption works before the drive is decided.
- L4 assumptions (for approval): the plain path keeps today's login (notch-lock greeter with password, no Plymouth, current busybox initramfs and resume hook), matching the plan's rejection of autologin without LUKS. The LUKS settings come from login-reinstall-plan.md as written (HOOKS line, cmdline, `[Autologin] User/Session=hyprland-uwsm.desktop/Relogin=false`, `pam_systemd_loadkey` before `pam_gnome_keyring` in sddm-autologin, `KeyringMode=inherit`, `plymouth quit --retain-splash`). The LUKS-path boot (criteria 1 and 3 on LUKS) is pinned by tests here and checked live at the trial or real reinstall (story 21); criterion 2 is checked live on this machine.
- L5 owner change at the test list ("dejar dos, una para cifrar el disco y otra para cuando no ... asi plymouth podemos verlo y probarlo ... el de sin cifrado que no haga el autologin"): the plain path also gets Plymouth (bgrt, systemd initramfs, splash on the cmdline) so it can be seen and tried on this machine; only autologin, the sddm-autologin PAM, the sddm.service drop-in and the LUKS initramfs/cmdline pieces stay LUKS-only. Criterion 2 and the plan updated; L4's "no Plymouth on the plain path" is superseded.
- L6 test list approved (owner: "si"): 1 root_on_luks detection (faked LUKS, LVM-on-LUKS, btrfs subvolume, plain; live: this machine is plain); 2 bgrt splash on a systemd initramfs on both paths, sd-encrypt only on LUKS; 3 splash on the kernel cmdline on both paths, rd.luks.name only on LUKS; 4 SDDM autologin, sddm-autologin PAM and sddm.service drop-in only on LUKS; 5 docs; 6 manual on this machine (plain path).
- L7 pair: red→green f0f88f5→1cc0100 (root_on_luks); a69bbbf→0f2b403 (boot splash step after the GRUB block; the busybox resume hook the hibernation step adds is harmless with systemd and is rewritten afterwards); 27ef27e→1bd9c21 (cmdline step; first attempt placed it indented inside the GRUB block, where the test extractor cannot find steps, so the second attempt moved it right after the block with its own grub-mkconfig, still skipped by --no-grub); 3a6df1e→564c45f (LUKS-only login: system/sddm/sddm.conf.d/luks-autologin.conf, system/pam.d/sddm-autologin, system/systemd/sddm.service.d/luks.conf); c04f338→65be666 (CLAUDE.md, login plan). Test command passes at 65be666; every suite passes except the known hypr-session nwg-displays files.
- L8 manual check (owner, live: "okay, funciona"): the steps ran on this machine through the repo bootstrap (HOOKS base systemd autodetect microcode modconf kms keyboard sd-vconsole plymouth block filesystems fsck, cmdline + splash, theme bgrt, initramfs rebuilt, backups *.pre-story20); after a reboot the bgrt splash showed and the notch-lock greeter asked for the password, no autologin. The LUKS path (criteria 1 and 3 on LUKS) is checked at the reinstall (story 21).
- L9 owner decision ("para el reinstall ... dejar desactivado grub, y que inicie directo a arch ... tambien aplica a si no esta cifrado"): new story 22 boots the UKI straight from the firmware on every install with the cmdline in /etc/kernel/cmdline; story 21 now requires it. This story stays on GRUB (what this machine boots today); the cmdline step is skipped with --no-grub.
