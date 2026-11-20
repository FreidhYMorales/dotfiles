#!/usr/bin/env bash
# Tests for the Stylus userstyles of the webapps (story 15): text stays
# readable on every matugen scheme, and the styles reach every stock color.
# Readability is measured: each style's surface/text tokens are resolved to
# --mat-* roles, the roles to real colors from matugen --dry-run for all nine
# schemes (dark mode, the current wallpaper), and the WCAG contrast must be
# at least 4.5:1 (AA for body text).
# Usage: scripts/tests/stylus.test.sh [test_name ...]   (no args = all tests)
set -uo pipefail

ROOT="$(git rev-parse --show-toplevel)"
STYLUS="${STYLUS:-$ROOT/dotfiles/stylus}"
WALLPAPER="${WALLPAPER:-$HOME/Pictures/Wallpaper/arch.png}"
SCHEMES="content expressive fidelity fruit-salad monochrome neutral rainbow tonal-spot vibrant"
PALETTES="$(mktemp -d)"
trap 'rm -rf "$PALETTES"' EXIT
failures=0

assert_eq() { # name expected actual
    if [[ "$2" == "$3" ]]; then
        printf '  ok   %s\n' "$1"
    else
        printf '  FAIL %s\n       expected: %s\n       actual:   %s\n' "$1" "$2" "$3"
        failures=$((failures + 1))
    fi
}

palettes() { # -> one matugen JSON per scheme in $PALETTES (made once per run)
    local s
    [[ -n $(find "$PALETTES" -name '*.json' -print -quit) ]] && return
    for s in $SCHEMES; do
        timeout 30 matugen image "$WALLPAPER" --type "scheme-$s" --mode dark \
            --source-color-index 0 --dry-run --json hex >"$PALETTES/$s.json" 2>/dev/null
    done
}

unreadable() { # style "surface-token text-token" ... -> "none" or the pairs/schemes under 4.5:1
    palettes
    python3 -I - "$PALETTES" "$STYLUS/$1" "${@:2}" <<'EOF'
import glob, json, os, re, sys

palettes, style, pairs = sys.argv[1], open(sys.argv[2]).read(), sys.argv[3:]

def declared(token):
    m = re.search(r'(?<![\w-])' + re.escape(token) + r'\s*:\s*([^;]+);', style)
    return m.group(1).replace('!important', '').strip() if m else None

def rgb(value, colors):
    v = value.strip()
    m = re.fullmatch(r'var\(--mat-([\w-]+)\)', v)
    if m:
        h = colors[m.group(1).replace('-', '_')]['dark']['color'].lstrip('#')
        return [int(h[i:i + 2], 16) for i in (0, 2, 4)]
    m = re.fullmatch(r'color-mix\(in srgb,\s*(var\([^)]*\))\s*(\d+)%\s*,\s*(var\([^)]*\))\s*\)', v)
    if m:
        a, p, b = rgb(m.group(1), colors), int(m.group(2)) / 100, rgb(m.group(3), colors)
        return [round(x * p + y * (1 - p)) for x, y in zip(a, b)]
    raise ValueError('cannot resolve ' + v)

def lum(c):
    c = [x / 255 for x in c]
    c = [x / 12.92 if x <= 0.03928 else ((x + 0.055) / 1.055) ** 2.4 for x in c]
    return 0.2126 * c[0] + 0.7152 * c[1] + 0.0722 * c[2]

bad = []
for pair in pairs:
    surface, text = pair.split()
    sv, tv = declared(surface), declared(text)
    if sv is None or tv is None:
        bad.append(f'{surface}/{text}:undeclared')
        continue
    for f in sorted(glob.glob(os.path.join(palettes, '*.json'))):
        colors = json.load(open(f))['colors']
        hi, lo = sorted([lum(rgb(sv, colors)), lum(rgb(tv, colors))], reverse=True)
        ratio = (hi + 0.05) / (lo + 0.05)
        if ratio < 4.5:
            bad.append(f'{surface}/{text}@{os.path.basename(f)[:-5]}={ratio:.2f}')
print(' '.join(bad) or 'none')
EOF
}

test_whatsapp_bubbles_readable() {
    # The owner's screenshot: on the mono theme the outgoing bubble was light
    # gray under light gray text. Message text is --WDS-content-default.
    assert_eq "matugen gives all nine palettes" 9 "$(palettes; find "$PALETTES" -name '*.json' -size +1k | wc -l)"
    assert_eq "outgoing and incoming bubble text reads at 4.5:1 on every scheme" none \
        "$(unreadable whatsapp-matugen.user.css \
            '--WDS-systems-bubble-surface-outgoing --WDS-content-default' \
            '--WDS-systems-bubble-surface-incoming --WDS-content-default')"
}

test_notion_selection_readable() {
    # Selected blocks and rows keep the default text color on --bg-selected.
    assert_eq "selected text reads at 4.5:1 on every scheme" none \
        "$(unreadable notion-matugen.user.css '--bg-selected --fg-default')"
}

