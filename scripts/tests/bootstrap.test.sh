#!/usr/bin/env bash
# Tests for dotfiles/bootstrap.sh (story 10): what a fresh install sets up,
# read from the script's own install commands. The live_* tests compare it
# with this machine's explicitly installed packages.
# Usage: scripts/tests/bootstrap.test.sh [test_name ...]   (no args = all tests)
set -uo pipefail

ROOT="$(git rev-parse --show-toplevel)"
BOOTSTRAP="${BOOTSTRAP:-$ROOT/dotfiles/bootstrap.sh}"
EXCLUDED="${EXCLUDED:-$ROOT/dotfiles/bootstrap-excluded.txt}"
failures=0

assert_eq() { # name expected actual
    if [[ "$2" == "$3" ]]; then
        printf '  ok   %s\n' "$1"
    else
        printf '  FAIL %s\n       expected: %s\n       actual:   %s\n' "$1" "$2" "$3"
        failures=$((failures + 1))
    fi
}

bootstrap_lines() { # -> bootstrap.sh with backslash continuations joined
    awk '{ if (sub(/\\$/, "")) { buf = buf $0 " "; next } print buf $0; buf = "" }' "$BOOTSTRAP"
}

bootstrap_packages() { # -> every package bootstrap.sh installs with pacman or yay, sorted
    bootstrap_lines | grep -oE '(pacman|yay) -S --needed --noconfirm[^|;&]*' |
        sed -E 's/^(pacman|yay) -S --needed --noconfirm//' | tr -s ' ' '\n' | grep -v '^$' | sort -u
}

installs() { # pkg -> yes|no
    bootstrap_packages | grep -qxF -- "$1" && echo yes || echo no
}

runs() { # pattern -> yes|no: a non-comment line of bootstrap.sh matches it
    # grep -c, not grep -q: under pipefail an early-exiting grep -q kills the
    # writer with SIGPIPE and turns a match into "no".
    [[ $(bootstrap_lines | grep -v '^\s*#' | grep -cE -- "$1") -gt 0 ]] && echo yes || echo no
}

test_zsh_plugins_without_omz() {
    # Story 01: .zshrc loads the plugins from /usr/share/zsh/plugins (pacman)
    # and fzf-tab from ~/.local/share/zsh/plugins/fzf-tab.
    local p
    for p in zsh-autosuggestions zsh-syntax-highlighting zsh-completions; do
        assert_eq "bootstrap installs $p from pacman" yes "$(installs "$p")"
    done
    assert_eq "bootstrap clones fzf-tab into ~/.local/share/zsh/plugins/fzf-tab" yes \
        "$(bootstrap_lines | grep -E 'git clone .*Aloxaf/fzf-tab' | grep -q '\.local/share/zsh/plugins/fzf-tab' && echo yes || echo no)"
}

test_removed_things_not_installed() {
    # Stories 01 and 05 removed Oh My Zsh with its powerlevel10k theme and
    # zsh-256color plugin, and Spotify with spicetify.
    local p
    for p in zsh-theme-powerlevel10k spotify spicetify-cli; do
        assert_eq "bootstrap does not install $p" no "$(installs "$p")"
    done
    assert_eq "bootstrap does not run the Oh My Zsh installer" no "$(runs ohmyzsh)"
    assert_eq "bootstrap does not clone zsh-256color" no "$(runs zsh-256color)"
}

test_no_magick_rock() {
    # snacks.image converts images with ImageMagick's `magick` binary; nothing
    # in the nvim config loads the magick Lua rock (that was image.nvim's).
    assert_eq "bootstrap does not install the magick Lua rock" no "$(runs 'luarocks .*install.*magick')"
    assert_eq "bootstrap installs ImageMagick for snacks.image" yes "$(installs imagemagick)"
}

test_pacman_files_database() {
    # Story 01: the command-not-found handler reads pacman's files database,
    # downloaded once at install and kept fresh by its timer.
    assert_eq "bootstrap downloads the pacman files database" yes "$(runs 'pacman -Fy')"
    assert_eq "bootstrap enables pacman-filesdb-refresh.timer" yes \
        "$(runs 'systemctl enable .*pacman-filesdb-refresh\.timer')"
}

