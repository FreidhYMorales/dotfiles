# Story 11: Ollama local models with a clear storage location

## Story

11. As the owner, I want Ollama running local models with a clear model storage location so that I can use LLMs offline.

## Acceptance criteria

- [ ] Given a fresh install from the repo, when bootstrap finishes and I reboot, then the Ollama service is running with the same service settings this ThinkPad has today (no hand-made drop-ins left out of the repo).
- [ ] Given I want to know where models live, when I read the repo docs, then they name one storage location, how much space it uses, and how to pull my models back after a reinstall.
- [ ] Given Wi-Fi is off, when I run one of my pulled models, then it answers locally.

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
