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

test_zellij_theme_components_are_readable() {
    # Renders the real zellij template with matugen for 2 source colors x
    # dark/light. Zellij must accept the theme, and in each of the 14 UI
    # components the text (base, emphasis_0-3) must reach WCAG >= 3:1 against
    # that component's own background (the minimum for UI components).
    local tmp tpl src mode out
    tpl="$(git rev-parse --show-toplevel)/dotfiles/matugen/.config/matugen/templates/zellij-theme.kdl"
    tmp=$(mktemp -d)
    printf '[config]\n[templates.zellij]\ninput_path = "%s"\noutput_path = "%s/theme.kdl"\n' \
        "$tpl" "$tmp" >"$tmp/config.toml"
    for src in '#c2185b' '#2e7d32'; do
        for mode in dark light; do
            matugen color hex "$src" -c "$tmp/config.toml" -m "$mode" \
                -t scheme-content --quiet >/dev/null 2>&1
            { cat "$tmp/theme.kdl"; echo 'theme "matugen"'; } >"$tmp/zellij.kdl"
            assert_eq "$src $mode: zellij accepts the theme" "" \
                "$(zellij --config "$tmp/zellij.kdl" setup --check 2>&1 | rg -i -m1 'error|failed')"
            out=$(python3 -I - "$tmp/theme.kdl" <<'PY'
import re, sys
text = open(sys.argv[1]).read()
comps = {}
for name, body in re.findall(r'^\s*(\w+)\s*\{([^{}]*)\}', text, re.M):
    attrs = {k: tuple(map(int, v)) for k, *v in
             re.findall(r'^\s*(\w+)\s+(\d+)\s+(\d+)\s+(\d+)\s*$', body, re.M)}
    if "background" in attrs:
        comps[name] = attrs
def lum(rgb):
    c = [x / 255 for x in rgb]
    c = [x / 12.92 if x <= 0.03928 else ((x + 0.055) / 1.055) ** 2.4 for x in c]
    return 0.2126 * c[0] + 0.7152 * c[1] + 0.0722 * c[2]
print(len(comps))
for name, a in sorted(comps.items()):
    bg = lum(a["background"])
    for k in ("base", "emphasis_0", "emphasis_1", "emphasis_2", "emphasis_3"):
        l = lum(a.get(k, a["background"]))
        ratio = (max(l, bg) + 0.05) / (min(l, bg) + 0.05)
        if ratio < 3:
            print(f"{name}.{k}={ratio:.2f}")
PY
            )
            assert_eq "$src $mode: 14 components checked" 14 "$(head -n1 <<<"$out")"
            assert_eq "$src $mode: no text below 3:1 against its background" "" \
                "$(tail -n +2 <<<"$out" | paste -sd' ')"
        done
    done
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
