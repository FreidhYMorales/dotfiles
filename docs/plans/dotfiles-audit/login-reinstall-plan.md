# Login flow plan for the clean reinstall

Status: decided, pending. Waits on the owner's choice of drive (this M.2 or
a new one) and applies at that clean install. Until then the login is the
SDDM notch greeter with a password and no LUKS. Feeds stories 10, 13 and 14.

Story 20 prepared bootstrap.sh for both outcomes, chosen by whether / sits
on LUKS. Every install gets the stock `bgrt` Plymouth splash (firmware logo)
on a systemd initramfs with `splash` on the cmdline. Only a LUKS root adds
`sd-encrypt` and `rd.luks.name=`, SDDM autologin
(`system/sddm/sddm.conf.d/luks-autologin.conf`), the `sddm-autologin` PAM
stack with `pam_systemd_loadkey` and the `sddm.service` drop-in. Without
LUKS there is no autologin: the notch-lock greeter asks for the password.
Story 21 is the reinstall itself (partitioning, Secure Boot, UKI).

Owner decision (2026-11-20): the reinstall drops GRUB on every install,
LUKS or not. The firmware boots the (signed) UKI directly through an
efibootmgr entry and its cmdline lives in `/etc/kernel/cmdline` (story 22);
the other distros go away, and a future dual boot comes from another
distro's GRUB detecting Arch. The GRUB items in the Secure Boot checklist
below are superseded by that.

## Problem

Every display manager (SDDM, greetd, GDM, ly, LightDM) runs the login screen
in one compositor and the session in another. Between the greeter exiting
and Hyprland taking the display, nobody owns DRM, so the kernel console
(fbcon) shows: black, or whatever text is on the VT. fbcon cannot draw an
image. Changing display manager does not fix it.

## Decision

Full-disk encryption is the authentication; the session starts without a
greeter.

1. LUKS2 passphrase at boot, asked by Plymouth with a themed image. This is
   the only password typed at boot.
2. SDDM autologin starts the Hyprland (uwsm) session directly: no greeter,
   no lock at boot.
3. Plymouth keeps its last frame (`--retain-splash`) until Hyprland takes the
   display: image -> desktop, no black gap and no console text.
4. `pam_systemd_loadkey` in `sddm-autologin` hands the LUKS passphrase to
   `pam_gnome_keyring`, so the keyring unlocks without a second password.
5. The Quickshell lockscreen covers idle, suspend and manual lock. Required:
   LUKS does not protect a running or suspended machine.
6. Logout: `Relogin=false`, so autologin runs once per boot and a logout
   shows the SDDM greeter (notch-lock theme). The black gap returns on this
   path only; it is rare (broken session, session restart).
7. One secret: LUKS passphrase = user password = keyring password, so boot,
   the logout greeter, the lockscreen and sudo all unlock the same things.
   It is a long random passphrase (5-6 diceware words): with argon2id that
   makes an offline attack on a stolen disk impractical.
8. Secure Boot with the owner's own keys, signed GRUB and a signed unified
   kernel image (UKI). LUKS leaves the ESP and the kernel unencrypted, so
   without this someone with brief physical access (evil maid) can plant an
   initramfs that records the passphrase. The UKI carries the kernel
   cmdline inside the signature, so it cannot be edited at the GRUB menu.
   A firmware supervisor password keeps Secure Boot from being turned off.
9. Suspend-then-hibernate with the swap inside LUKS: after
   `HibernateDelaySec` the disk key leaves RAM and resume asks for the
   passphrase. This machine only has s2idle, so while merely suspended the
   key stays in memory and the lockscreen is the only barrier.

Why: single user, single machine. Without encryption the login password only
stops someone at the keyboard; booting a USB reads the disk anyway. With
encryption the post-boot login is redundant, which is what lets it go.

Rejected:

- greetd `initial_session`: greetd starts it without `pam_authenticate`
  (`start_unauthenticated_session`, `authenticate = false` in greetd's
  `context.rs`), so no `auth` module runs and the keyring cannot be unlocked
  from the LUKS passphrase. SDDM autologin runs the `sddm-autologin` auth
  stack; `man pam_systemd_loadkey` uses it as its example.
- `Relogin=true`: systemd's cached passphrase expires (about 2.5 min, verify
  on install), so an automatic relogin after a logout would start with the
  keyring locked.
- Keyring with an empty password: works with any display manager, but SDDM
  makes it unnecessary.
- Unlocking the keyring with the fingerprint: impossible, a fingerprint match
  yields no secret to derive the keyring key from.
- TPM2 auto-unlock: the disk would unlock by itself and autologin would give
  the desktop to anyone holding the laptop.
- Autologin without LUKS: no authentication at all.
- Autologin + lock at session start: a short unlocked window before the lock
  maps, and two passwords once LUKS exists.
- A greeter password on top of LUKS: one person, one machine; it only stops
  someone who knows the LUKS passphrase but not the user password.
