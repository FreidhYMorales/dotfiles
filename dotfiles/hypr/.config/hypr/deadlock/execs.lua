-- Autostart

-- Variables
local exec = hl.exec_cmd

local dbus = "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
local wallpaper = "hyprpaper"
-- polkit-gnome-authentication-agent-1 (GTK, visually mismatched with the
-- rest of the shell) replaced by Quickshell's own native agent
-- (services/Polkit.qml + modules/launcher/PolkitForm.qml, rendered inside
-- the launcher itself) — only one polkit agent can be registered per
-- session, so this one must stay gone for ours to register. See
-- auditorias/autenticacion/README.md §11.
local keyring = "/usr/bin/gnome-keyring-daemon --start --components=secrets"
local cliphistText = "wl-paste --type text --watch cliphist store"
local cliphistImg = "wl-paste --type image --watch cliphist store"
local quickshell = "quickshell"
local term_file_chosser = "/usr/lib/xdg-desktop-portal-termfilechooser"
-- Auto-empties trash items older than 30 days (trash-cli, already in bootstrap.sh)
local trashCleanup = "trash-empty 30"
-- Forwards Bluetooth AVRCP media controls (headphone buttons) to the active
-- MPRIS player (mpd/spotify/etc) — without this, BT media buttons do nothing
local mprisProxy = "mpris-proxy"

hl.on("hyprland.start", function()
	exec(dbus)
	exec(wallpaper)
	exec(keyring)
	exec(cliphistText)
	exec(cliphistImg)
	exec(quickshell)
	exec(term_file_chosser)
	exec(trashCleanup)
	exec(mprisProxy)
end)
