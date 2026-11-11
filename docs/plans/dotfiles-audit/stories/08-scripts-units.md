# Story 08: Scripts and user systemd units audit

## Story

08. As the owner, I want my scripts and user systemd units audited so that nothing is dead, duplicated or broken.

## Acceptance criteria

- [ ] Given a new login session, when I list my user units, then every unit the repo deploys is wanted and running (or enabled and idle by design), and none watches or runs a path that no longer exists.
- [ ] Given the scripts in ~/.local/bin, when I use each one from its keybind, Quickshell or the shell, then it works on this ThinkPad; scripts nothing uses and I do not want are gone, and no two scripts do the same job.
- [ ] Given the repo deployed, when I look at my app launcher entries and the scripts README, then no entry points at a missing target and the README lists exactly the scripts that remain.

## Plan

- Units: drop the kitty-theme-reload pair (it watches and runs caelestia paths that no longer exist; story 02 moved kitty theming to the live socket); confirm matugen-server is still the Stylus feed and keep it.
- Scripts: for each of the 21, check who calls it (keybinds, Quickshell, other scripts, generated .desktop files) and whether its dependencies are installed; fix what is broken, and bring the unused ones to the owner to keep or drop.
- Overlap: check the battery-*, brightness-* and notification-send scripts against what Quickshell and the other scripts already do.
- Leftovers: fix or remove the dangling NetworkDisplays launcher entry, and update the scripts README.
- Verify: the test command, a new scripts/units test suite, and a live run of the kept keybinds.

## Out of scope

- The engram, upstream-watch and mpd units: they live outside this repo (AI dotfiles) or were settled in story 06.
- system/ units and udev rules (story 09) and bootstrap.sh changes (story 10).
- New scripts or rewriting a working script for style.
- Stylus coverage (story 15).

## Assumptions

- Zero callers in the repo today: battery-remaining, battery-status, battery-time, brightness-display, brightness-keyboard, notification-send (used by reminder), webapp-launch/webapp-remove (used through generated .desktop files and by hand), wsaction (needs fish, which is not installed). Nothing is deleted without the owner's word per script.
- record stays as a manual fallback to the Quickshell recorder (documented choice), unless it is broken.
- libreoffice/soffice wrappers stay if they still serve the LibreOffice theming patch.

## Suggestions (your call)

- wsaction depends on fish while the shell is zsh; drop it rather than port it, since it has no keybind.

## Size

normal
Risk: item 5, 6 (stowed user units and runtime config; keybind and Quickshell behaviour verifiable only live)

## Log

- L1 request: "/flow:story 08"
- L2 approval: "si" (story and assumptions approved as written).
- L3 pair finding: nothing calls get-location (only a bootstrap comment) and nothing consumes the libreoffice/soffice wrapper's UNO socket (the matugen post-hook patches the .xcu only with LibreOffice closed). Live leftovers of the dropped Miracast scaffolding (6818674): dangling ~/.local/bin/network-display and ~/.local/share/applications/org.gnome.NetworkDisplays.desktop. Every dependency of the kept scripts is installed.
- L4 decision (owner: "si"): drop battery-remaining, battery-status, battery-time, brightness-display, brightness-keyboard, wsaction, get-location, libreoffice, soffice; keep notification-send, webapp-*, record, clipboard, launch-or-focus, mute-toggle, ocr, reminder, screenshot. Test list approved: 1 unit paths exist, 2 units active (characterization), 3 dropped scripts gone, 4 kept scripts deps + shellcheck (characterization), 5 no dangling symlinks, 6 README matches the package, 7 keybinds (manual).
- L5 pair: red→green 2b15382→4cfedee (kitty-theme-reload units disabled live and the systemd package removed; 957b1d8 drops its README row); characterization 564f297 (matugen-server enabled/active, shown failing while stopped); red→green 278df0d→ab46e14 (nine scripts unstowed and removed); characterization 9831abe (12 kept scripts: deps installed + shellcheck, shown failing on a PATH without tesseract/satty); red 718c5da → live-only fix (dangling ~/.local/share/applications/org.gnome.NetworkDisplays.desktop removed from $HOME; ~/.local/bin/network-display was already cleaned by the restow; no repo change, so no fix commit); red→green ef1e56c→2d3bbed (scripts README: wsaction out, notification-send and webapp-* in). scripts-units.test.sh: 6 ok, all passed; all 8 suites green; test command passes.
- L6 manual check (owner, live: "listo, todo funciona"): SUPER+O ocr, SUPER+R reminder show, PRINT/SUPER+PRINT screenshot, SUPER+SHIFT+V clipboard --delete, mute keys with LEDs.
- L7 verifier: PASS (refs unchanged, HEAD 2d3bbed). Notes: bootstrap.sh:725 comment still names get-location (story 10); CLAUDE.md still mentions wsaction.
- Done. Last code commit 2d3bbed. Risk: item 5, 6 (stowed user units and runtime config; keybind and Quickshell behaviour verifiable only live). Follow-ups: story 10 drops the get-location comment in bootstrap.sh; CLAUDE.md's wsaction mention and its "25 paquetes" count are stale (systemd package removed).
