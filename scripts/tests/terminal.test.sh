#!/usr/bin/env bash
# Integration tests for the terminal stack: kitty + zellij (story 02).
# Runs the real binaries against the stowed dotfiles.
# Usage: scripts/tests/terminal.test.sh [test_name ...]   (no args = all tests)
set -uo pipefail

failures=0

assert_eq() { # name expected actual
    if [[ "$2" == "$3" ]]; then
        printf '  ok   %s\n' "$1"
    else
        printf '  FAIL %s\n       expected: %s\n       actual:   %s\n' "$1" "$2" "$3"
        failures=$((failures + 1))
    fi
}

test_kitty_socket_lives_in_runtime_dir() {
    local listen
    listen=$(kitty +runpy 'import os
from kitty.cli import create_default_opts
print(os.path.expandvars(create_default_opts().listen_on))' 2>/dev/null)
    assert_eq "kitty listens on a per-user runtime socket" \
        "unix:/run/user/$(id -u)/kitty-{kitty_pid}" "$listen"
}

main() {
    local tests=("$@") t
    if ((${#tests[@]} == 0)); then
        mapfile -t tests < <(declare -F | awk '$3 ~ /^test_/ {print $3}')
    fi
    for t in "${tests[@]}"; do
        printf '%s\n' "$t"
        "$t"
    done
    if ((failures)); then
        printf '\n%d failure(s)\n' "$failures"
        exit 1
    fi
    printf '\nall passed\n'
}

main "$@"
