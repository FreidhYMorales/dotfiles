#!/usr/bin/env bash
# Integration tests for the zsh + starship config (story 01).
# Runs real zsh shells in a clean environment against the stowed dotfiles.
# Usage: scripts/tests/shell.test.sh [test_name ...]   (no args = all tests)
set -uo pipefail

FUNCTIONS_DIR="$HOME/.config/zsh/functions"
failures=0

# Clean environment so inherited PATH/vars from the caller don't mask bugs.
zsh_clean() {
    env -i HOME="$HOME" USER="$USER" TERM=xterm-256color \
        PATH=/usr/local/bin:/usr/bin zsh "$@"
}

assert_eq() { # name expected actual
    if [[ "$2" == "$3" ]]; then
        printf '  ok   %s\n' "$1"
    else
        printf '  FAIL %s\n       expected: %s\n       actual:   %s\n' "$1" "$2" "$3"
        failures=$((failures + 1))
    fi
}

test_modules_load_once_and_path_has_no_duplicates() {
    local trace file count
    trace=$(zsh_clean -i -x -c exit 2>&1)
    for file in "$FUNCTIONS_DIR"/*.zsh; do
        count=$(grep -cE "^\+[^ ]*> (source|\.) \"?${file}\"?\$" <<<"$trace")
        assert_eq "$(basename "$file") sourced once" 1 "$count"
    done
    local path_out
    # shellcheck disable=SC2016 # $path expands inside zsh, not bash
    path_out=$(zsh_clean -i -c 'print -l $path' 2>/dev/null)
    assert_eq "HOME/.local/bin appears once in PATH" 1 "$(grep -cx "$HOME/.local/bin" <<<"$path_out")"
    assert_eq "no duplicated PATH entries" "" "$(sort <<<"$path_out" | uniq -d)"
}

main() {
    local tests=("$@")
    if ((${#tests[@]} == 0)); then
        mapfile -t tests < <(declare -F | awk '{print $3}' | grep '^test_')
    fi
    local t
    for t in "${tests[@]}"; do
        printf '%s\n' "$t"
        "$t"
    done
    if ((failures > 0)); then
        printf '\n%d assertion(s) failed\n' "$failures"
        exit 1
    fi
    printf '\nall passed\n'
}

main "$@"
