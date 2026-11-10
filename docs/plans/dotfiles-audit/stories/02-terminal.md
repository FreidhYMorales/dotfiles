# Story 02: Terminal stack (kitty + zellij) audit

## Story

02. As the owner, I want my terminal stack (kitty, zellij) audited so that it is consistent with the theme and keybinds.

## Acceptance criteria

- [ ] Given a wallpaper change, when matugen re-themes, then open kitty windows and new zellij sessions use the new palette, and every zellij UI element (frames, tabs, status bar, selected items) stays readable against the background.
- [ ] Given I am inside zellij, when I use my shell and nvim keys (atuin Ctrl-R, fzf, fzf-tab Tab, Esc Esc sudo, nvim Ctrl-based maps), then they reach the app; zellij actions sit behind one prefix and no single key quits the session by accident.
- [ ] Given a zellij session running in kitty, when I close the kitty window and open a new one, then I can reattach to the same session with its tabs and panes intact.

## Plan

- Kitty: remove dead config (unused Omarchy theme file, commented font list, stale comments). Keep only the settings that differ from kitty's defaults, and keep the matugen include plus the remote-control socket that the post-hook uses.
- Zellij: reduce the full default dump to the overrides that are actually used. Remove the unused `batman` theme and pick one prefix scheme that does not collide with shell or nvim keys.
- Theme: re-map the zellij matugen template to roles that contrast with the background (today `magenta`/`orange` use `*_container` roles that are nearly invisible). Check whether 0.45's newer theme format gives better control than the legacy 11-color one.
- Sessions: confirm that detach and reattach (plus resurrection after the kitty window closes) work with the trimmed config.
- Verify: `kitty --debug-config` and `zellij setup --check` are clean, plus a live check of a wallpaper change, the key passthrough and a reattach.

## Out of scope

- Shell config (story 01, done), nvim keymaps (story 03), Hyprland keybinds that launch kitty (story 04).
- The matugen pipeline beyond the kitty/zellij templates and their post-hook lines (story 05).
- bootstrap/deploy changes (story 10 picks them up).
- Replacing zellij with tmux.

## Decisions

- Move kitty's remote-control socket from `/tmp/kitty-{kitty_pid}` to `$XDG_RUNTIME_DIR` (per-user, not world-listable); the matugen post-hook's socket lookup moves with it, so live re-theming keeps working.
- Enable zellij `session_serialization` so that sessions can be resurrected after a reboot, not just after a window close.

## Suggestions (your call)

- none pending

## Size

normal
Risk: item 5, 6 (terminal runtime config; keybind passthrough and theming only verifiable live)

## Log

- L1 request: "/flow:story 02"
- L2 decision: keep zellij (user: "dejalo, porque kitty no tiene termux, eso a veces sirve, o mejor dicho, va servir"). Usage today is low (~5 invocations in history); kept for detach/reattach persistence.
- L3 approval: "si, aprobada, aplica las dos sugerencias" → both suggestions promoted to Decisions.
- L4 pair: test list approved with Ctrl b as the single prefix. Red→green pairs: 34f518e→b1d9e9a (kitty socket in $XDG_RUNTIME_DIR), c2c5900→18c4514 (post-hook scans runtime-dir sockets; sandboxed with fake kitten), dbde6c8→3cf16c0 (zellij theme migrated to the 0.42+ component format, RGB only; WCAG >= 3:1 per component, 2 seeds x dark/light; all 9 scheme types checked by hand), a7b0e1d→5963180 (normal mode binds only Ctrl b; Alt keys, Ctrl g, Ctrl q removed), ad7785d→10ba9ca (Ctrl b < > / Shift space / g / q, user-approved). Refactors: 6c7f6c5 (kitty: theme.conf removed, defaults dropped), 6d3e953 (zellij 521→264 lines, explicit session_serialization true).
- L5 decision: test 5 (session resurrection) moved to manual (user OK). A background or pty-attached test session never wrote session-layout.kdl within 200 s / 141 s, while 8 real sessions do show as EXITED and resurrectable.