test_story_packages_installed() {
    # Story 06: mpd-mpris exposes mpd to playerctl and the shell's media
    # widgets as a user service. Story 07: xdg-terminal-exec opens
    # Terminal=true entries (nvim, yazi) in kitty.
    assert_eq "bootstrap installs mpd-mpris" yes "$(installs mpd-mpris)"
    assert_eq "bootstrap enables the mpd-mpris user service" yes \
        "$(runs 'systemctl --user enable .*mpd-mpris')"
    assert_eq "bootstrap installs xdg-terminal-exec" yes "$(installs xdg-terminal-exec)"
}

excluded_packages() { # -> package names in bootstrap-excluded.txt, sorted
    [[ -f "$EXCLUDED" ]] || return 0
    grep -v '^\s*\(#\|$\)' "$EXCLUDED" | awk '{print $1}' | sort -u
}

test_exclusions_have_reasons() {
    # Each exclusion says why in a trailing comment, and none of them is also
    # installed by bootstrap.sh (that would make the reason a lie).
    local no_reason both
    assert_eq "exclusion list has entries" yes "$([[ -n $(excluded_packages) ]] && echo yes || echo no)"
    no_reason=$(grep -v '^\s*\(#\|$\)' "$EXCLUDED" | grep -v '^\S\+\s\+#\s*\S' | xargs)
    assert_eq "exclusions without a reason" "" "$no_reason"
    both=$(comm -12 <(excluded_packages) <(bootstrap_packages) | xargs)
    assert_eq "exclusions that bootstrap.sh also installs" "" "$both"
}

test_docs_name_only_current_things() {
    # Stories 01, 05 and 08 removed Oh My Zsh (and its p10k prompt), spicetify
    # and get-location: no bootstrap comment, install.sh or dotfiles README
    # may still describe them as part of the setup.
    local stale
    stale=$(grep -ohiE 'oh-my-zsh|\bOMZ\b|p10k|powerlevel10k|spicetify|spotify|get-location' \
        "$BOOTSTRAP" "$ROOT/install.sh" "$ROOT/dotfiles/README.md" | sort -u | xargs)
    assert_eq "removed things still named in bootstrap.sh, install.sh, dotfiles/README.md" "" "$stale"
    # The README's package table lists exactly the Stow packages in dotfiles/.
    assert_eq "dotfiles/README.md package table matches dotfiles/" \
        "$(find "$ROOT/dotfiles" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort | xargs)" \
        "$(grep -oE '^\| `[a-z0-9-]+` \|' "$ROOT/dotfiles/README.md" | tr -d '|` ' | sort -u | xargs)"
}

logind_step_restarts() { # session types... -> yes|no: the logind step restarts systemd-logind
    # Runs bootstrap.sh's own logind step under its strict mode, with loginctl
    # faked to report one session per given type and sudo only logging.
    local dir types=("$@") i out
    dir=$(mktemp -d)
    mkdir -p "$dir/bin" "$dir/repo/system/logind/logind.conf.d"
    touch "$dir/repo/system/logind/logind.conf.d/deadlock.conf"
    {
        echo '#!/usr/bin/env bash'
        echo 'case "$1" in'
        printf '  list-sessions) '
        for i in "${!types[@]}"; do printf 'echo "%d 1000 deadlock seat0 1 user tty1 no -"; ' "$((i + 2))"; done
        echo ';;'
        echo '  show-session) case "$2" in'
        for i in "${!types[@]}"; do printf '    %d) echo %s ;;\n' "$((i + 2))" "${types[$i]}"; done
        echo '  esac ;;'
        echo 'esac'
    } >"$dir/bin/loginctl"
    printf '#!/usr/bin/env bash\necho "$*" >>"%s/sudo.log"\n' "$dir" >"$dir/bin/sudo"
    chmod +x "$dir/bin/loginctl" "$dir/bin/sudo"
    awk '/^step "logind: power button config"/ {on = 1; next} on && /^step / {exit} on' "$BOOTSTRAP" >"$dir/step.sh"
    PATH="$dir/bin:$PATH" REPO_ROOT="$dir/repo" bash -euo pipefail "$dir/step.sh" >/dev/null 2>&1
    out=$(grep -c 'systemctl restart systemd-logind' "$dir/sudo.log" 2>/dev/null)
    rm -rf "$dir"
    [[ ${out:-0} -gt 0 ]] && echo yes || echo no
}

