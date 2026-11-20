# Story 10: Bootstrap and deploy reconciled with stories 01-09

## Story

10. As the owner, I want bootstrap.sh and deploy.sh reconciled with stories 01-09 so that a fresh install reproduces this machine.

## Acceptance criteria

- [ ] Given a fresh Arch install on this ThinkPad, when bootstrap.sh runs, then it sets up what stories 01-09 left in use (zsh without Oh My Zsh: plugins from pacman plus fzf-tab, pacman files database refreshed with its timer, mpd-mpris, xdg-terminal-exec) and nothing they removed (Oh My Zsh, spotify, spicetify-cli, the system-sleep hook).
- [ ] Given this machine's explicitly installed packages, when I check them against bootstrap.sh and the exclusion list, then every package is in exactly one of the two, and each exclusion has a one-line reason decided for this ThinkPad.
- [ ] Given an already installed system, when bootstrap.sh re-runs and deploy.sh runs, then both finish without aborting, nothing already set up is reset, and every bootstrap comment and dotfiles/README.md entry describes current behavior.

## Plan

- Apply the follow-ups recorded in stories 01-09 (zsh plugins and fzf-tab, files database timer, mpd-mpris, xdg-terminal-exec, spotify/spicetify removed, fonts step, stale get-location comment); keep deploy.sh's REAL_DIRS as stories 05-06 left them.
- Triage the 72 explicit packages missing from bootstrap.sh once with the owner, package by package, thinking of this ThinkPad as the reinstall target: each one goes into bootstrap.sh or into a documented exclusion list with its reason.
- Pin it with a test: `pacman -Qqe` minus bootstrap.sh minus the exclusion list is empty, plus checks for what stories 01-09 removed.
- Clean the stale docs that point at removed things (dotfiles/README.md zsh row with ~/.p10k.zsh, package count, CLAUDE.md mentions of the dropped hook and wsaction).
- Verify: test command plus all suites green; the owner re-runs bootstrap.sh on this machine for criterion 3.

## Out of scope

- Ollama and local models (stories 11-12), even though `ollama-vulkan` shows up in the triage: it is only classified, its setup stays in story 11.
- LUKS, Plymouth, SDDM autologin, Secure Boot (story 13).
- The notch shell and the notch-lock SDDM greeter install path (story 14); bootstrap.sh keeps installing the current Quickshell and silent theme.
- Changing what any stowed config does; this story only changes what gets installed and documented.
- A real fresh install or a VM run.

## Assumptions

- The triage happens during `/flow:pair`, not here; its outcome is recorded in this file's Log.
- Packages pulled in only as dependencies (not in `pacman -Qqe`) are not checked.
- The exclusion list lives in the repo next to bootstrap.sh.

## Suggestions (your call)

- Group the kept extras into one or two new bootstrap steps (e.g. dev tools, personal apps) instead of scattering them, so the triage result reads in one place.

## Size

normal
Risk: item 5, 6 (install script and package set; a fresh install is verifiable only on the real reinstall)

## Log

- L1 request: "/flow:story 10"
- L2 scope (owner: "la 1, ahora de la 2 vamos a ver bien que paquetes valen la pena instalar y cuales no, tomando en cuenta este equipo que es donde se va a hacer la reinstalacion"): follow-ups from 01-09 plus a one-pass triage of the 72 explicit packages missing from bootstrap.sh, judged for this ThinkPad, with a test that keeps the list from drifting.
- L3 approval: "si" (story and assumptions approved as written).
