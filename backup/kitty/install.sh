#!/usr/bin/env bash
set -e

CONF="$HOME/Files/Configuraciones"

echo "==> Symlinking kitty config..."
ln -sfn "$CONF/kitty" "$HOME/.config/kitty"

echo "==> Symlinking caelestia template..."
mkdir -p "$HOME/.config/caelestia/templates"
ln -sf "$CONF/caelestia/templates/kitty-theme.conf" "$HOME/.config/caelestia/templates/kitty-theme.conf"

echo "==> Symlinking caelestia reload script..."
mkdir -p "$HOME/.config/caelestia/scripts"
ln -sf "$CONF/caelestia/scripts/kitty-theme-reload.sh" "$HOME/.config/caelestia/scripts/kitty-theme-reload.sh"
chmod +x "$CONF/caelestia/scripts/kitty-theme-reload.sh"

echo "==> Symlinking systemd units..."
mkdir -p "$HOME/.config/systemd/user"
ln -sf "$CONF/systemd/kitty-theme-reload.path"    "$HOME/.config/systemd/user/kitty-theme-reload.path"
ln -sf "$CONF/systemd/kitty-theme-reload.service" "$HOME/.config/systemd/user/kitty-theme-reload.service"

echo "==> Enabling systemd path unit..."
systemctl --user daemon-reload
systemctl --user enable --now kitty-theme-reload.path

echo "==> Generating initial theme from current caelestia scheme..."
if command -v caelestia &>/dev/null; then
    caelestia scheme set \
        --name    "$(caelestia scheme get --name)" \
        --flavour "$(caelestia scheme get --flavour)" \
        --mode    "$(caelestia scheme get --mode)" \
        --variant "$(caelestia scheme get --variant)"
    echo "    Theme generated at ~/.local/state/caelestia/theme/kitty-theme.conf"
else
    echo "    caelestia not found — theme.conf (static fallback) will be used until caelestia is installed."
fi

echo ""
echo "Done. Restart kitty once so it picks up allow_remote_control and listen_on."
