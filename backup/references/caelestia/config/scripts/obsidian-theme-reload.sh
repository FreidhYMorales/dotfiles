#!/usr/bin/env bash
# Sincroniza temas caelestia con Obsidian y Notion en cada cambio de esquema.
# Llamado via postHook en ~/.config/caelestia/cli.json

ZEN_CHROME="$HOME/.config/zen/n9raehyd.deadlock/chrome"

# ── Obsidian ────────────────────────────────────────────────────────
SRC_OBSIDIAN="$HOME/.local/state/caelestia/theme/obsidian-theme.css"
SRC_MANIFEST="$HOME/Files/Configuraciones/caelestia/obsidian-manifest.json"

if [[ -f "$SRC_OBSIDIAN" ]]; then
    VAULTS=(
        "$HOME/Files/Documents/UNIVERSIDAD"
        "$HOME/Files/Documents/CERTIFICADOS Y OTROS/CIBERSEGURIDAD/Cursos/Junior Cybersecurity Analyst(HackTheBox)"
    )
    for vault in "${VAULTS[@]}"; do
        dest="$vault/.obsidian/themes/Caelestia"
        mkdir -p "$dest"
        cp "$SRC_OBSIDIAN" "$dest/theme.css"
        [[ -f "$SRC_MANIFEST" ]] && cp "$SRC_MANIFEST" "$dest/manifest.json"
    done
fi

# ── Notion (zen-browser) ────────────────────────────────────────────
SRC_NOTION="$HOME/.local/state/caelestia/theme/notion-theme.css"

if [[ -f "$SRC_NOTION" ]] && [[ -d "$ZEN_CHROME" ]]; then
    cp "$SRC_NOTION" "$ZEN_CHROME/zen-notion.css"
fi
