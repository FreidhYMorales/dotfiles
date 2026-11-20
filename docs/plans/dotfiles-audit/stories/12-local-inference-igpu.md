# Story 12: Local inference on the Intel iGPU

## Story

12. As the owner, I want local inference to use the Intel NPU/iGPU so that models run fast without draining the battery. Requires: #11, #17

## Acceptance criteria

- [ ] Given a fresh install from the repo on this ThinkPad, when bootstrap finishes and I run one of my models, then Ollama runs it on the Arc iGPU, with no hand-made package or service setting left out of the repo.
- [ ] Given one of my models, when I want to know whether the iGPU is worth it, then the repo docs give its tokens per second and battery draw on the iGPU and on the CPU alone, measured on this ThinkPad, and the default is the better of the two.

## Plan

- Move the Vulkan backend out of bootstrap's exclusion list into the install, and bring the live iGPU service setting into the repo next to story 11's drop-in, installed the same way.
- Confirm live which settings Ollama actually needs to pick the iGPU (the Vulkan backend alone, or the iGPU setting too); carry only what makes a difference.
- Measure one model on battery, iGPU against CPU only: tokens per second and system power draw; record the numbers and how they were taken in the local-models docs.
- Pin it with tests: bootstrap installs the backend and the iGPU setting, the live drop-ins match the repo, and a loaded model reports the iGPU as its processor.
- Verify: test command plus all suites green.

## Out of scope

- The NPU and OpenVINO (GenAI, NPU/GPU plugins, model conversion): the owner reviews it after the reinstall.
- Choosing, swapping or adding models; the gpt-oss raw Harmony tokens in `ollama run` (story 11 follow-up).
- Clients or UI integration (shell widget, nvim plugin, scripts).
- Other runtimes (llama.cpp, SYCL, IPEX-LLM).

## Assumptions

- Today's state, seen live: `ollama-vulkan` 0.40.16 is installed and the last load put the KV cache and compute buffers on `Vulkan0`; `igpu.conf` (`OLLAMA_IGPU_ENABLE=1`) lives only in `/etc`; bootstrap excludes `ollama-vulkan` ("story 11 decides").
- Story 11's `ollama.test.sh` leaves `igpu.conf` out of its repo comparison on purpose ("story 12 decides them"). Folding it in changes that existing test, so pair asks before touching it.
- The measurement uses `gpt-oss:20b` (the smaller model, 12 GB) unless the owner picks the other.

## Suggestions (your call)

- none

## Size

normal
Risk: item 5, 6 (package set and systemd runtime config; speed and battery numbers are measured by hand, not by a test)

## Log

- L1 request: "/flow:story 12"
- L2 scope (owner: "si, solo iGPU, el NPU después del reinstall"): iGPU through Ollama's Vulkan backend only; the NPU (OpenVINO GenAI, small INT4 models only, a different runtime) waits for the post-reinstall local-models review.
- L3 approval: "si" (story and assumptions approved as written).
- L4 finding: the Ollama binary and log confirm both pieces are needed: "dropping integrated GPU; to enable, set OLLAMA_IGPU_ENABLE=1"; today's boot detected `Vulkan0 Intel(R) Graphics (LNL) type=iGPU`. So both ollama-vulkan and igpu.conf go into the repo.
- L5 test list approved ("si"): 1 bootstrap installs the Vulkan backend, 2 repo ships igpu.conf (changes story 11's test_live_dropins_match_repo to stop excluding it; owner approved), 3 live model runs on the iGPU, 4 docs compare iGPU and CPU, 5 manual measurement on battery.
- L6 pair: red→green 265f03b→7c94533 (ollama-vulkan installed, exclusion entry and its empty section removed); efadda7→5d724f6 (igpu.conf in system/systemd/ollama.service.d/, byte-identical to live; bootstrap comment names it); characterization dfdd6e3 (live 100% GPU; a copy loading with num_gpu=0 fails with 100% CPU); 6eca19d→17d402c (post-install.md 9 "iGPU (Vulkan) vs CPU").
- L7 measurement (manual, on battery, balanced profile): gpt-oss:20b, 200 tokens, temperature 0, two runs each. iGPU 22.0/21.9 tok/s at 7.6/9.6 W; CPU only (num_gpu=0) 11.3/11.3 tok/s at 12.8/11.3 W; idle 4-6 W (the first CPU run's idle read 12.9 W because power_now lags after an unload; rerun after a 30 s rest). Documented means: iGPU 22.0 tok/s 8.6 W, CPU 11.3 tok/s 12.1 W; the iGPU stays the default.
- L8 checks: test command passes; ollama.test.sh all passed (7 tests); every suite green except hypr-session (pre-existing, the untracked nwg-displays files).
- L9 verifier round 1: PASS (refs unchanged), with a note: bootstrap's `--no-gpu`, which CLAUDE.md advised for the ThinkPad, skips vulkan-intel, so Ollama would fall back to the CPU after the reinstall. Owner ("si"): drop that advice. 4bc65a2→fffe980 (CLAUDE.md line 57 now says not to use --no-gpu on the ThinkPad); vulkan-intel on an Intel GPU stays pinned by hardware.test.sh (story 17).
- L10 verifier recheck at fffe980: PASS (refs unchanged). Test command passes; ollama.test.sh 8 tests, all passed. Weakness noted: test_docs_do_not_skip_gpu_on_thinkpad matches the old wording only, not a reworded positive advice.
- Done. Last code commit fffe980. Risk: item 5, 6 (package set and systemd runtime config; speed and battery numbers are measured by hand, not by a test). Follow-ups: NPU via OpenVINO GenAI after the reinstall (owner); intel-npu-driver-bin trails upstream (1.32.1); gpt-oss raw Harmony tokens in `ollama run` (story 11); post-install.md still has a Spicetify section (story 11 follow-up).
