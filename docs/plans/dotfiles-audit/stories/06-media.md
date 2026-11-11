# Story 06: Media setup audit (mpv, mpd, ncmpcpp, wiremix)

## Story

06. As the owner, I want my media setup (mpv, mpd, ncmpcpp, wiremix) audited so that playback and audio just work.

## Acceptance criteria

- [x] Given the repo deployed on this machine, when mpd runs, then its database, state, log and playlists never land inside the repo, and it still knows my whole library.
- [x] Given mpd running, when I save a playlist from ncmpcpp, then it is saved and mpd's log stops reporting the missing playlists folder.
- [x] Given a local video, when I open it in mpv, then it plays with hardware decoding on the Arc iGPU, and ncmpcpp's visualizer moves while mpd plays.

## Plan

- Deploy: move mpd's runtime files (database, state, sticker db, playlists) out of the stowed ~/.config/mpd into ~/.local/state/mpd, log to journald, and let a unit drop-in create those directories.
- mpd: make sure the playlists folder exists and the log does not grow without bound; keep the pulse output (PipeWire's pulse server) and the visualizer fifo.
- mpv / ncmpcpp / wiremix: check each option against the installed versions and drop anything dead or redundant; no restyling.
- Verify: the test command plus a live check (playlist save, mpv hwdec on a local file, visualizer).

## Out of scope

- A CLI Spotify client, new players or theming these apps with matugen (`/flow:idea`).
- bootstrap.sh changes (story 10): mpd-mpris is installed and enabled here but not in the script; `systemctl --user enable --now mpd` stays as is.
- PipeWire/WirePlumber tuning or Bluetooth audio beyond what playback needs.

## Assumptions

- mpd + ncmpcpp stay in daily use (mpd log shows plays up to 2026-11-09).
- ~~Live configs are stale copies~~: wrong, ~/.config/mpd, ncmpcpp and wiremix are folded stow symlinks (see L3).
- Music library stays at ~/Music.

## Suggestions (your call)

- Adopted (L4): mpd runtime moved to `~/.local/state/mpd`.
- ncmpcpp still writes `error.log` and `lyrics/` inside the repo through the folded ~/.config/ncmpcpp (error.log is gitignored): same fix pattern if wanted.
- `hwdec=auto-safe` tries Vulkan decode first and logs `VK_KHR_video_decode_queue` errors before falling back to vaapi; `hwdec=vaapi` would silence it.

## Size

normal
Risk: item 1, 5, 6 (mpd database/state when restowing; stow packages; playback and hwdec verifiable only live)

## Log

- L1 request: "/flow:story 06"
- L2 approval: "si" (story approved as written; the ~/.local/state/mpd suggestion stays the owner's call during pair).
- L3 pair finding: the live ~/.config/mpd, ncmpcpp and wiremix were folded stow dir symlinks, not stale copies (the earlier diff compared each file with itself). Real problem: mpd wrote database/state/log/sticker into the repo, hidden by .gitignore. C1 reworded (owner: "si").
- L4 decision (owner: "si"): mpd runtime goes to ~/.local/state/mpd, log to journald. mpd 0.24 does not create its dirs, so a unit drop-in does (StateDirectory + mkdir playlists); systemd ignores a symlinked drop-in dir, so deploy.sh REAL_DIRS keeps it real. Live migration moved database/state/sticker.sql (old log kept as mpd.log.old).
- L5 manual checks (owner, live): local video plays with `Using hardware decoding (vaapi)`, `VO: [gpu-next] vaapi[nv12]`; ncmpcpp visualizer moves. YouTube in mpv fails with 403 even with --no-config: YouTube now needs `&range=` on each chunk (yt-dlp adds it via http_chunk_size, mpv hands the bare URL to ffmpeg; curl 403 without, 200 with). Upstream mpv/yt-dlp breakage, not this config; owner ("si") dropped YouTube from C3, follow-up for /flow:idea.
- L6 pair: red→green pairs 0888ee8→f0517a7 (mpd runtime to ~/.local/state/mpd, log to journald, unit drop-in), 95ddab4→2cbeace (deploy.sh REAL_DIRS keeps mpd.service.d real); characterization tests e168bd7 (library kept: 10402 songs), a0f0971 (playlist save), 7ce0eff (mpv.conf parses), each shown failing (mpd stopped, playlists dir removed, bogus option); refactor 382ad58 (ncmpcpp options that repeat 0.10.1 defaults dropped; the owner's visualizer check in L5 ran after it). media.test.sh: 12 ok, all passed; all suites green; test command passes.
- L7 verifier: PASS (refs unchanged, HEAD 382ad58). Notes: the mpv exit-status assertion cannot fail alone (mpv exits 0 on a bad option; the output-regex assertion carries the test); 382ad58 had no pinning test, removed options checked against the shipped defaults.
- Done. Last code commit 382ad58. Risk: item 1, 5, 6 (mpd database/state when restowing; stow packages; playback and hwdec verifiable only live). Follow-ups: YouTube in mpv broken upstream (needs `&range=` per chunk) → /flow:idea; story 10 adds mpd-mpris to bootstrap.sh and keeps the REAL_DIRS entry; ncmpcpp error.log/lyrics still land in the repo (suggestion).
