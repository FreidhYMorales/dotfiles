# Story 03: Light re-check of nvim and yazi

## Story

03. As the owner, I want a light re-check of nvim and yazi so that only drift since their recent audits is fixed.

## Acceptance criteria

- [ ] Given any line in a buffer, including the first and the last, when I press Alt j or Alt k (move) or `>`/`<` (indent) in normal or visual mode, then the line or selection moves or indents when it can and otherwise stays put, visual mode keeps the selection, and no error message appears.
- [ ] Given the current nvim (0.12.6) with plugins at their locked versions, when I start nvim and open a Lua, Python and QML file, then no startup error, deprecation warning or failed health check appears that was not there at the 2026-10-06 audit.
- [ ] Given the current yazi (26.9.1), when I start it and use my plugins (git, toggle-pane, chmod, ouch-extract, sys-clipboard, simple-mtp) and file openers, then each works with no error or deprecation notice.

## Plan

- Alt j/k: fix the move-line maps so they no-op at the buffer edges instead of raising `E16: Invalid range` (reproduced headless: the map at the last line fails, a middle line works).
- Indent: check the visual `>`/`<` maps (keep the selection) and normal `>>`/`<<` live; headless they already work, so fix only what fails in a real session.
- nvim drift: settle the uncommitted lazy.nvim lock bump, then check startup, `:checkhealth` and LSP attach on the three file types against the audit's baseline; fix only what broke since then.
- Docs drift: the nvim README and keymap notes that still describe Alt j/k as "accept line/word" (an AI completion removed in the audit) get corrected.
- yazi drift: start yazi and exercise each local plugin and opener; fix only what errors under 26.9.1.
- Verify: the test command plus a headless nvim check for the edges; yazi is checked live.

## Out of scope

- A new plugin-by-plugin audit of nvim or yazi (done on 2026-10-06 and 2026-10-10/20).
- New plugins, keymap redesign, theme changes.
- Updating plugins beyond the lock file already on disk.
- The `.atl/skill-registry.md` changes in the working tree (tooling noise, not config).
- bootstrap/deploy changes (story 10).

## Suggestions (your call)

- none

## Size

normal
Risk: item 5, 6 (editor runtime config; yazi plugin behaviour only verifiable live)

## Log

- L1 request: "/flow:story 03"
- L2 assumptions: "drift" = anything broken or stale since the nvim audit (2026-10-06) and the last yazi fixes (2026-10-20); the Alt j/Alt k error carried over from story 02 is the edge-of-buffer `E16`, reproduced headless.
- L3 approval: "si, aprobado, revisa tambien para los de keybind de indentacion que usan > / <" → indent maps folded into criterion 1. Headless check: visual `>`/`<` indent and keep the selection, normal `>>` works. Headless start also prints "clipboard: error: Nothing is copied" (a candidate for criterion 2).
- L4 pair: test list approved (6 automated + 3 manual) in scripts/tests/nvim.test.sh (headless nvim on the stowed config). Red→green pairs: 984dfdf→88d7e88 (Alt j last line), f554633→9c9b644 (Alt k first line), 1f3a55d→10693ac (visual Alt j/k at edges, expr maps returning "" so the original `gv=gv` rhs stays). Pin tests, each mutation-checked: fadd6f7 (move away from edges), 63cf7dc (visual indent keeps selection), db15bf7 (LSP attach lua_ls / pyright,ruff / qmlls, empty errmsg). Other: a5ca501 (lazy.nvim lock bump, exercised by the suite), 2e1f207 (docs: stale Copilot Alt j/k block removed, edge no-op noted).
- L5 manual checks (owner, live): "todos estan bien, no hay errores" — Alt j/k and >/< in kitty+zellij with no error; nvim start with no clipboard error and :checkhealth snacks clean; yazi plugins (git, toggle-pane, chmod, ouch-extract, sys-clipboard, simple-mtp) and openers with no errors.
- L6 verifier: PASS (HEAD 2e1f207, refs unchanged). Suite 11/11 ok; test command passes ("Dry run complete."). Verifier mutation: main's keymaps.lua turns all 4 edge cases red with E16. Optional leftover: no test pins that the selection survives visual Alt j/k (checked by hand headless, behaviour predates this story).
- Done. Last code commit 10693ac. Risk: item 5, 6 (editor runtime config; yazi plugin behaviour only verifiable live). Suggestions: the nvim README still has stale Gemini and Copilot sections (AI tools removed 2026-10-06); scripts/tests/nvim.test.sh is not in the backlog test command. Story 10 has nothing new to install.
