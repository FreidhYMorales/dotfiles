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

test_live_every_explicit_package_accounted_for() {
    # Every package explicitly installed on this ThinkPad is either installed
    # by bootstrap.sh or listed in bootstrap-excluded.txt with a reason.
    local missing
    missing=$(comm -23 <(pacman -Qqe | sort -u) \
        <(sort -u <(bootstrap_packages) <(excluded_packages)) | xargs)
    assert_eq "explicit packages neither in bootstrap nor excluded" "" "$missing"
}

tests=("$@")
if [[ ${#tests[@]} -eq 0 ]]; then
    mapfile -t tests < <(declare -F | awk '$3 ~ /^test_/ {print $3}')
fi
for t in "${tests[@]}"; do
    "$t"
done
[[ $failures -eq 0 ]] && echo "all passed" || { echo "$failures failed"; exit 1; }