test_rerun_keeps_graphical_session() {
    # Restarting logind under a running desktop drops the user to SDDM; on a
    # fresh install with no graphical session it is safe and applies the conf.
    assert_eq "logind is not restarted with a wayland session and a manager session" no \
        "$(logind_step_restarts wayland unspecified)"
    assert_eq "logind is not restarted with a manager session listed before the wayland one" no \
        "$(logind_step_restarts unspecified wayland)"
    assert_eq "logind is restarted with no graphical session (fresh install)" yes \
        "$(logind_step_restarts tty unspecified)"
}

yazi_step_finishes() { # ya-exit-code -> yes|no: the yazi plugins step lets bootstrap go on
    local dir status
    dir=$(mktemp -d)
    mkdir -p "$dir/bin"
    printf '#!/usr/bin/env bash\nexit %d\n' "$1" >"$dir/bin/ya"
    chmod +x "$dir/bin/ya"
    { awk '/^step "Post-install: yazi plugins"/ {on = 1; next} on && /^step / {exit} on' "$BOOTSTRAP"
      echo 'echo REACHED_NEXT_STEP'; } >"$dir/step.sh"
    status=$(PATH="$dir/bin:$PATH" bash -euo pipefail "$dir/step.sh" 2>/dev/null | tail -1)
    rm -rf "$dir"
    [[ $status == REACHED_NEXT_STEP ]] && echo yes || echo no
}

test_yazi_plugin_failure_does_not_abort() {
    # A failed plugin fetch (network, corrupt cache) must not cut off the
    # post-install steps that follow it (MPD, web apps, Quickshell state).
    assert_eq "bootstrap goes on after ya pkg install fails" yes "$(yazi_step_finishes 1)"
    assert_eq "bootstrap goes on after ya pkg install succeeds" yes "$(yazi_step_finishes 0)"
}

test_live_every_explicit_package_accounted_for() {
    # Every package explicitly installed on this ThinkPad is either installed
    # by bootstrap.sh or listed in bootstrap-excluded.txt with a reason.
    local missing
    missing=$(comm -23 <(pacman -Qqe | sort -u) \
        <(sort -u <(bootstrap_packages) <(excluded_packages)) | xargs)
    assert_eq "explicit packages neither in bootstrap nor excluded" "" "$missing"
}

SDDM_STEP='SDDM: install notch-lock theme'

