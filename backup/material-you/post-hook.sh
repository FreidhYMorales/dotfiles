#!/bin/bash
# Post-hook de cambio de tema/wallpaper — stub para Material You.
# Este script se llama automáticamente cuando cambia el wallpaper o el esquema.
# El sistema de colores (matugen, materialyoucolor, pywal) llama este hook
# y expone los colores como variables de entorno.
#
# Variables disponibles (según la herramienta que uses):
#
#   Con Caelestia CLI:
#     SCHEME_NAME       — nombre del esquema (ej. "dynamic", "catppuccin")
#     SCHEME_FLAVOUR    — variante del esquema
#     SCHEME_MODE       — "dark" | "light"
#     SCHEME_VARIANT    — variante material (tonal_spot, expressive, etc.)
#     SCHEME_COLOURS    — JSON con todos los colores en hex (sin #)
#
#   Con matugen (alternativa popular en Rust):
#     Los colores se propagan vía templates, no via hook env vars.
#     Ver: https://github.com/InioX/matugen
#
#   Con pywal:
#     WAL_COLORS / ~/.cache/wal/colors.json
#
# Este stub extiende lo que hace el sistema de colores con acciones propias.
# Editá o eliminá las secciones que no usés.

set -euo pipefail

# Ejemplo: reiniciar waybar para que tome los nuevos colores
# pkill -USR2 waybar 2>/dev/null || true

# Ejemplo: aplicar colores a Zen Browser via userContent.css
# if [[ -n "${SCHEME_COLOURS:-}" ]]; then
#   primary=$(echo "$SCHEME_COLOURS" | jq -r '.primary')
#   surface=$(echo "$SCHEME_COLOURS" | jq -r '.surface')
#   ZEN_PROFILE="$HOME/.config/zen/$(ls ~/.config/zen/ | grep default | head -1)"
#   cat > "$ZEN_PROFILE/chrome/colours.css" <<EOF
# :root {
#   --accent-color: #$primary;
#   --background: #$surface;
# }
# EOF
# fi

# Ejemplo: aplicar a kitty via escape sequences (sin reiniciar)
# if [[ -n "${SCHEME_COLOURS:-}" ]]; then
#   bg=$(echo "$SCHEME_COLOURS" | jq -r '.surface')
#   fg=$(echo "$SCHEME_COLOURS" | jq -r '.onSurface')
#   kitty @ set-colors --all "background=#$bg" "foreground=#$fg" 2>/dev/null || true
# fi

# Placeholder: loggear qué recibimos
echo "Theme changed: mode=${SCHEME_MODE:-unknown} wallpaper=${WALLPAPER_PATH:-unknown}" \
  >> "${XDG_STATE_HOME:-$HOME/.local/state}/theme-changes.log"
