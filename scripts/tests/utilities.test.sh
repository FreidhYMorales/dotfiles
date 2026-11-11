#!/usr/bin/env bash
# Integration tests for the utilities: btop, fastfetch, git, mimeapps, fonts
# (story 07). Reads the repo's packages; btop runs against a copy of its config
# under a throwaway HOME so it never writes into the repo; the live_* tests
# check this machine's installed tools.
# Usage: scripts/tests/utilities.test.sh [test_name ...]   (no args = all tests)
set -uo pipefail

ROOT="$(git rev-parse --show-toplevel)"
DOTFILES="$ROOT/dotfiles"
failures=0

assert_eq() { # name expected actual
    if [[ "$2" == "$3" ]]; then
        printf '  ok   %s\n' "$1"
    else
        printf '  FAIL %s\n       expected: %s\n       actual:   %s\n' "$1" "$2" "$3"
        failures=$((failures + 1))
    fi
}

run_btop() { # home keys... -> btop's screen output; config lives in <home>/.config/btop
    local home=$1 key
    shift
    {
        sleep 3
        for key in "$@"; do
            printf '%s' "$key"
            sleep 1
        done
    } | HOME="$home" XDG_CONFIG_HOME="$home/.config" TERM=xterm-256color \
        timeout 20 script -qec "stty cols 200 rows 50; btop" /dev/null 2>/dev/null
}

btop_home() { # -> a throwaway HOME holding a copy of the repo's btop config
    local home
    home=$(mktemp -d)
    mkdir -p "$home/.config"
    cp -r "$DOTFILES/btop/.config/btop" "$home/.config/btop"
    printf '%s' "$home"
}

test_btop_quit_keeps_config() {
    # btop reaches its config through the folded ~/.config/btop symlink, so
    # anything it writes on quit lands in the repo. Toggling a box and quitting
    # must leave the config exactly as the repo has it.
    local home actual
    home=$(btop_home)
    run_btop "$home" 4 q >/dev/null
    actual=$(diff -q "$DOTFILES/btop/.config/btop/btop.conf" "$home/.config/btop/btop.conf" >/dev/null && echo unchanged || echo rewritten)
    rm -rf "$home"
    assert_eq "btop leaves its config untouched after a change and quit" "unchanged" "$actual"
}

tests=("$@")
if [[ ${#tests[@]} -eq 0 ]]; then
    mapfile -t tests < <(declare -F | awk '$3 ~ /^test_/ {print $3}')
fi
for t in "${tests[@]}"; do
    "$t"
done
[[ $failures -eq 0 ]] && echo "all passed" || { echo "$failures failed"; exit 1; }
