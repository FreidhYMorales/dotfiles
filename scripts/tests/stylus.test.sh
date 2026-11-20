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

tests=("$@")
[[ ${#tests[@]} -eq 0 ]] && mapfile -t tests < <(declare -F | awk '{print $3}' | grep '^test_')
for t in "${tests[@]}"; do
    echo "$t"
    "$t"
done
[[ $failures -eq 0 ]] && echo "all passed" || { echo "$failures failed"; exit 1; }
