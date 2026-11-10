#!/usr/bin/env bash
# Integration tests for the theming pipeline: matugen, vesktop, stylus,
# chromium-extension (story 05). Reads the repo's packages; some tests run
# deploy.sh or matugen against a temporary HOME, one checks the live
# matugen-server.
# Usage: scripts/tests/theming.test.sh [test_name ...]   (no args = all tests)
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

test_unused_theming_packages_are_gone() {
    # Spotify is not used (Spicetify goes with it) and BetterDiscord has no
    # client on this machine (Vesktop runs Vencord): neither package nor its
    # README row remains. The theming packages that stay are still listed.
    local candidates="betterdiscord chromium-extension matugen spicetify stylus vesktop"
    local pkg packages="" rows=""
    for pkg in $candidates; do
        [[ -d "$DOTFILES/$pkg" ]] && packages+="$pkg "
        rg -q "^\| \`$pkg\` \|" "$DOTFILES/README.md" && rows+="$pkg "
    done
    assert_eq "theming packages left in dotfiles/" \
        "chromium-extension matugen stylus vesktop" "${packages% }"
    assert_eq "theming packages listed in dotfiles/README.md" \
        "chromium-extension matugen stylus vesktop" "${rows% }"
}

tests=("$@")
if [[ ${#tests[@]} -eq 0 ]]; then
    mapfile -t tests < <(declare -F | awk '$3 ~ /^test_/ {print $3}')
fi
for t in "${tests[@]}"; do
    "$t"
done
[[ $failures -eq 0 ]] && echo "all passed" || { echo "$failures failed"; exit 1; }
