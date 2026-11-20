#!/usr/bin/env bash
# Tests for dotfiles/bootstrap.sh (story 10): what a fresh install sets up,
# read from the script's own install commands. The live_* tests compare it
# with this machine's explicitly installed packages.
# Usage: scripts/tests/bootstrap.test.sh [test_name ...]   (no args = all tests)
set -uo pipefail

ROOT="$(git rev-parse --show-toplevel)"
BOOTSTRAP="${BOOTSTRAP:-$ROOT/dotfiles/bootstrap.sh}"
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

tests=("$@")
if [[ ${#tests[@]} -eq 0 ]]; then
    mapfile -t tests < <(declare -F | awk '$3 ~ /^test_/ {print $3}')
fi
for t in "${tests[@]}"; do
    "$t"
done
[[ $failures -eq 0 ]] && echo "all passed" || { echo "$failures failed"; exit 1; }
