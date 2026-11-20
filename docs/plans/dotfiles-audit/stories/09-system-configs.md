# Story 09: System configs audit

## Story

09. As the owner, I want system/ configs (logind, pam.d, udev, systemd) audited so that root-level behavior is correct and safe.

## Acceptance criteria

- [ ] Given an unlocked session, when the machine suspends by any trigger (lid close, idle timeout, dashboard button, `systemctl suspend`), then on resume the Quickshell lockscreen is already up and asks for the password, with no unlocked desktop visible.
- [ ] Given the lockscreen, the SDDM greeter, sudo and a TTY login, when I authenticate, then each behaves as intended: lockscreen password never waits on or is bypassed by the fingerprint reader, lockscreen fingerprint works only while the lockscreen fingerprint setting is on, SDDM requires the password (no fingerprint) and unlocks the keyring, sudo/TTY accept fingerprint or password.
- [ ] Given the repo and this ThinkPad, when I compare each system/ file in live use with its installed copy, then they match, every comment describes current behavior, and AC plug/unplug and the mute LEDs still work.

## Plan

- Suspend lock: already built by the notch shell (a logind delay inhibitor that locks on `PrepareForSleep`); pin it with a test and drop the dead system-sleep hook (missing live, and unworkable since systemd 262 freezes user.slice while sleep hooks run) with its bootstrap step.
- Auth: re-check the lockscreen PAM services against the live system-auth and pin their behavior with tests (pamtester where possible, the rest manual).
- Drift: adopt the live SDDM fingerprint-off PAM into the repo, fix the stale comment in the SDDM conf (it names a monitors file that no longer exists; scale 2 is still correct).
- Hibernate path: confirm suspend-then-hibernate still has its prerequisites (resume= on the cmdline, swap active, s2idle only) and keep it.
- Verify: a system/ test suite (repo vs installed, permissions, syntax) plus a live suspend/resume round.

## Out of scope

- SDDM autologin, the `sddm-autologin` PAM change, the `KeyringMode=inherit` drop-in, LUKS and Plymouth: login-reinstall-plan.md says autologin without LUKS is no authentication, so they land together at the reinstall (story 13).
- The SDDM notch-lock theme and the greetd notch greeter (notch repo, story 14).
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
- L6 pair stop (plan vs code mismatch): the running shell is the notch shell (`qs -p shell/shell.qml` from the notch checkout), and its services/SleepLock.qml already holds a logind delay inhibitor and locks on PrepareForSleep (live: `systemd-inhibit --list` shows "notch ... Lock the session before sleep ... delay"). The plan's "replace the hook with an inhibitor" is already built; the remaining work is pinning it with a test and dropping the dead hook. The notch lockscreen uses the same quickshell-password/quickshell-fprint PAM services; its fingerprint setting is read by LockSecurity (notch file, falling back to the old `>security` file). Waiting for the owner's call.
- L7 re-scope (owner: "si"): criterion 1 is characterization of the notch SleepLock inhibitor plus dropping the dead hook and its bootstrap step; criterion 2 says "lockscreen fingerprint setting" instead of the `>security` toggle.
- L8 owner (2026-11-19): SDDM is enabled live again (notch-lock greeter, X11), greetd disabled; LUKS/Secure Boot wait on a drive decision ("vamos a seguir con sddm sin luks"), so SDDM PAM is back in criterion 2. Test list approved ("si"): 1 live sleep inhibitor (characterization), 2 hook dropped, 3 lockscreen PAM stacks (characterization), 4 sudo/TTY fprint-or-password (characterization), 5 SDDM PAM password-only with keyring, 6 live files match repo, 7 comments reference existing paths, 8 hibernate prerequisites (characterization), 9 manual (real suspend, lockscreen password+fingerprint on real PAM, SDDM login, sudo fingerprint, AC plug, mute LEDs). No automated wrong-password PAM runs (faillock). Mode C.
