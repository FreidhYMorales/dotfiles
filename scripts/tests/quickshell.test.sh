#!/usr/bin/env bash
# Structural tests for the quickshell stow package (story 18): the notch is the
# only shell the package ships.
# Usage: scripts/tests/quickshell.test.sh [test_name ...]   (no args = all tests)
set -uo pipefail

ROOT="$(git rev-parse --show-toplevel)"
QS="$ROOT/dotfiles/quickshell/.config/quickshell"
failures=0

assert_eq() { # name expected actual
    if [[ "$2" == "$3" ]]; then
        printf '  ok   %s\n' "$1"
    else
        printf '  FAIL %s\n       expected: %s\n       actual:   %s\n' "$1" "$2" "$3"
        failures=$((failures + 1))
    fi
}

test_package_ships_only_the_notch_config() {
    # Quickshell registers every directory under ~/.config/quickshell as a
    # config: the package holds the notch link, its submodule and the
    # gitignore (.atl is local AI state), and no old bar.
    local actual
    actual=$(git -C "$QS" ls-files | awk -F/ '{print $1}' | LC_ALL=C sort -u)
    assert_eq "package ships only the notch config" ".atl
.gitignore
notch
notch-repo" "$actual"
    assert_eq "notch config points at the notch shell" "notch-repo/shell" "$(readlink "$QS/notch")"
}

tests=("$@")
if [[ ${#tests[@]} -eq 0 ]]; then
    mapfile -t tests < <(declare -F | awk '$3 ~ /^test_/ {print $3}')
fi
for t in "${tests[@]}"; do
    "$t"
done
[[ $failures -eq 0 ]] && echo "all passed" || { echo "$failures failed"; exit 1; }
