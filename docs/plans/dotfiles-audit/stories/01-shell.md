# Story 01: Shell (zsh + starship) audit

## Story

01. As the owner, I want my shell (zsh, starship) audited and tuned so that every terminal starts fast and clean.

## Acceptance criteria

- [x] Given a new kitty window, when it opens, then the prompt appears with every plugin/hook initialized once, no duplicated PATH entries, and startup at or below the 174 ms baseline (`hyperfine -N 'zsh -i -c exit'`).
- [x] Given a wallpaper change, when matugen re-themes kitty, then the starship prompt follows the new palette (no hardcoded hex colors).
- [x] Given I type a command that is not installed, when zsh can't find it, then it tells me which package provides it (or that none does); non-interactive `zsh -c` scripts load no aliases or prompt hooks.

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
- L4 pair: test 1 red (deac7d3) → green locally; stopped: pre-existing shellcheck warnings in bootstrap.sh:643 (SC2034 ROOT_TYPE) and deploy.sh:20 (SC2034 args) make the Test command fail on main too.
- L5 pair steps 2-6: red→green pairs a359265→16f4821 (drop OMZ, pacman plugins + fzf-tab), dc30d9e→85f4e6f (pacman -F not-found handler), 61c23a1→7dda567 (Esc Esc sudo + curated git aliases), 402b8dc→cfdb6de (starship ANSI palette, trimmed modules). ae3c58a pins test 3, already green from 612d808 (confirmed: old .zshenv loaded 24 aliases in zsh -c). Manual items: 556ee9d (cached tool init, compinit -C fix), 89b85ba (fastfetch once per session + `ff`, fd/rg helpers, no ffch/global --help/p10k). 3bc4ffe removes unused secrets.zsh hook and expired API key docs (user request). ~/.oh-my-zsh deleted (user OK).
- L6 manual checks (user, live kitty): fastfetch first terminal only + `ff` OK (initially consumed by a test run inside kitty, marker reset); prompt re-themes with wallpaper OK; fzf-tab Tab OK; atuin Ctrl-R OK. Startup: 174 ms → 69 ms → 25 ms (hyperfine `zsh -i -c exit`).
- L7 verifier #1: FAIL — C1 "every plugin/hook once" only pinned for functions/*.zsh; untested behaviour in 556ee9d/89b85ba; Log stale. Correction batch: 64b7c69 (every sourced file once; mutant duplicate prompt.zsh + autosuggestions → FAIL), dd7f22c→0d688d5 (cached init regenerates on new binary or new args; real bug fixed), 2e27259 (starship hook only interactive; test 3 checked a wrong function name — mutant starship init in .zshenv → FAIL), fastfetch-once test (mutant without marker → FAIL).
- L8 verifier recheck: PASS (HEAD e8f20bc). Suite: 10 tests, all passed; test command passes. Optional leftover: dead `starship_precmd` assertion in test 3 (shell.test.sh:70), superseded by 2e27259; kept per tamper rule unless the owner approves removal.
- Done. Last code commit 0d688d5. Risk: item 5, 6 (shell runtime config; only verifiable live). Follow-ups for story 10: bootstrap still installs oh-my-zsh and its plugin clones; must install zsh-autosuggestions/zsh-syntax-highlighting/zsh-completions via pacman, clone Aloxaf/fzf-tab to ~/.local/share/zsh/plugins, run `pacman -Fy` and enable pacman-filesdb-refresh.timer.
