# Story 07: Utilities audit (btop, fastfetch, git, mimeapps, fonts)

## Story

07. As the owner, I want my utilities (btop, fastfetch, git, mimeapps, fonts) audited so that defaults are correct on this ThinkPad.

## Acceptance criteria

- [x] Given the repo deployed on this machine, when I open btop, change something and quit, then the repo stays clean, and btop shows the matugen theme with CPU, memory, network, processes and the battery.
- [x] Given a new login session, when the first kitty terminal opens, then fastfetch shows a logo and its info with no errors or missing fields.
- [x] Given a text or code file, a folder or an archive, when I open it from yazi or the browser, then it opens in the intended app (assumed below), never LibreOffice Writer or Zen.

## Plan

- btop: stop btop writing its config back into the repo (it saves on exit through the folded ~/.config/btop) while keeping the owner's current box/sort choices; check each option against btop 1.4.7 and the ThinkPad (battery, Arc iGPU); drop the unused theme.
- fastfetch: fix the logo source (points at the old ~/Files/... path, which no longer exists) and check each module against fastfetch 2.70 on this hardware.
- mimeapps: set the missing or wrong defaults (text/code, folders, archives, JSON) and keep what already works (browser, images, PDF, media).
- git and fonts: check .gitconfig for stale or missing settings, and drop bundled fonts nothing uses.
- Verify: the test command plus `xdg-mime query default` per type and a live btop/fastfetch run.

## Out of scope

- Theming changes beyond btop keeping the matugen theme (story 05 closed the pipeline).
- bootstrap.sh changes (story 10), including which fonts it installs.
- The git hooks path and the gh credential helper: they work and belong to the AI dotfiles setup.
- New tools or replacing any of these five.

## Assumptions

- Text, markdown-less code and shell scripts open in nvim inside kitty; folders open in yazi; archives open in yazi too (no GUI archiver installed). Markdown keeps Obsidian.
- The current uncommitted btop.conf change (`shown_boxes = "cpu net proc mem"`, `proc_sorting = "threads"`) is the owner's choice and is kept.
- Roboto and CustomTkinter_shapes_font are unused (no reference anywhere in the repo); the fonts package may end up empty.

## Suggestions (your call)

- btop: `save_config_on_exit = false` is the simplest fix; the mpd pattern (a real dir via deploy.sh REAL_DIRS) would also work but needs btop to keep a copy outside the repo.
- .gitconfig holds the owner's email in a public repo; it is already in git history, so moving it only helps if you care about future copies.

## Size

normal
Risk: item 5, 6 (stow packages and runtime config; fastfetch output and opening files from yazi/browser verifiable only live)

## Log

- L1 request: "/flow:story 07"
- L2 approval: "si" (story and assumptions approved as written).
- L3 pair finding: yazi already opens text/code (nvim), archives (ouch) and folders (its own rules) without mimeapps; the gap is everything going through xdg-open. nvim.desktop and yazi.desktop are Terminal=true, and glib 2.90 launches those only through xdg-terminal-exec (or gnome-terminal), neither installed. Probing btop in a pty, btop ignored XDG_CONFIG_HOME and rewrote the repo btop.conf (restored to the owner's values), confirming C1 live.
- L4 decision (owner: "el 1"): install xdg-terminal-exec (extra) with a stowed xdg-terminals.list pointing at kitty, so every Terminal=true entry opens in kitty; story 10 adds it to bootstrap.sh. Test list approved ("si").
- L5 pair: red→green pairs 11bd8b2→e1e4921 (btop save_config_on_exit=false), 1a98f65→2914a60 (unused caelestia theme dropped), 020d71a→8c29328 (fastfetch logo from ~/.config/fastfetch/logo), abb66e5→1db9da6 (chassis format without the version this ThinkPad reports as None), 26da165→4d12970 (text/json/shellscript → nvim, folders/zip/tar → yazi), 7e3bf5e→4fe3790 (new stow package xdg-terminal-exec → kitty, deployed live), 1dce52e→edbf606 (unused Roboto/CustomTkinter fonts unstowed and removed); characterization test 92e423d (battery box, shown failing with show_battery=false). ef4dc1d commits the owner's btop box order/thread sorting. .gitconfig reviewed: nothing stale, unchanged.
- L6 manual checks (owner, live: "todo bien, los 3 funcionan"): btop shows matugen colours, fastfetch logo shows in the first kitty, `xdg-open ~/.zshrc` / `xdg-open ~/Downloads` open nvim / yazi in a new kitty.
- L7 verifier: FAIL (net box test matched a bare "net"; compressed archives fell back to Chromium through xdg-open). Correction batch: characterization test 4ec1b0b (net box download/upload graphs, shown failing without net), red→green 083c580→0cfe6d9 (gzip, tgz, xz, bzip2, zstd, 7z, rar and their tarballs → yazi). Recheck: PASS (refs unchanged, HEAD 0cfe6d9). utilities.test.sh: 13 ok, all passed; all suites green; test command passes.
- Done. Last code commit 0cfe6d9. Risk: item 5, 6 (stow packages and runtime config; fastfetch output and opening files from yazi/browser verifiable only live). Follow-ups: story 10 adds xdg-terminal-exec to bootstrap.sh and drops any fonts-package step; ~/.local/share/applications/org.gnome.NetworkDisplays.desktop is a dangling entry (story 08 or cleanup); host module could show "LENOVO ThinkPad X1 Carbon Gen 13" in fastfetch (suggestion).