test_github_youtube_pairs_readable() {
    # These two already pair each filled surface with its on-* role; pin it.
    assert_eq "github primary and danger buttons read at 4.5:1 on every scheme" none \
        "$(unreadable github-matugen.user.css \
            '--button-primary-bgColor-rest --button-primary-fgColor-rest' \
            '--button-danger-bgColor-rest --button-danger-fgColor-rest')"
    assert_eq "youtube primary and selected-chip colors read at 4.5:1 on every scheme" none \
        "$(unreadable youtube-matugen.user.css \
            '--yt-sys-color-baseline--primary --yt-sys-color-baseline--on-primary' \
            '--yt-sys-color-baseline--primary-container --yt-sys-color-baseline--on-primary-container')"
}

TEMPLATE="${TEMPLATE:-$ROOT/dotfiles/matugen/.config/matugen/templates/userContent.css}"

rgb_of() { # rendered-file role -> "r, g, b" from its hex line, then "|" and its -rgb line
    local hex
    hex=$(grep -oP -- "--mat-$2:\s*#\K[0-9a-fA-F]{6}" "$1")
    printf '%d, %d, %d|%s' "0x${hex:0:2}" "0x${hex:2:2}" "0x${hex:4:2}" \
        "$(grep -oP -- "--mat-$2-rgb:\s*\K[0-9, ]+(?=;)" "$1")"
}

test_template_renders_rgb_triplets() {
    # WhatsApp builds gradients from rgba(var(--WDS-*-RGB), a): the palette
    # must also come as "r, g, b" triplets, equal to the hex of the same role.
    local dir got want
    dir=$(mktemp -d)
    printf '[config]\n[templates.t]\ninput_path = "%s"\noutput_path = "%s/out.css"\n' "$TEMPLATE" "$dir" >"$dir/c.toml"
    timeout 30 matugen -c "$dir/c.toml" image "$WALLPAPER" --type scheme-content --mode dark \
        --source-color-index 0 >/dev/null 2>&1
    for role in secondary-container surface-container; do
        got=$(rgb_of "$dir/out.css" "$role")
        want=${got%%|*}
        assert_eq "--mat-$role-rgb equals --mat-$role" "$want" "${got#*|}"
    done
    rm -rf "$dir"
}

test_whatsapp_rgb_twins_follow_bubbles() {
    # The message chevron's fade uses the -RGB twin of the bubble color; it
    # stayed stock green because only the hex was overridden. Each twin must
    # name the same palette role as its bubble.
    local f="$STYLUS/whatsapp-matugen.user.css" b role
    for b in outgoing incoming; do
        role=$(grep -oP -- "--WDS-systems-bubble-surface-$b:\s*var\(--mat-\K[\w-]+(?=\))" "$f")
        assert_eq "$b bubble -RGB twin follows its color" "var(--mat-$role-rgb)" \
            "$(grep -oP -- "--WDS-systems-bubble-surface-$b-RGB:\s*\Kvar\([^)]*\)" "$f" || echo missing)"
    done
}

WEBAPP_STYLES="github whatsapp notion youtube"

test_styles_palette_only_and_chromium() {
    # Stylus runs in the Chromium webapps (story 05), with the vars injected by
    # the matugen-vars extension; a hard-coded color never follows the wallpaper.
    local s f hard zen chromium
    for s in $WEBAPP_STYLES; do
        f="$STYLUS/$s-matugen.user.css"
        hard=$(grep -v '^\s*/\?\*' "$f" | grep -cE '#[0-9a-fA-F]{3,8}\b|rgba?\([0-9]')
        zen=$(grep -ciE '\bzen\b|userContent' "$f")
        chromium=$(grep -ci 'chromium' "$f")
        assert_eq "$s: no hard-coded colors" 0 "$hard"
        assert_eq "$s: instructions do not mention Zen or userContent.css" 0 "$zen"
        assert_eq "$s: instructions name Chromium" yes "$( ((chromium > 0)) && echo yes || echo no)"
    done
}

POST_INSTALL="${POST_INSTALL:-$ROOT/backup/references/post-install.md}"

test_install_steps_use_file_url() {
    # Owner, live: Stylus Manage -> Import did not update installed styles;
    # opening the file:// URL in Chromium and pressing Install/Reinstall did.
    local section s
    section=$(awk '/^## 6\. Chromium/ {on = 1; print; next} on && /^## / {exit} on' "$POST_INSTALL")
    assert_eq "post-install Chromium section exists" yes "$([[ -n $section ]] && echo yes || echo no)"
    assert_eq "Chromium section installs styles from a file:// URL" yes \
        "$(grep -q 'file://' <<<"$section" && echo yes || echo no)"
    assert_eq "Chromium section says to press Reinstall to update" yes \
        "$(grep -qi 'reinstall' <<<"$section" && echo yes || echo no)"
    assert_eq "Chromium section no longer uses Manage -> Import" 0 "$(grep -c 'Manage → Import' <<<"$section")"
    for s in $WEBAPP_STYLES; do
        assert_eq "$s: how-to does not say Import" 0 "$(grep -ciw 'import' "$STYLUS/$s-matugen.user.css")"
    done
}

tests=("$@")
[[ ${#tests[@]} -eq 0 ]] && mapfile -t tests < <(declare -F | awk '{print $3}' | grep '^test_')
for t in "${tests[@]}"; do
    echo "$t"
    "$t"
done
[[ $failures -eq 0 ]] && echo "all passed" || { echo "$failures failed"; exit 1; }
