# Story 01: Shell (zsh + starship) audit

## Story

01. As the owner, I want my shell (zsh, starship) audited and tuned so that every terminal starts fast and clean.

## Acceptance criteria

- [ ] Given a new kitty window, when it opens, then the prompt appears with every plugin/hook initialized once, no duplicated PATH entries, and startup at or below the 174 ms baseline (`hyperfine -N 'zsh -i -c exit'`).
- [ ] Given a wallpaper change, when matugen re-themes kitty, then the starship prompt follows the new palette (no hardcoded hex colors).
- [ ] Given I type a command that is not installed, when zsh can't find it, then it tells me which package provides it (or that none does); non-interactive `zsh -c` scripts load no aliases or prompt hooks.

## Plan

- Move module loading out of the always-sourced env file into the interactive path only; keep env vars (EDITOR, PATH, secrets) in one place, deduplicated.
- Remove dead code: p10k fallback and its config, HyDE leftovers, duplicated aliases, oh-my-zsh boilerplate comments.
- Rewrite the not-found handler on top of `pacman -F`.
- Trim starship to the languages actually used, fix broken modules, switch colors to ANSI names so the matugen-themed terminal palette drives it.
- Measure startup before/after; shellcheck/zsh -n the touched files; live check in kitty.

## Out of scope

- Switching shells (fish evaluation stays a separate decision).
- kitty/zellij configs (story 02), bootstrap changes (story 10 picks up whatever this story changes).

## Decisions

- Drop oh-my-zsh. Source autosuggestions, syntax-highlighting and completions from pacman packages directly.
- Keep the Esc Esc "prepend sudo" behavior as a small local zle widget.
- Move a short, curated set of git aliases into `functions/aliases.zsh` (history shows 0 uses of any oh-my-zsh git alias out of 378 `git` invocations, so porting all ~180 is dead weight).

- Profiled (zprof): zsh-256color 49 ms (useless on truecolor kitty) → remove; OMZ 85 ms total; compaudit+compinit ~36 ms → `compinit -C` with a daily-refreshed dump; functions loaded twice (21 ms each) → once, interactive only; tool inits (starship/atuin/fzf/direnv/zoxide ~34 ms) → cache their init output, regenerate when the binary changes. Target ~40-60 ms.
- fastfetch only in the first terminal of the session, plus an `ff` alias for on-demand use.
- Remove the global `--help` alias (the `?` widget already covers it).
- Remove `ffch` and fzf's `^R`; atuin owns `^R`.
- `ff*` helpers use `fd`/`rg` instead of `find`/`grep`.
- Add `fzf-tab`.

## Suggestions (your call)

- none pending

## Size

normal
Risk: item 5, 6 (shell runtime config; only verifiable live)

## Log

- L1 request: "que tal si vamos primero por las configuraciones individuales, en orden, y de ultimo el boostrap ... si quieres puedes hacer stories para hacerlo despacio y bien individualmente" / "Recuerda que tanto la parte visual como el flujo quiero que este actualizado, optimizado y mejor de lo que ya esta si se puede, tambien si existen nuevas integraciones que valdrian tener en cuenta podriamos explorarlo."
- L2 decision: drop oh-my-zsh, keep sudo-on-Esc-Esc, git aliases into aliases.zsh; user wants startup speed and technical (not popular-opinion) recommendations to disable or change flows.
- L3 approval: "dale, aplicalas todas. La parte del fastfetch, me gusta tu propuesta de dejarlo solo en la primeroa terminal de la sesion, y el alias para facil acceso"
