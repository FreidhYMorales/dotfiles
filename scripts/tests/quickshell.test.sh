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
    # gitignore, and no old bar. .atl (local AI state) is not tracked.
    local actual
    actual=$(git -C "$QS" ls-files | awk -F/ '{print $1}' | LC_ALL=C sort -u)
    assert_eq "package ships only the notch config" ".gitignore
notch
notch-repo" "$actual"
    assert_eq "notch config points at the notch shell" "notch-repo/shell" "$(readlink "$QS/notch")"
}

# Lines in the current docs that still point at the old bar or its rollback.
old_bar_refs() { # files...
    rg -n -i -e 'quickshell/default' -e 'notch-cutover' -e 'rollback' -e 'old bar' \
        -e 'modules/(bar|lock|launcher|dashboard|background)' -e 'Reuse map' \
        -e 'RecorderWidget' -e 'Horizontal top flotante' -e 'quickshell-vision' "$@"
}

test_notch_docs_describe_the_notch_as_the_only_shell() {
    # The notch repo's current docs (plans and ADRs are history) name no old
    # bar or rollback, and the cutover/rollback script is gone with its tests.
    local n="$QS/notch-repo" f left=""
    assert_eq "notch docs point at no old bar or rollback" "" \
        "$(cd "$n" && old_bar_refs AGENTS.md docs/development.md docs/architecture.md)"
    for f in scripts/notch-cutover.sh tests/cutover.test.mjs; do
        [[ -e "$n/$f" ]] && left+="$f "
    done
    assert_eq "cutover script and its tests are gone" "" "$left"
    assert_eq "notch development docs run the shell with qs -c notch" "yes" \
        "$(rg -q 'qs -c notch' "$n/docs/development.md" && echo yes || echo no)"
}

test_claude_md_describes_the_notch_as_the_only_shell() {
    # The project CLAUDE.md is read at the start of every session: it must not
    # describe the old bar as the running shell.
    assert_eq "CLAUDE.md points at no old bar or rollback" "" "$(old_bar_refs "$ROOT/CLAUDE.md")"
    assert_eq "CLAUDE.md names qs -c notch as the shell" "yes" \
        "$(rg -q 'qs -c notch' "$ROOT/CLAUDE.md" && echo yes || echo no)"
}

tests=("$@")
if [[ ${#tests[@]} -eq 0 ]]; then
    mapfile -t tests < <(declare -F | awk '$3 ~ /^test_/ {print $3}')
fi
for t in "${tests[@]}"; do
    "$t"
done
[[ $failures -eq 0 ]] && echo "all passed" || { echo "$failures failed"; exit 1; }
