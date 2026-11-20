# Story 18: Old bar removed, clean notch logout

## Story

18. As the owner, I want the old bar removed and the notch logout clean so that only the notch shell is left on this machine.

## Acceptance criteria

- [ ] Given a fresh clone and `deploy.sh`, when I look at the deployed Quickshell configs, then only the notch config is there and the Hyprland session still starts it with every keybind working.
- [ ] Given a running session, when I log out from the notch power menu, then I land on the SDDM greeter and the journal shows no hyprpaper core dump for that logout.
- [ ] Given the repo docs, when I read how the desktop shell works, then they describe the notch as the only shell and no longer point at the old bar or its rollback.

## Plan

- Remove the old bar config from the quickshell stow package; the notch submodule stays the only config.
- Drop the rollback path to the old bar (the cutover script's rollback mode and anything that runs bare `qs`), in the notch repo, then bump the submodule.
- Switch the notch power-menu logout from the compositor exit to a session stop so apps (hyprpaper) shut down before the compositor dies.
- Pin the "only the notch config ships" and the logout command with tests; logout and SDDM landing checked live.
- Rewrite the CLAUDE.md shell sections that describe the old bar as current into a short history note pointing at the notch repo docs.

## Out of scope

- bootstrap.sh, the matugen post-hook, the old state dir `~/.local/state/quickshell` and the SDDM theme switch from silent to notch-lock (story 19).
- Keeping or dropping hyprpaper as the notch's wallpaper fallback.
- LUKS, Plymouth, autologin (story 13).
- Any new notch feature or visual change.

## Suggestions (your call)

- The old bar's docs (`lockscreen.md`, `idle-screensaver.md`, `recorder.md`, gotchas) hold hard-won findings; the notch repo may already cover them. Worth a quick diff before deleting, moving any gotcha that still applies into the notch docs.

## Size

normal
Risk: item 5, 6 (session logout command and shipped shell config; logout only verifiable live)

## Log

- L1 request: /flow:story 14
- L2 split: story 14 needed more than 3 criteria (old bar removal, logout, docs, plus bootstrap/post-hook/SDDM theme on the notch). Split into #18 (this) and #19 (bootstrap and post-hook target the notch).
- L3 assumptions (for approval): "fully replaces" means the old config is deleted from the repo, not kept as a fallback (notch ADR 0001, 2026-11-05: the old bar is temporary and removed in a later story; git history keeps it). The cutover itself is already live (Hyprland execs `qs -c notch`, keybinds call `qs -c notch ipc call`, SDDM runs notch-lock) and is not redone. The logout fix is the story 04 L6 follow-up: `uwsm stop` instead of `hyprctl dispatch hl.dsp.exit()`.
