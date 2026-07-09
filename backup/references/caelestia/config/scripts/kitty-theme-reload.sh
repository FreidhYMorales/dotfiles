#!/usr/bin/env bash
THEME="$HOME/.local/state/caelestia/theme/kitty-theme.conf"
[[ -f "$THEME" ]] || exit 0
for sock in /tmp/kitty-*; do
    [[ "$sock" =~ ^/tmp/kitty-[0-9]+$ ]] || continue
    kitten @ --to "unix:$sock" set-colors --all "$THEME" 2>/dev/null
done
