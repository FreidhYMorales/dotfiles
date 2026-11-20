# Backlog: dotfiles-audit

## Context

- What: Audit and improve the dotfiles repo one area at a time (visuals and workflow updated, optimized, and new integrations explored where worthwhile), ending with bootstrap, local models, login flow and notch. Plan: none.
- Stack: Arch Linux, Hyprland (Lua bridge), Quickshell, GNU Stow, bash
- Expensive decisions: login flow = LUKS + Plymouth + SDDM autologin (login-reinstall-plan.md)
- Test command: shellcheck -S error dotfiles/*.sh && dotfiles/deploy.sh --dry-run
- Single test: shellcheck <file>

## Backlog

01. [x] 0d688d5 As the owner, I want my shell (zsh, starship) audited and tuned so that every terminal starts fast and clean.
02. [x] 6d3e953 As the owner, I want my terminal stack (kitty, zellij) audited so that it is consistent with the theme and keybinds.
03. [x] 10693ac As the owner, I want a light re-check of nvim and yazi so that only drift since their recent audits is fixed.
04. [x] 9acf5c0 As the owner, I want my Hyprland session (hypr, uwsm, xdg-portal, termfilechooser) audited so that the desktop starts and behaves reliably.
05. [x] 022d1aa As the owner, I want the theming pipeline (matugen, spicetify, vesktop, betterdiscord, stylus, chromium-extension) audited so that every app follows the wallpaper.
06. [x] 382ad58 As the owner, I want my media setup (mpv, mpd, ncmpcpp, wiremix) audited so that playback and audio just work.
07. [x] 0cfe6d9 As the owner, I want my utilities (btop, fastfetch, git, mimeapps, fonts) audited so that defaults are correct on this ThinkPad.
08. [x] 2d3bbed As the owner, I want my scripts and user systemd units audited so that nothing is dead, duplicated or broken.
09. [x] b12513c As the owner, I want system/ configs (logind, pam.d, udev, systemd) audited so that root-level behavior is correct and safe.
10. [x] 551c424 As the owner, I want bootstrap.sh and deploy.sh reconciled with stories 01-09 so that a fresh install reproduces this machine.
11. [x] 0e5adf5 As the owner, I want Ollama running local models with a clear model storage location so that I can use LLMs offline.
17. [x] d50fc84 As the owner, I want this ThinkPad's hardware, drivers and firmware (CPU microcode, xe iGPU, NPU, audio, Wi-Fi/Bluetooth, power, fwupd) audited against the bootstrap so that every device runs on the right driver and config after a reinstall.
12. [x] fffe980 As the owner, I want local inference to use the Intel NPU/iGPU so that models run fast without draining the battery. Requires: #11, #17
13. [ ] As the owner, I want boot to go LUKS passphrase -> Plymouth -> SDDM autologin -> Hyprland so that I type one password and never see a black screen (see login-reinstall-plan.md).
14. [ ] As the owner, I want the notch shell cutover finished so that the new Quickshell fully replaces the old bar.
15. [x] d767bb7 As the owner, I want the Stylus userstyles to cover every surface of the sites I use so that no page keeps stock colors after a wallpaper change. Requires: #05
16. [x] 4f3d472 As the owner, I want a larger console font on the plain TTYs (no TTY replacement) so that text is readable on the 2K screen before any desktop starts.
