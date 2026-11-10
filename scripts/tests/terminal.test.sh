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

test_post_hook_recolors_kitty_sockets_in_runtime_dir() {
    # Sandbox: temp HOME, and PATH holding only a fake kitten that logs its
    # args, so the rest of the post-hook (gsettings, sudo, hyprctl...) is inert.
    local tmp hook log
    hook="$(git rev-parse --show-toplevel)/dotfiles/matugen/.config/matugen/post-hook.sh"
    tmp=$(mktemp -d)
    mkdir -p "$tmp/bin" "$tmp/run" "$tmp/home/.config/kitty"
    log="$tmp/kitten.log"
    printf '#!/bin/bash\necho "$*" >>%q\n' "$log" >"$tmp/bin/kitten"
    chmod +x "$tmp/bin/kitten"
    : >"$tmp/home/.config/kitty/matugen-theme.conf"
    : >"$tmp/run/kitty-111"
    : >"$tmp/run/kitty-222"
    : >"$tmp/run/kitty-notes"
    : >"$tmp/run/wayland-1"
    env -i HOME="$tmp/home" PATH="$tmp/bin" XDG_RUNTIME_DIR="$tmp/run" \
        /usr/bin/bash "$hook" dark >/dev/null 2>&1
    local theme="$tmp/home/.config/kitty/matugen-theme.conf"
    assert_eq "kitten called once per kitty socket in the runtime dir" \
        "@ --to unix:$tmp/run/kitty-111 set-colors --all $theme
@ --to unix:$tmp/run/kitty-222 set-colors --all $theme" \
        "$(sort "$log" 2>/dev/null)"
    rm -rf "$tmp"
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