- Swapping the SDDM X11 greeter for Wayland (weston/kwin) or greetd to kill
  the black gap: every greeter exits before Hyprland paints, so the gap
  stays; only autologin + `--retain-splash` removes it.

## Install checklist

Partitioning:

- [ ] ESP (unencrypted) + LUKS2 root (`cryptsetup luksFormat --type luks2
      --pbkdf argon2id`), passphrase only.
- [ ] Hibernation: the swap must live inside the encrypted volume (swapfile on
      root, or LVM on LUKS). Today's swap is a separate plain partition, which
      would leave RAM contents unencrypted on hibernate.

initramfs (`/etc/mkinitcpio.conf`), systemd-based so the fsck/udev text of
the busybox hooks disappears:

```
HOOKS=(base systemd autodetect microcode modconf kms keyboard sd-vconsole plymouth block sd-encrypt filesystems fsck)
```

Kernel cmdline (`resume_offset` only for a swapfile, from
`filefrag -v /swapfile`):

```
rd.luks.name=<luks-uuid>=root root=/dev/mapper/root rw resume=/dev/mapper/root resume_offset=<offset> quiet splash loglevel=3 rd.udev.log_level=3 systemd.show_status=auto vt.global_cursor_default=0 nowatchdog
```

Plymouth:

- [x] Install `plymouth` with the stock `bgrt` theme (bootstrap.sh, story
      20); a notch-themed splash is a later idea.
- [ ] Plymouth must quit with `--retain-splash` instead of the default quit.
      Verify on install how `sddm.service` orders against
      `plymouth-quit.service`; a drop-in with
      `ExecStartPre=-/usr/bin/plymouth quit --retain-splash` is the starting
      point.

SDDM (`/etc/sddm.conf.d/`):

```ini
[Autologin]
User=deadlock
Session=hyprland-uwsm.desktop
Relogin=false

[Theme]
Current=notch-lock
```

- [ ] Disable greetd, enable sddm.
- [ ] Session: `hyprland-uwsm.desktop` (present today in
      `/usr/share/wayland-sessions/`).

PAM (`/etc/pam.d/sddm-autologin`), keyring unlocked from the LUKS
passphrase; add before the existing `pam_gnome_keyring` line:

```
-auth       optional    pam_systemd_loadkey.so
-auth       optional    pam_gnome_keyring.so
-session    optional    pam_gnome_keyring.so auto_start
```

`sddm.service` drop-in, so it can read root's keyring (required by
`man pam_systemd_loadkey`):

```ini
[Service]
KeyringMode=inherit
```

- [ ] Verify on install that systemd-cryptsetup leaves the passphrase in the
      kernel keyring (key `cryptsetup`) and that the keyring password equals
      the LUKS passphrase.

Secure Boot (`sbctl`):

- [ ] Firmware: set a supervisor password, clear the Secure Boot keys (setup
      mode).
- [ ] `sbctl create-keys`, then `sbctl enroll-keys -m`: `-m` keeps
      Microsoft's keys, needed for firmware option ROMs and for the other
      installed distros (Fedora, openSUSE, Debian), which boot through a
      Microsoft-signed shim.
- [ ] UKI: kernel cmdline in `/etc/kernel/cmdline`, mkinitcpio preset with
      `default_uki=` writing to `<esp>/EFI/Linux/`; GRUB boots it with
      `chainloader`, so the signed cmdline is the one used.
- [ ] GRUB: `grub-install ... --modules="tpm" --disable-shim-lock`, then
      `sbctl sign -s` on `grubx64.efi` and the UKI; `sbctl verify` lists
      nothing unsigned. `-s` registers them, so the sbctl pacman hook
      re-signs on every kernel or GRUB update.
- [ ] fwupd: sign its EFI binary (`sbctl sign -s -o
      /usr/lib/fwupd/efi/fwupdx64.efi.signed /usr/lib/fwupd/efi/fwupdx64.efi`)
      or firmware updates stop working.
- [ ] Turn Secure Boot on; `sbctl status` shows it enabled with the owner's
      keys.

Lock (story 09):

- [ ] Lock before suspend through a logind delay inhibitor held by the
      session, not a system-sleep hook. Idle stays in Quickshell's
      IdleManager (no hypridle).

Hyprland:

- [ ] `misc:disable_hyprland_logo = true`, `misc:background_color` set to the
      Plymouth background, so the first frame before the shell paints matches.

## Verification

- Cold boot: Plymouth image -> passphrase -> desktop, no black frame and no
  console text (record with a phone camera; frames are too fast to judge by
  eye).
- Keyring unlocked after boot without a prompt.
- Lid close, idle and `systemctl suspend`: lockscreen up on resume.
- Logout: SDDM notch greeter appears; logging in with the password unlocks
  the keyring.
- TTY3 login still works as recovery.
- Secure Boot: `sbctl status` enabled; an unsigned EFI binary is refused by
  the firmware; the other distros still boot from the GRUB menu; editing the
  Arch entry at the GRUB menu does not change the kernel cmdline.
- Hibernate: after `HibernateDelaySec`, resume asks for the LUKS passphrase.
