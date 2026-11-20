# Story 11: Ollama local models with a clear storage location

## Story

11. As the owner, I want Ollama running local models with a clear model storage location so that I can use LLMs offline.

## Acceptance criteria

- [x] Given a fresh install from the repo, when bootstrap finishes and I reboot, then the Ollama service is running with the same service settings this ThinkPad has today (no hand-made drop-ins left out of the repo).
- [x] Given I want to know where models live, when I read the repo docs, then they name one storage location, how much space it uses, and how to pull my models back after a reinstall.
- [x] Given Wi-Fi is off, when I run one of my pulled models, then it answers locally.

## Plan

- Bring the live service tweaks under `/etc/systemd/system/ollama.service.d/` into `system/` and have bootstrap install them, the same way the other system configs are handled.
- Keep the stock storage location (`/var/lib/ollama`, set by the packaged unit); document it, its size and the re-pull commands for the current models.
- Verify offline use live: Wi-Fi off, one prompt to an installed model.
- Re-run the test command; the shellcheck gate stays clean.

## Assumptions (for approval)

- Storage stays at `/var/lib/ollama` on `/` (28G free). `~/Files` only has 12G free, so moving models there is worse; no new partition or mount.
- Bootstrap does not auto-pull models (about 29G); re-pulling stays a documented manual step.
- `igpu.conf` (`OLLAMA_IGPU_ENABLE=1`) and the `ollama-vulkan` backend are acceleration, so they belong to story 12. This story only carries over service settings that do not change which device runs inference (`download.conf`), and notes `igpu.conf` as story 12's to decide.

## Out of scope

- NPU/iGPU acceleration, `ollama-vulkan`, backend choice and benchmarks (story 12).
- Choosing, swapping or adding models.
- Any client or UI integration (shell widget, nvim plugin, primary-buffer script).

## Suggestions (your call)

- `ProtectHome=yes` in the packaged unit means a models path under `/home` would need an extra drop-in; one more reason to keep `/var/lib/ollama`.

## Size

normal
Risk: item 5 (bootstrap install step and systemd runtime config)

## Log

- L1 request: /flow:story 11
- L2 approval (owner): "si, como al instalar ya voy a tener de nuevo el disco completo y sin basura en el" — storage stays at /var/lib/ollama; after reinstall the root disk is clean, so free space only grows. The owner also offered a deeper machine/driver review; kept out of this story (proposed as a separate backlog story).
- L3 pair: test list approved (3 integration tests in scripts/tests/ollama.test.sh + 1 manual). Commits: 40909ed test -> 7175c2d feat (download.conf in system/systemd/ollama.service.d/, bootstrap copies it, daemon-reload, no live restart); ff542d3 test (live drop-ins match repo, igpu.conf excluded for story 12); fb56ccd test -> 0e5adf5 docs (post-install.md section 9: /var/lib/ollama, ~29G, one `ollama pull` per model with its size).
- L4 test-after (owner accepted: "si, aceptalo como test-after y anotalo"): ff542d3 was written after 7175c2d, so it passed on its first run. Red evidence: run against a drifted copy (LIVE_DROPINS override, edited download.conf + extra.conf) it failed 2 asserts; the verifier ran it at 7d7aa02 (pre-feat) and the repo-set assert failed.
- L5 evidence: `shellcheck -S error dotfiles/*.sh && dotfiles/deploy.sh --dry-run` exit 0 ("Dry run complete."); ollama.test.sh, bootstrap.test.sh, system.test.sh all passed. Manual C3: owner ran `ollama run gpt-oss:20b` with Wi-Fi off and it answered. Verifier: NEEDS DECISION on commit order only (C1, C2 PASS, tamper check PASS, mutants fail); refs unchanged; resolved by the owner as test-after (L4). Risk: item 5 (bootstrap install step and systemd runtime config)
- L6 follow-ups: gpt-oss output shows raw Harmony tokens (<|channel|>analysis...) in `ollama run`; post-install.md still has a Spicetify section (removed in story 05). The owner will review local models in depth after the reinstall.
