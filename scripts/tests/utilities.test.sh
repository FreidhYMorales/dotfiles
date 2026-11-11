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

test_btop_shows_battery() {
    # On the ThinkPad the CPU box carries the battery meter (BAT0), next to the
    # cpu, mem, net and proc boxes.
    local home out actual="" box
    home=$(btop_home)
    out=$(run_btop "$home" q | sed 's/\x1b\[[0-9;?]*[A-Za-z]//g')
    rm -rf "$home"
    for box in cpu mem net proc BAT; do
        printf '%s' "$out" | rg -q "$box" && actual+="$box "
    done
    assert_eq "btop draws cpu, mem, net, proc and the battery" "cpu mem net proc BAT" "${actual% }"
}

test_btop_package_holds_only_config() {
    # btop uses the matugen theme (generated, gitignored); the package tracks
    # only btop.conf, no unused themes.
    assert_eq "btop package tracks only its config" \
        "dotfiles/btop/.config/btop/btop.conf" \
        "$(git -C "$ROOT" ls-files dotfiles/btop | xargs)"
    assert_eq "btop uses the matugen theme" '"matugen"' \
        "$(rg -o -r '$1' '^color_theme = (.*)$' "$DOTFILES/btop/.config/btop/btop.conf")"
}

FASTFETCH_CONF="$DOTFILES/fastfetch/.config/fastfetch/config.jsonc"

test_fastfetch_logo_resolves() {
    # The kitty logo source must point at the deployed logo folder. Outside a
    # real kitty the image cannot be drawn (no pixel size), but a source that
    # does not exist fails earlier, at resolving it.
    local out
    out=$(fastfetch --config "$FASTFETCH_CONF" --pipe false --show-errors 2>&1 </dev/null)
    assert_eq "fastfetch resolves its logo source" "" \
        "$(printf '%s\n' "$out" | rg -a -o 'Failed to resolve logo source.*')"
}

test_fastfetch_no_empty_fields() {
    # Every "key : value" line has a value with nothing missing at its end;
    # a format field this machine does not report leaves a trailing gap.
    local out
    out=$(fastfetch --config "$FASTFETCH_CONF" --pipe --logo none 2>&1 </dev/null)
    assert_eq "fastfetch prints info lines" "yes" \
        "$( (($(printf '%s\n' "$out" | rg -c ' : ') >= 10)) && echo yes || echo no)"
    assert_eq "fastfetch lines with a missing field" "" \
        "$(printf '%s\n' "$out" | rg ' : (.*\s)?$')"
}

tests=("$@")
if [[ ${#tests[@]} -eq 0 ]]; then
    mapfile -t tests < <(declare -F | awk '$3 ~ /^test_/ {print $3}')
fi
for t in "${tests[@]}"; do
    "$t"
done
[[ $failures -eq 0 ]] && echo "all passed" || { echo "$failures failed"; exit 1; }
