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

test_matugen_renders_vesktop_theme_from_the_palette() {
    # Runs matugen with the repo's config.toml on a known seed in a throwaway
    # HOME (templates linked in, every output written there). The Vencord theme
    # it writes must paint Discord's background, text and accent with the same
    # palette matugen wrote to colors.json in that run.
    local home theme colors expected actual var
    home=$(mktemp -d)
    mkdir -p "$home/.config/matugen" "$home/.config/vesktop"
    ln -s "$DOTFILES/matugen/.config/matugen/templates" "$home/.config/matugen/templates"
    ln -s "$DOTFILES/matugen/.config/matugen/colors.json.template" "$home/.config/matugen/colors.json.template"
    HOME="$home" matugen color hex "#4285f4" --mode dark --quiet \
        --config "$DOTFILES/matugen/.config/matugen/config.toml" >/dev/null 2>&1
    colors="$home/.config/matugen/colors.json"
    theme="$home/.config/vesktop/themes/matugen.theme.css"
    expected=$(python3 -I -c 'import json, sys
c = json.load(open(sys.argv[1]))["colors"]
print(c["background"]["hex"], c["on_surface"]["hex"], c["primary"]["hex"])' "$colors" 2>/dev/null)
    actual=""
    for var in --background-primary --text-normal --brand-500; do
        actual+="$(rg -o --no-filename "^\s*$var:\s*(#[0-9a-fA-F]{6})" -r '$1' "$theme" 2>/dev/null | head -1) "
    done
    rm -rf "$home"
    assert_eq "matugen run yields a palette to compare" "yes" "$([[ $expected == \#* ]] && echo yes || echo no)"
    assert_eq "vesktop theme paints background, text and accent from the palette" \
        "$expected" "${actual% }"
}

test_vesktop_enables_the_matugen_theme() {
    # Vencord applies only the themes listed in enabledThemes; the file name is
    # the one matugen writes into ~/.config/vesktop/themes/.
    local actual
    actual=$(python3 -I -c 'import json, sys
print(" ".join(json.load(open(sys.argv[1]))["enabledThemes"]))' \
        "$DOTFILES/vesktop/.config/vesktop/settings/settings.json" 2>&1)
    assert_eq "vesktop enables the matugen theme" "matugen.theme.css" "$actual"
}

tests=("$@")
if [[ ${#tests[@]} -eq 0 ]]; then
    mapfile -t tests < <(declare -F | awk '$3 ~ /^test_/ {print $3}')
fi
for t in "${tests[@]}"; do
    "$t"
done
[[ $failures -eq 0 ]] && echo "all passed" || { echo "$failures failed"; exit 1; }