sddm_sandbox() { # dir -> fake sudo that runs commands with /usr/share, /var/lib and /etc under dir/root
    # Ownership flags are logged but dropped (no root here); everything else
    # really runs, so the notch's own installer copies the theme.
    mkdir -p "$1/bin" "$1/root/usr/share/sddm/themes" "$1/root/var/lib" "$1/home"
    cat >"$1/bin/sudo" <<SUDO
#!/usr/bin/env bash
echo "\$*" >>"$1/sudo.log"
args=()
while [[ \$# -gt 0 ]]; do
    case "\$1" in
        -o|-g) shift 2; continue ;;
    esac
    a="\$1"; a="\${a//\/usr\/share\//$1/root/usr/share/}"; a="\${a//\/var\/lib\//$1/root/var/lib/}"; a="\${a//\/etc\//$1/root/etc/}"
    args+=("\$a"); shift
done
exec "\${args[@]}"
SUDO
    chmod +x "$1/bin/sudo"
}

run_bootstrap_step() { # dir step-title -> runs that bootstrap.sh step in the sandbox, prints the last line
    { awk -v t="step \"$2\"" '$0 == t {on = 1; next} on && /^step / {exit} on' "$BOOTSTRAP"
      echo 'echo REACHED_NEXT_STEP'; } >"$1/step.sh"
    HOME="$1/home" USER=deadlock PATH="$1/bin:$PATH" SCRIPT_DIR="$ROOT/dotfiles" REPO_ROOT="$ROOT" \
        bash -euo pipefail "$1/step.sh" 2>"$1/stderr" | tail -1
}

test_sddm_step_installs_notch_lock() {
    # A fresh install gets the live setup: the notch-lock theme from the notch
    # submodule, its theme.conf.user linked to a shared data dir the user
    # owns and the sddm group reads (setgid, 2750), and the notch told to
    # publish the greeter wallpaper there.
    local dir r
    dir=$(mktemp -d)
    sddm_sandbox "$dir"
    r="$dir/root"
    assert_eq "notch-lock step finishes" REACHED_NEXT_STEP "$(run_bootstrap_step "$dir" "$SDDM_STEP")"
    assert_eq "notch-lock theme installed" yes \
        "$([[ -f $r/usr/share/sddm/themes/notch-lock/Main.qml ]] && echo yes || echo no)"
    assert_eq "theme.conf.user links into the shared data dir" \
        "$r/var/lib/quickshell-notch-sddm/theme.conf.user" \
        "$(readlink "$r/usr/share/sddm/themes/notch-lock/theme.conf.user")"
    assert_eq "shared data dir is setgid and closed to others" 2750 \
        "$(stat -c %a "$r/var/lib/quickshell-notch-sddm" 2>/dev/null)"
    assert_eq "shared data dir is owned by the user, group sddm" yes \
        "$(grep -qE 'install .*-o deadlock -g sddm -m 2750 /var/lib/quickshell-notch-sddm' "$dir/sudo.log" 2>/dev/null && echo yes || echo no)"
    assert_eq "notch publishes the greeter to the shared data dir" /var/lib/quickshell-notch-sddm \
        "$(cat "$dir/home/.local/state/quickshell-notch/sddm-target.txt" 2>/dev/null)"
    rm -rf "$dir"
}

test_sddm_step_rerun_keeps_installed_greeter() {
    # On a re-run the theme and the staged greeter data are already there:
    # the notch's installer refuses to replace a theme, so the step must leave
    # both alone and let bootstrap go on instead of aborting under set -e.
    local dir r
    dir=$(mktemp -d)
    sddm_sandbox "$dir"
    r="$dir/root"
    mkdir -p "$r/usr/share/sddm/themes/notch-lock" "$r/var/lib/quickshell-notch-sddm"
    echo installed >"$r/usr/share/sddm/themes/notch-lock/marker"
    echo 'background=file:///var/lib/quickshell-notch-sddm/background-a' \
        >"$r/var/lib/quickshell-notch-sddm/theme.conf.user"
    assert_eq "re-run finishes the notch-lock step" REACHED_NEXT_STEP "$(run_bootstrap_step "$dir" "$SDDM_STEP")"
    assert_eq "re-run keeps the installed theme" installed \
        "$(cat "$r/usr/share/sddm/themes/notch-lock/marker" 2>/dev/null)"
    assert_eq "re-run keeps the staged greeter config" \
        'background=file:///var/lib/quickshell-notch-sddm/background-a' \
        "$(cat "$r/var/lib/quickshell-notch-sddm/theme.conf.user" 2>/dev/null)"
    rm -rf "$dir"
}

test_repo_sddm_config_selects_notch_lock() {
    # The repo config bootstrap copies to /etc/sddm.conf.d is the one that
    # picks the greeter: notch-lock, with no import path into the silent theme.
    local conf="$ROOT/system/sddm/sddm.conf.d/deadlock.conf"
    assert_eq "repo SDDM config selects notch-lock" "Current=notch-lock" \
        "$(grep -E '^Current=' "$conf")"
    assert_eq "repo SDDM config names no silent theme path" "" \
        "$(grep -n 'themes/silent' "$conf")"
}

test_silent_theme_and_sync_helper_gone() {
    # notch-lock replaced the silent theme (story 19): its files, its root
    # sync helper and the NOPASSWD sudoers entry for it are not shipped or
    # installed any more.
    local left="" f
    for f in system/sddm/themes/silent dotfiles/matugen/.config/matugen/sddm-theme-sync; do
        [[ -e "$ROOT/$f" ]] && left+="$f "
    done
    assert_eq "silent theme and sync helper are not in the repo" "" "$left"
    assert_eq "bootstrap installs no sddm-theme-sync helper" no "$(runs 'sddm-theme-sync')"
    assert_eq "bootstrap writes no sudoers entry" no "$(runs '/etc/sudoers\.d')"
    assert_eq "bootstrap installs no silent theme" no "$(runs 'themes/silent')"
}

STATE_STEP='Post-install: default Quickshell state'

state_step_fresh() { # dir -> runs the default-state step in the sandbox, prints FRESH_WALLPAPER_STATE
    { awk -v t="step \"$STATE_STEP\"" '$0 == t {on = 1; next} on && /^step / {exit} on' "$BOOTSTRAP"
      echo 'echo "$FRESH_WALLPAPER_STATE"'; } >"$1/step.sh"
    HOME="$1/home" PATH="$1/bin:$PATH" bash -euo pipefail "$1/step.sh" 2>"$1/stderr" | tail -1
}

test_fresh_install_seeds_notch_state() {
    # The notch reads its wallpaper and theme mode from its own state dir; a
    # fresh install seeds both there (default wallpaper, content scheme, dark)
    # and nothing in the old Quickshell state dir. A re-run keeps the pick.
    local dir h n
    dir=$(mktemp -d)
    sddm_sandbox "$dir"
    h="$dir/home"
    n="$h/.local/state/quickshell-notch"
    mkdir -p "$h/.config/hypr/assets"
    echo png >"$h/.config/hypr/assets/arch.png"
    assert_eq "fresh install is detected" true "$(state_step_fresh "$dir")"
    assert_eq "notch wallpaper seeded with the default" "$h/Pictures/Wallpaper/arch.png" \
        "$(cat "$n/wallpaper.txt" 2>/dev/null)"
    assert_eq "notch theme seeded dark content scheme" '{"mode":"scheme-content","variant":"dark"}' \
        "$(cat "$n/theme.json" 2>/dev/null)"
    assert_eq "old Quickshell state dir not created" no \
        "$([[ -e $h/.local/state/quickshell ]] && echo yes || echo no)"
    echo "$h/Pictures/Wallpaper/tiger.jpg" >"$n/wallpaper.txt"
    echo '{"mode":"scheme-tonal-spot","variant":"light"}' >"$n/theme.json"
    assert_eq "re-run is not a fresh install" false "$(state_step_fresh "$dir")"
    assert_eq "re-run keeps the picked wallpaper" "$h/Pictures/Wallpaper/tiger.jpg" "$(cat "$n/wallpaper.txt")"
    assert_eq "re-run keeps the picked theme" '{"mode":"scheme-tonal-spot","variant":"light"}' "$(cat "$n/theme.json")"
    rm -rf "$dir"
}

test_docs_describe_the_notch_lock_greeter() {
    # Story 19 replaced the silent theme with notch-lock and moved the
    # first-boot state to the notch: the project docs must not describe the
    # removed theme, its sudo helper or the old shell's wallpaper services.
    local stale
    stale=$(grep -noiE 'silent|sddm-theme-sync|custom\.conf|qs-current|Wallpapers\.qml|ColoursEngine' \
        "$ROOT/CLAUDE.md" "$ROOT/system/sddm/README.md")
    assert_eq "docs name no silent theme, sync helper or old wallpaper services" "" "$stale"
    assert_eq "SDDM README describes notch-lock" yes \
        "$(grep -q 'notch-lock' "$ROOT/system/sddm/README.md" && echo yes || echo no)"
}

test_sddm_step_greeter_config_readable_only_by_sddm() {
    # The greeter reads theme.conf.user through the sddm group; the user (the
    # notch) writes it. Nobody else may read it, and the sddm group may not
    # write it.
    local dir r
    dir=$(mktemp -d)
    sddm_sandbox "$dir"
    r="$dir/root"
    run_bootstrap_step "$dir" "$SDDM_STEP" >/dev/null
    assert_eq "greeter config is 640" 640 \
        "$(stat -c %a "$r/var/lib/quickshell-notch-sddm/theme.conf.user" 2>/dev/null)"
    assert_eq "greeter config is owned by the user, group sddm" yes \
        "$(grep -qE 'install -o deadlock -g sddm -m 640 /dev/null /var/lib/quickshell-notch-sddm/theme.conf.user' "$dir/sudo.log" && echo yes || echo no)"
    rm -rf "$dir"
}

test_reference_docs_describe_the_notch_pipeline() {
    # The repo README and the matugen pipeline reference (a read-first doc in
    # CLAUDE.md) must not describe the removed silent theme, its sudo helper,
    # the old Quickshell state dir or the old shell's theming service.
    local stale
    stale=$(grep -noiE 'silent|sddm-theme-sync|custom\.conf|qs-current|local/state/quickshell/|ColoursEngine' \
        "$ROOT/README.md" "$ROOT/backup/references/matugen-pipeline-reference.md")
    assert_eq "reference docs name no silent theme, sync helper or old shell state" "" "$stale"
    assert_eq "matugen reference describes the notch-lock greeter" yes \
        "$(grep -q 'notch-lock' "$ROOT/backup/references/matugen-pipeline-reference.md" && echo yes || echo no)"
}

root_on_luks_says() { # findmnt-source "lsblk -s types" -> yes|no from bootstrap.sh's root_on_luks
    # findmnt and lsblk are faked: findmnt reports the given root source and
    # lsblk lists the given device types only for the bracket-free device.
    local dir out
    dir=$(mktemp -d)
    mkdir -p "$dir/bin"
    printf '#!/usr/bin/env bash\necho "%s"\n' "$1" >"$dir/bin/findmnt"
    printf '#!/usr/bin/env bash\n[[ "${@: -1}" == "%s" ]] && printf "%%b\\n" "%s"\n' "${1%%\[*}" "$2" >"$dir/bin/lsblk"
    chmod +x "$dir/bin/findmnt" "$dir/bin/lsblk"
    { awk '/^root_on_luks\(\) \{/ {on = 1} on {print} on && /^\}/ {exit}' "$BOOTSTRAP"
      echo 'root_on_luks && echo yes || echo no'; } >"$dir/fn.sh"
    out=$(PATH="$dir/bin:$PATH" bash -euo pipefail "$dir/fn.sh" 2>/dev/null)
    rm -rf "$dir"
    echo "${out:-missing}"
}

test_root_on_luks_detection() {
    # Every encryption-only step (autologin, sd-encrypt, rd.luks) hangs on
    # this answer; a wrong yes would give an unencrypted machine autologin.
    assert_eq "root on a LUKS mapping is encrypted" yes "$(root_on_luks_says /dev/mapper/root 'crypt\npart\ndisk')"
    assert_eq "root on LVM inside LUKS is encrypted" yes "$(root_on_luks_says /dev/mapper/vg-root 'lvm\ncrypt\npart\ndisk')"
    assert_eq "btrfs subvolume on LUKS is encrypted" yes "$(root_on_luks_says '/dev/mapper/root[/@]' 'crypt\npart\ndisk')"
    assert_eq "root on a plain partition is not encrypted" no "$(root_on_luks_says /dev/nvme0n1p5 'part\ndisk')"
}

test_live_root_is_not_on_luks() {
    # This ThinkPad's root is a plain ext4 partition today: the real tools
    # must take the plain path (no autologin).
    local out
    out=$({ awk '/^root_on_luks\(\) \{/ {on = 1} on {print} on && /^\}/ {exit}' "$BOOTSTRAP"
            echo 'root_on_luks && echo yes || echo no'; } | bash -euo pipefail 2>/dev/null)
    assert_eq "this machine takes the plain path" no "${out:-missing}"
}

BOOT_SPLASH_STEP='Boot splash: Plymouth (bgrt) and a systemd initramfs'

luks_sandbox() { # dir yes|no -> sandbox whose root is (or is not) on LUKS, with inert boot tools
    sddm_sandbox "$1"
    mkdir -p "$1/root/etc/default"
    if [[ $2 == yes ]]; then
        printf '#!/usr/bin/env bash\necho /dev/mapper/root\n' >"$1/bin/findmnt"
        printf '#!/usr/bin/env bash\nprintf "crypt\\npart\\ndisk\\n"\n' >"$1/bin/lsblk"
    else
        printf '#!/usr/bin/env bash\necho /dev/nvme0n1p5\n' >"$1/bin/findmnt"
        printf '#!/usr/bin/env bash\nprintf "part\\ndisk\\n"\n' >"$1/bin/lsblk"
    fi
    local tool
    for tool in pacman plymouth-set-default-theme mkinitcpio grub-mkconfig; do
        printf '#!/usr/bin/env bash\nexit 0\n' >"$1/bin/$tool"
    done
    chmod +x "$1"/bin/*
}

run_step_with_detection() { # dir step-title -> like run_bootstrap_step, with root_on_luks defined
    { awk '/^root_on_luks\(\) \{/ {on = 1} on {print} on && /^\}/ {exit}' "$BOOTSTRAP"
      awk -v t="step \"$2\"" '$0 == t {on = 1; next} on && /^step / {exit} on' "$BOOTSTRAP"
      echo 'echo REACHED_NEXT_STEP'; } >"$1/step.sh"
    HOME="$1/home" USER=deadlock PATH="$1/bin:$PATH" SCRIPT_DIR="$ROOT/dotfiles" REPO_ROOT="$ROOT" \
        bash -euo pipefail "$1/step.sh" 2>"$1/stderr" | tail -1
}

boot_splash_result() { # yes|no -> "<last line>|<HOOKS line>|<COMPRESSION line>|<plymouth installed>|<bgrt set>"
    local dir conf
    dir=$(mktemp -d)
    luks_sandbox "$dir" "$1"
    conf="$dir/root/etc/mkinitcpio.conf"
    printf '%s\n' 'MODULES=()' \
        'HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block resume filesystems fsck)' \
        'COMPRESSION="lz4"' >"$conf"
    local last
    last=$(run_step_with_detection "$dir" "$BOOT_SPLASH_STEP")
    printf '%s|%s|%s|%s|%s\n' "$last" "$(grep '^HOOKS=' "$conf")" "$(grep '^COMPRESSION=' "$conf")" \
        "$(grep -qE 'pacman -S .*plymouth' "$dir/sudo.log" 2>/dev/null && echo yes || echo no)" \
        "$(grep -qx 'plymouth-set-default-theme bgrt' "$dir/sudo.log" 2>/dev/null && echo yes || echo no)"
    rm -rf "$dir"
}

test_boot_splash_on_both_paths() {
    # Both installs show the bgrt splash from a systemd initramfs (sd-vconsole
    # keeps the TTY font, systemd handles resume); only a LUKS root adds
    # sd-encrypt, so Plymouth asks the passphrase. Other settings are kept.
    local base='base systemd autodetect microcode modconf kms keyboard sd-vconsole plymouth block'
    assert_eq "LUKS install: bgrt splash, sd-encrypt initramfs" \
        "REACHED_NEXT_STEP|HOOKS=($base sd-encrypt filesystems fsck)|COMPRESSION=\"lz4\"|yes|yes" \
        "$(boot_splash_result yes)"
    assert_eq "plain install: bgrt splash, systemd initramfs without sd-encrypt" \
        "REACHED_NEXT_STEP|HOOKS=($base filesystems fsck)|COMPRESSION=\"lz4\"|yes|yes" \
        "$(boot_splash_result no)"
}

CMDLINE_STEP='GRUB: boot splash and LUKS kernel cmdline'

cmdline_result() { # yes|no -> "<DEFAULT line>|<LINUX line>" after the cmdline step ran twice
    # lsblk -P answers the device chain under /: the crypt mapping "root"
    # on a crypto_LUKS partition (LUKS), or a plain ext4 partition.
    local dir grub
    dir=$(mktemp -d)
    luks_sandbox "$dir" "$1"
    if [[ $1 == yes ]]; then
        cat >"$dir/bin/lsblk" <<'LSBLK'
#!/usr/bin/env bash
if [[ " $* " == *" -sPno "* ]]; then
    echo 'NAME="root" TYPE="crypt" FSTYPE="ext4" UUID="aaaa-root"'
    echo 'NAME="nvme0n1p5" TYPE="part" FSTYPE="crypto_LUKS" UUID="1111-luks"'
    echo 'NAME="nvme0n1" TYPE="disk" FSTYPE="" UUID=""'
else
    printf 'crypt\npart\ndisk\n'
fi
LSBLK
    fi
    grub="$dir/root/etc/default/grub"
    printf '%s\n' 'GRUB_DEFAULT=0' \
        'GRUB_CMDLINE_LINUX_DEFAULT="quiet loglevel=3 nowatchdog resume=UUID=5555-swap"' \
        'GRUB_CMDLINE_LINUX=""' >"$grub"
    run_step_with_detection "$dir" "$CMDLINE_STEP" >/dev/null
    run_step_with_detection "$dir" "$CMDLINE_STEP" >/dev/null
    printf '%s|%s\n' "$(grep '^GRUB_CMDLINE_LINUX_DEFAULT=' "$grub")" \
        "$(grep '^GRUB_CMDLINE_LINUX=' "$grub" | tr -s ' ' | sd '=" ' '="')"
    rm -rf "$dir"
}

test_kernel_cmdline_on_both_paths() {
    # Both installs boot with the splash; only a LUKS root names its LUKS
    # device and mapping for sd-encrypt. A re-run adds nothing twice.
    local default='GRUB_CMDLINE_LINUX_DEFAULT="quiet loglevel=3 nowatchdog resume=UUID=5555-swap splash"'
    assert_eq "LUKS install: splash plus the LUKS device and mapping" \
        "$default|GRUB_CMDLINE_LINUX=\"rd.luks.name=1111-luks=root\"" "$(cmdline_result yes)"
    assert_eq "plain install: splash only" \
        "$default|GRUB_CMDLINE_LINUX=\"\"" "$(cmdline_result no)"
}

LOGIN_STEP='Login: SDDM autologin on a LUKS root'

luks_login_result() { # yes|no -> one line per installed piece, "-" when absent
    local dir r conf pam dropin
    dir=$(mktemp -d)
    luks_sandbox "$dir" "$1"
    r="$dir/root"
    run_step_with_detection "$dir" "$LOGIN_STEP" >"$dir/last"
    conf="$r/etc/sddm.conf.d/luks-autologin.conf"
    pam="$r/etc/pam.d/sddm-autologin"
    dropin="$r/etc/systemd/system/sddm.service.d/luks.conf"
    echo "step: $(cat "$dir/last")"
    echo "autologin: $( [[ -f $conf ]] && grep -E '^(User|Session|Relogin)=' "$conf" | xargs || echo -)"
    echo "keyring auth: $( [[ -f $pam ]] && awk '$1 ~ /auth/ && /pam_(systemd_loadkey|gnome_keyring)/ {print $3}' "$pam" | xargs || echo -)"
    echo "sddm.service: $( [[ -f $dropin ]] && grep -E '^(KeyringMode|ExecStartPre)=' "$dropin" | xargs || echo -)"
    rm -rf "$dir"
}

test_luks_login_only_on_luks() {
    # A LUKS root logs in once per boot with no greeter (Relogin=false keeps
    # the logout greeter), the keyring unlocked from the LUKS passphrase
    # (pam_systemd_loadkey before pam_gnome_keyring, SDDM allowed to read
    # root's keyring) and Plymouth's last frame kept until the session paints.
    # A plain root gets none of it: autologin there would be no login at all.
    assert_eq "LUKS install: autologin, keyring unlock, retained splash" \
        "step: REACHED_NEXT_STEP
autologin: User=deadlock Session=hyprland-uwsm.desktop Relogin=false
keyring auth: pam_systemd_loadkey.so pam_gnome_keyring.so
sddm.service: KeyringMode=inherit ExecStartPre=-/usr/bin/plymouth quit --retain-splash" \
        "$(luks_login_result yes)"
    assert_eq "plain install: no autologin pieces" \
        "step: REACHED_NEXT_STEP
autologin: -
keyring auth: -
sddm.service: -" \
        "$(luks_login_result no)"
}

test_docs_describe_both_login_paths() {
    # Story 20: bootstrap sets up the bgrt splash on every install and SDDM
    # autologin only on a LUKS root. CLAUDE.md and the login plan say so; the
    # plan no longer promises a notch-themed splash that does not exist.
    local claude="$ROOT/CLAUDE.md" plan="$ROOT/docs/plans/dotfiles-audit/login-reinstall-plan.md"
    assert_eq "CLAUDE.md names the bgrt splash and the LUKS-only autologin" "yes yes" \
        "$(rg -q 'bgrt' "$claude" && echo yes || echo no) $(rg -q 'luks-autologin\.conf' "$claude" && echo yes || echo no)"
    assert_eq "login plan uses bgrt and names the plain path" "yes yes" \
        "$(rg -q 'bgrt' "$plan" && echo yes || echo no) $(rg -qi 'without LUKS' "$plan" && echo yes || echo no)"
    assert_eq "login plan promises no notch-themed splash" "" \
        "$(rg -n 'theme with the notch image' "$plan")"
}

tests=("$@")
if [[ ${#tests[@]} -eq 0 ]]; then
    mapfile -t tests < <(declare -F | awk '$3 ~ /^test_/ {print $3}')
fi
for t in "${tests[@]}"; do
    "$t"
done
[[ $failures -eq 0 ]] && echo "all passed" || { echo "$failures failed"; exit 1; }
