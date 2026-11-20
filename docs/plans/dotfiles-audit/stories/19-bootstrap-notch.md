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
- L4 test list approved (owner: "si"): 1 fresh install sets up notch-lock (sandboxed fake sudo runs the real notch installer); 2 re-run keeps the installed greeter; 3 repo SDDM config selects notch-lock; 4 silent theme, sync helper and sudoers gone; 5 notch state seeded on a fresh install, kept on a re-run; 6 manual greeter check; 7 post-hook leaves hyprpaper and the greeter to the notch; 8 docs describe notch-lock. system.test.sh test_live_matches_repo expected red until the owner installs the repo deadlock.conf.
- L5 pair: red→green 2d510ce→46de790 (notch-lock bootstrap step; also inits the notch submodule, since deploy.sh runs later); 34bf3a0 characterization (re-run): green on arrival because 46de790 already held the skip branch (more code than test 1 needed); shown failing by removing that branch, code restored, no feat commit; 6a8ea20→3cab30e (deadlock.conf Current=notch-lock, no silent import path); 9470759→af43b39 (silent theme, sddm-theme-sync helper, sudoers step removed); 9c79ed1→be5c94f (notch state seeded); 09dcd2f→02a673d (post-hook hyprpaper and silent sections removed, 334 lines); e455e24→9a23e88 (CLAUDE.md, system/sddm/README.md). Test command passes at 9a23e88.
- L6 manual check (owner, live: "si cambio el wallpaper y si funciona"): owner installed the repo deadlock.conf and removed the hand-made zz-notch-lock.conf; logout showed the notch-lock greeter with the current wallpaper; after picking another wallpaper the next logout showed it (notch staged background-b and theme.conf.user at 16:02). system.test.sh all passed afterwards; hypr-session.test.sh fails only on the two untracked nwg-displays files.
