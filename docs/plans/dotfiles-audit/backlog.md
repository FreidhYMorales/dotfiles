# Backlog: dotfiles-audit

## Context

- What: Audit and improve the dotfiles repo one area at a time (visuals and workflow updated, optimized, and new integrations explored where worthwhile), ending with bootstrap, local models, greetd and notch. Plan: none.
- Stack: Arch Linux, Hyprland (Lua bridge), Quickshell, GNU Stow, bash
- Expensive decisions: SDDM → greetd (login/lock/theming pipeline)
- Test command: shellcheck -S error dotfiles/*.sh && dotfiles/deploy.sh --dry-run
- Single test: shellcheck <file>

## Backlog

01. [x] 0d688d5 As the owner, I want my shell (zsh, starship) audited and tuned so that every terminal starts fast and clean.
02. [x] 6d3e953 As the owner, I want my terminal stack (kitty, zellij) audited so that it is consistent with the theme and keybinds.
03. [x] 10693ac As the owner, I want a light re-check of nvim and yazi so that only drift since their recent audits is fixed.
04. [~] As the owner, I want my Hyprland session (hypr, uwsm, xdg-portal, termfilechooser) audited so that the desktop starts and behaves reliably.
05. [ ] As the owner, I want the theming pipeline (matugen, spicetify, vesktop, betterdiscord, stylus, chromium-extension) audited so that every app follows the wallpaper.
06. [ ] As the owner, I want my media setup (mpv, mpd, ncmpcpp, wiremix) audited so that playback and audio just work.
07. [ ] As the owner, I want my utilities (btop, fastfetch, git, mimeapps, fonts) audited so that defaults are correct on this ThinkPad.
08. [ ] As the owner, I want my scripts and user systemd units audited so that nothing is dead, duplicated or broken.
09. [ ] As the owner, I want system/ configs (logind, pam.d, udev, systemd) audited so that root-level behavior is correct and safe.
10. [ ] As the owner, I want bootstrap.sh and deploy.sh reconciled with stories 01-09 so that a fresh install reproduces this machine.
11. [ ] As the owner, I want Ollama running local models with a clear model storage location so that I can use LLMs offline.
12. [ ] As the owner, I want local inference to use the Intel NPU/iGPU so that models run fast without draining the battery. Requires: #11
13. [ ] As the owner, I want to log in through greetd instead of SDDM so that login matches the Quickshell lockscreen.
14. [ ] As the owner, I want the notch shell cutover finished so that the new Quickshell fully replaces the old bar.
