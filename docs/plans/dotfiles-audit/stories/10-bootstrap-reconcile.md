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
- L4 test list approved ("si"): 1 zsh plugins without OMZ, 2 removed things not installed, 3 pacman files database, 4 mpd-mpris + xdg-terminal-exec, 5 live: every explicit package in bootstrap or excluded, 6 exclusions have reasons, 7 docs name only current things, 8 manual re-run of bootstrap.sh --no-grub. Real count of explicit packages missing was 81 (86 once base/linux/sudo/mkinitcpio/yay/tree/p10k counted), not 72 (that count matched words in comments).
- L5 triage (owner, five batches): bootstrap gains intel-ucode (own step, GenuineIntel only), dosfstools exfatprogs ntfsprogs gptfdisk man-db tree wget unrar wireless-regdb alsa-utils, dev tools (shellcheck shfmt actionlint gitleaks act trivy osv-scanner mise typst ast-grep go-yq; restic rclone socat for engram-backup and pi-box), cfr mingw-w64-gcc (cybersecurity), a virtualization step (libvirt qemu-desktop virt-manager dnsmasq freerdp tigervnc anydesk-bin, libvirtd + libvirt group), a devices step (android-tools arduino-cli arduino-ide-bin), coin-or-mp (LibreOffice solver), lib32-vulkan-intel vulkan-tools (Intel GPU step), nvtop, cava, gimp. Excluded (dotfiles/bootstrap-excluded.txt): base linux linux-firmware mkinitcpio sudo yay ollama-vulkan (story 11). Owner uninstalled the rest ("los ? desinstalalos", "el resto ? se va"): acpid age anylogic-ple bottles btrfs-progs cage dbeaver disktui dolphin git-filter-repo greetd heimdall kicad kicad-library kicad-library-3d libretro-mame libretro-mesen logisim-evolution packer pmbootstrap pyside6 retroarch vagrant webkit2gtk-4.1 wine-mono xdg-desktop-portal-wlr zsh-theme-powerlevel10k (50 orphaned deps went with them).
- L6 pair finding (manual re-run): the re-run dropped the desktop to SDDM right after the TPM2 step, twice. The logind step's "graphical session active" guard ended in `| grep -qE`; under pipefail the SIGPIPE on the next session's line turned a match into "no session", so it restarted systemd-logind live. Same SIGPIPE trap hit the test helpers earlier (fixed before their red commit with `grep -c`). The first run ended in a hard power-off (journal cut at 11:07:16) that left zero-length files: yazi package cache and its 17 ya-installed plugins, 4 webapp .desktop files and icons; repaired live (cache wiped + `ya pkg install --discard`; empty files removed + `webapp-restore`), repo clean (git fsck), /etc/sudoers.d/sddm-theme-sync intact (61 bytes). Owner approved ("si") two more fixes for criterion 3: drop the unused magick Lua rock step (snacks.image uses the ImageMagick binary) and let a failed `ya pkg install` warn instead of aborting.
- L7 pair: red→green 2af2d34→a2fae19 (zsh plugins from pacman, fzf-tab clone), 530bb79→2228f20 (OMZ, p10k, spotify, spicetify dropped), 8232aa2→6c31ca5 (pacman -Fy + filesdb timer), 0322ef1→dbefd56 (mpd-mpris + user unit, xdg-terminal-exec), d7e8c0d→14447a0 (triage: every explicit package installed or excluded), 712751b→2885e37 (stale OMZ/p10k/get-location docs, README zellij row), 61c8ef7→c69bde9 (no live logind restart under a graphical session; red 3/3 with wayland listed first), 05e1716→f8417d0 (magick rock step dropped), 55ceff6→551c424 (yazi plugin failure warns); characterization fcb8082 (exclusion reasons, shown failing on a copy with a reasonless entry and an excluded bootstrap package, and on an empty copy). 6b95df2 cleans CLAUDE.md (OMZ, spicetify, magick rock, sleep hook described as current). bootstrap.test.sh: 27 ok, all passed; test command passes; every suite green except hypr-session, which fails only in the working tree on the two untracked nwg-displays files (passes on a clean worktree at 2885e37).
- L8 manual check (owner: "llegó a Bootstrap complete sin cerrar sesión"): `bootstrap.sh --no-grub` re-run on this ThinkPad finished, the logind step printed the "sesión gráfica activa detectada" skip, the log has no errors and no zero-length files appeared.
