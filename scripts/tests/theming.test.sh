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

test_vesktop_package_holds_only_settings() {
    # Only the settings the owner curates live in the repo. Session data, crash
    # dumps, window state and generated themes stay in the real
    # ~/.config/vesktop, so using Vesktop never shows up as repo changes.
    # Lists what is on disk (ignored files included), not just what git tracks.
    local expected actual
    expected="settings.json
settings/quickCss.css
settings/settings.json"
    actual=$(cd "$DOTFILES/vesktop/.config/vesktop" && fd . --hidden --no-ignore --type f | LC_ALL=C sort)
    assert_eq "vesktop package holds only settings" "$expected" "$actual"
}

test_deploy_keeps_vesktop_config_a_real_directory() {
    # On a fresh HOME, stow would fold ~/.config/vesktop into one symlink to the
    # package, and Vesktop would then write its session data into the repo.
    # deploy.sh must leave a real directory that links only the settings.
    local home actual
    home=$(mktemp -d)
    HOME="$home" "$DOTFILES/deploy.sh" vesktop >/dev/null 2>&1
    # A real directory resolves to itself: no symlinked ancestor (a folded
    # ~/.config would also hide it inside the repo).
    actual="$([[ "$(realpath "$home/.config/vesktop" 2>/dev/null)" == "$(realpath "$home")/.config/vesktop" ]] && echo real-dir || echo not-real-dir)"
    actual+=" $(cd "$home/.config/vesktop" 2>/dev/null && fd . --max-depth 1 --type symlink | LC_ALL=C sort | xargs)"
    rm -rf "$home"
    assert_eq "deploy leaves ~/.config/vesktop a real directory linking only settings" \
        "real-dir settings settings.json" "$actual"
}

tests=("$@")
if [[ ${#tests[@]} -eq 0 ]]; then
    mapfile -t tests < <(declare -F | awk '$3 ~ /^test_/ {print $3}')
fi
for t in "${tests[@]}"; do
    "$t"
done
[[ $failures -eq 0 ]] && echo "all passed" || { echo "$failures failed"; exit 1; }
