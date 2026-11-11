# Login flow plan for the clean reinstall

Status: decided, not implemented. Applies at the next clean reinstall; until
then SDDM (or the current greetd greeter) stays as is. Feeds stories 09, 10,
13 and 14.

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
   the only password typed.
2. greetd `initial_session` starts `uwsm start -e -D Hyprland hyprland.desktop`
   directly: no greeter, no lock at boot.
3. Plymouth keeps its last frame (`--retain-splash`) until Hyprland takes the
   display: image -> desktop, no black gap and no console text.
4. `pam_systemd_loadkey` hands the LUKS passphrase to `pam_gnome_keyring`, so
   the keyring unlocks without a second password.
5. The Quickshell lockscreen covers idle, suspend and manual lock. Required:
   LUKS does not protect a running or suspended machine.
6. `initial_session` runs once per greetd start. After a logout greetd shows
   `default_session`: the notch greeter (cage + `greetd-shell.qml`) stays as
   the logout screen.

Why: single user, single machine. Without encryption the login password only
stops someone at the keyboard; booting a USB reads the disk anyway. With
encryption the post-boot login is redundant, which is what lets it go.

Rejected:

- TPM2 auto-unlock: the disk would unlock by itself and autologin would give
  the desktop to anyone holding the laptop.
- Autologin without LUKS: no authentication at all.
- Autologin + lock at session start: a short unlocked window before the lock
  maps, and two passwords once LUKS exists.
- SDDM: it can autologin too, but greetd is lighter and already has a greeter
  matching the notch.

## Install checklist

Partitioning:

- [ ] ESP (unencrypted) + LUKS2 root (`cryptsetup luksFormat --type luks2
      --pbkdf argon2id`), passphrase only.
- [ ] Hibernation: the swap must live inside the encrypted volume (swapfile on
      root with `resume=` + `resume_offset=`, or LVM on LUKS).

initramfs (`/etc/mkinitcpio.conf`), systemd-based so the fsck/udev text of
the busybox hooks disappears:

```
HOOKS=(base systemd autodetect microcode modconf kms keyboard sd-vconsole plymouth block sd-encrypt filesystems fsck)
```

Kernel cmdline:

```
rd.luks.name=<luks-uuid>=root root=/dev/mapper/root rw quiet splash loglevel=3 rd.udev.log_level=3 systemd.show_status=auto vt.global_cursor_default=0 nowatchdog
```

Plymouth:

- [ ] Theme with the notch image; set it with `plymouth-set-default-theme -R`.
- [ ] greetd must stop Plymouth with `--retain-splash` instead of the default
      quit. Verify on install how the greetd unit orders against
      `plymouth-quit.service`; a drop-in with
      `ExecStartPre=-/usr/bin/plymouth quit --retain-splash` is the starting
      point.

greetd (`/etc/greetd/config.toml`):

```toml
[terminal]
vt = 1

[initial_session]
command = "uwsm start -e -D Hyprland hyprland.desktop"
user = "deadlock"

[default_session]
command = "/usr/local/share/quickshell-notch-greetd/greetd/launch-greeter.sh"
user = "greeter"
```

PAM (`/etc/pam.d/greetd`), keyring unlocked from the LUKS passphrase:

```
auth     optional  pam_systemd_loadkey.so
auth     optional  pam_gnome_keyring.so
session  optional  pam_gnome_keyring.so auto_start
```

- [ ] Verify on install that systemd-cryptsetup leaves the passphrase in the
      kernel keyring (key `cryptsetup`) for `pam_systemd_loadkey`, and that
      the keyring password equals the LUKS passphrase.

Lock (story 09):

- [ ] Lock before suspend through a logind delay inhibitor held by the
      session, not a system-sleep hook.
- [ ] hypridle: lock on idle and `before_sleep_cmd`.

Hyprland:

- [ ] `misc:disable_hyprland_logo = true`, `misc:background_color` set to the
      Plymouth background, so the first frame before the shell paints matches.

## Verification

- Cold boot: Plymouth image -> passphrase -> desktop, no black frame and no
  console text (record with a phone camera; frames are too fast to judge by
  eye).
- Keyring unlocked after boot without a prompt.
- Lid close, idle and `systemctl suspend`: lockscreen up on resume.
- Logout: notch greeter appears and logs back in.
- TTY3 login still works as recovery.
