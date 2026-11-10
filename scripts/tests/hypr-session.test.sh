#!/usr/bin/env bash
# Integration tests for the Hyprland session: hypr, uwsm, xdg-portal,
# termfilechooser (story 04). Reads the repo's config files; the keybind test
# also checks commands and Quickshell IPC targets against the live session.
# Usage: scripts/tests/hypr-session.test.sh [test_name ...]   (no args = all tests)
set -uo pipefail

ROOT="$(git rev-parse --show-toplevel)"
HYPR="$ROOT/dotfiles/hypr/.config/hypr"
failures=0

assert_eq() { # name expected actual
    if [[ "$2" == "$3" ]]; then
        printf '  ok   %s\n' "$1"
    else
        printf '  FAIL %s\n       expected: %s\n       actual:   %s\n' "$1" "$2" "$3"
        failures=$((failures + 1))
    fi
}

test_hypr_package_holds_only_files_the_session_reads() {
    # hyprland.lua requires monitors.lua and deadlock/init.lua, which requires
    # every deadlock/*.lua (nvidia.lua only on NVIDIA machines); bootstrap.sh
    # seeds the default wallpaper from assets/arch.png. Generated, gitignored
    # files (deadlock/colors.lua, hyprpaper.conf) are not part of the package.
    local expected actual
    expected="assets/arch.png
deadlock/animations.lua
deadlock/decorations.lua
deadlock/env.lua
deadlock/execs.lua
deadlock/general.lua
deadlock/gestures.lua
deadlock/init.lua
deadlock/input.lua
deadlock/keybinds.lua
deadlock/nvidia.lua
deadlock/rule.lua
deadlock/xwayland.lua
hyprland.lua
monitors.lua"
    actual=$(git -C "$HYPR" ls-files --cached --others --exclude-standard | LC_ALL=C sort)
    assert_eq "hypr package holds only files the session reads" "$expected" "$actual"
}

tests=("$@")
if [[ ${#tests[@]} -eq 0 ]]; then
    mapfile -t tests < <(declare -F | awk '$3 ~ /^test_/ {print $3}')
fi
for t in "${tests[@]}"; do
    "$t"
done
[[ $failures -eq 0 ]] && echo "all passed" || { echo "$failures failed"; exit 1; }
