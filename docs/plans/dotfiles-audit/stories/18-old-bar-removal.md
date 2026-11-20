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
- L4 test list approved (owner: "si"): 1 package ships only the notch config; 2 keybinds covered by the existing hypr-session keybind test; 3 logout runs `uwsm stop` (changes the existing logout assertion in notch tests/powerMenu.test.mjs, approved); 4 docs name the notch as the only shell (deletes notch scripts/notch-cutover.sh and its 10 tests in tests/cutover.test.mjs, approved), split into 4a notch docs and 4b CLAUDE.md (stop rule 5); 5 manual logout check.
- L5 pair: red→green 23a0005→263fe48 (old bar removed); notch 3eb3c10→3474394 (logout `uwsm stop`); red 6318be1 → notch 30a8c03 (docs, cutover script and tests removed) → 0560abc (submodule bump); red f42a719 → a6bc122 (CLAUDE.md). Test command passes at a6bc122; quickshell.test.sh 7 ok. Known, not this story: hypr-session.test.sh fails only on the two untracked nwg-displays files; notch `make test` has 24 SDDM/greeter failures already present at base bf53f96.
- L6 verifier: NEEDS DECISION (refs unchanged). C1 PASS, C3 PASS with leftovers in CLAUDE.md missed by the English-only patterns (decision row "Bar style", `RecorderWidget` in the keybinds paragraph, reading-list `quickshell-vision.md`; `Wallpapers.qml` in the bootstrap paragraph can wait for story 19); C2 live logout check pending.
