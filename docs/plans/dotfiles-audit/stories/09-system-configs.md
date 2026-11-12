# Story 09: System configs audit

## Story

09. As the owner, I want system/ configs (logind, pam.d, udev, systemd) audited so that root-level behavior is correct and safe.

## Acceptance criteria

- [ ] Given an unlocked session, when the machine suspends by any trigger (lid close, idle timeout, dashboard button, `systemctl suspend`), then on resume the Quickshell lockscreen is already up and asks for the password, with no unlocked desktop visible.
- [ ] Given the lockscreen, sudo and a TTY login, when I authenticate, then each behaves as intended: lockscreen password never waits on or is bypassed by the fingerprint reader, lockscreen fingerprint works only while the `>security` toggle is on, sudo/TTY accept fingerprint or password.
- [ ] Given the repo and this ThinkPad, when I compare each system/ file in live use with its installed copy, then they match, every comment describes current behavior, AC plug/unplug and the mute LEDs still work, and the SDDM files in the repo reflect the decided state (fingerprint off at the greeter) even though SDDM stays disabled until the reinstall.

## Plan

- Suspend lock: the system-sleep hook is missing live and cannot work anyway (systemd 262 freezes user.slice while sleep hooks run, so its Quickshell IPC hangs until its timeout). Replace it with a logind delay inhibitor held by the session that locks on `PrepareForSleep`, then drop the hook from the repo.
- Auth: re-check the lockscreen PAM services against the live system-auth and pin their behavior with tests (pamtester where possible, the rest manual).
- Drift: adopt the live SDDM fingerprint-off PAM into the repo, fix the stale comment in the SDDM conf (it names a monitors file that no longer exists; scale 2 is still correct).
- Hibernate path: confirm suspend-then-hibernate still has its prerequisites (resume= on the cmdline, swap active, s2idle only) and keep it.
- Verify: a system/ test suite (repo vs installed, permissions, syntax) plus a live suspend/resume round.

## Out of scope

- SDDM autologin, the `sddm-autologin` PAM change, the `KeyringMode=inherit` drop-in, LUKS and Plymouth: login-reinstall-plan.md says autologin without LUKS is no authentication, so they land together at the reinstall (story 13).
- Switching greetd off or SDDM on, and the greetd notch greeter (story 13/14).
- /etc/sddm.conf.d/zz-notch-lock.conf and /etc/udev/rules.d/01-ttyusb.rules (live, not in repo): not ours unless the owner claims them.
- bootstrap.sh install steps, beyond removing the hook's own step if the hook is dropped (story 10).
- TPM2 / Secure Boot.

## Assumptions

- SDDM fingerprint off (live `/etc/pam.d/sddm` comments out `pam_fprintd`) is the intended state; the repo adopts it.
- `/etc/hosts` already has `127.0.1.1 archlinux`; nothing to do there.
- Backlog line 13 (greetd) is reworded to the decided flow: SDDM autologin + LUKS + Plymouth.

## Suggestions (your call)

- The inhibitor fits Quickshell itself (it already owns the lock and the session), so lock-before-sleep keeps working without any root-owned file.

## Size

normal
Risk: item 2, 5, 6 (PAM auth stacks and suspend lock; root-level runtime config; login and suspend verifiable only live)

## Log

- L1 request: "/flow:story 09"
- L2 paused (owner): "estoy viendo si paso de sddm a greetd, dejame ver eso primero y luego vemos lo de esta storie". Not approved yet; if greetd lands first (story 13), the SDDM parts of criterion 2 and the sddm.conf.d drift item move to greetd or drop.
- L3 owner decision: autologin through SDDM (not greetd: greetd's initial_session skips pam_authenticate, so the keyring cannot unlock from the LUKS passphrase). login-reinstall-plan.md rewritten for SDDM (ed96a5e).
- L4 re-cut (owner: "si, commitea y retomamos la 09"): SDDM dropped from criterion 2 (disabled live); autologin pieces moved out of scope to the reinstall (story 13), since autologin without LUKS is rejected in the plan.
- L5 approval: "si" (story, assumptions and backlog line 13 rewording approved as written).
