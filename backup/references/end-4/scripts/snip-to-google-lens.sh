#!/bin/bash
# Capturar región de pantalla y buscar en Google Lens — end-4/dots-hyprland
# Seleccionás con slurp, sube la imagen a uguu.se (file host temporal), abre Lens.
#
# Deps: grim, slurp, curl, jq, xdg-open
# Hyprland binding: bind = SUPER, G, exec, snip-to-google-lens

grim -g "$(slurp)" /tmp/snip-lens.png
imageLink=$(curl -sF "files[]=@/tmp/snip-lens.png" 'https://uguu.se/upload' | jq -r '.files[0].url')
xdg-open "https://lens.google.com/uploadbyurl?url=${imageLink}"
rm -f /tmp/snip-lens.png
