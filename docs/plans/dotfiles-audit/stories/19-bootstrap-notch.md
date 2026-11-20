# Story 19: Bootstrap and post-hook target the notch

## Story

19. As the owner, I want bootstrap.sh and the matugen post-hook to target the notch (its state dir and the notch-lock SDDM theme) so that a fresh install reproduces this machine. Requires: #18

## Acceptance criteria

- [ ] Given a fresh install, when bootstrap finishes and I reboot, then the SDDM greeter is notch-lock, and the silent theme, its sync helper and its sudoers entry are not installed.
- [ ] Given the first boot after a fresh install, when the notch starts, then it shows the default wallpaper with matching colours, and after I pick another wallpaper the greeter shows it at the next logout.
- [ ] Given a wallpaper change, when the matugen post-hook runs, then it neither reads nor writes the old Quickshell state dir or the silent theme, so no stale wallpaper reaches hyprpaper or SDDM.

## Plan

- Replace the bootstrap SDDM steps: install the notch-lock theme from the notch submodule, create the shared greeter data dir the notch publishes to (readable by the sddm group) and point the notch at it, and make the repo SDDM config select notch-lock.
- Drop the silent theme from the repo and the bootstrap, with the sync helper and its sudoers entry.
- Seed the default wallpaper and theme mode in the notch's own state dir instead of the old one.
- Remove the post-hook's hyprpaper and silent-theme sections; the notch already writes its own hyprpaper config and stages the greeter.
- Pin each with bash tests on the scripts; reboot and greeter behaviour checked live; CLAUDE.md and the SDDM README follow.

## Out of scope

- LUKS, Plymouth and SDDM autologin (story 13).
- The greetd greeter (the notch repo's greetd tree stays as it is).
- Changes to the notch-lock theme itself or to how the notch stages it.
- Dropping hyprpaper as the notch's wallpaper fallback.
- Live cleanup of this machine (old state dir, installed silent theme, helper, sudoers); see suggestions.

## Suggestions (your call)

- This machine still has `/usr/local/bin/sddm-theme-sync` with a NOPASSWD sudoers entry that nothing will call any more; worth removing live with one owner-run `sudo` step once the story lands, together with `/usr/share/sddm/themes/silent` and `~/.local/state/quickshell/`.

## Size

normal
Risk: item 2, 5, 6 (sudoers entry and greeter data permissions; install script and SDDM config; reboot and greeter only verifiable live)

## Log

- L1 request: /flow:story 19
- L2 owner decision ("si, saquemoslo"): remove the silent theme entirely (theme, `sddm-theme-sync` helper, sudoers entry, post-hook section) instead of keeping it as a fallback. The sddm package's stock themes are the recovery path and git history keeps silent.
- L3 assumptions (for approval): the live notch-lock setup is the target to reproduce: theme at `/usr/share/sddm/themes/notch-lock` with `theme.conf.user` linked to `/var/lib/quickshell-notch-sddm/theme.conf.user`, that dir `deadlock:sddm` mode 2750, `~/.local/state/quickshell-notch/sddm-target.txt` naming it, and `Current=notch-lock` (today in a hand-made `/etc/sddm.conf.d/zz-notch-lock.conf`; the repo config takes it over). The notch's own installer script (`scripts/install-sddm-theme.py`) is reused, not rewritten. The post-hook's other sections (kitty, btop, LibreOffice, Zen, Obsidian, Stylus vars, Hyprland reload) stay.
