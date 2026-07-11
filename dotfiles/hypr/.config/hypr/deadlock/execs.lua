-- Autostart

-- Variables
local exec = hl.exec_cmd

local dbus = "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
local wallpaper = "hyprpaper"
local polkit = "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1"
local keyring = "/usr/bin/gnome-keyring-daemon --start --components=secrets"
local cliphistText = "wl-paste --type text --watch cliphist store"
local cliphistImg = "wl-paste --type image --watch cliphist store"
local quickshell = "quickshell"
local term_file_chosser = "/usr/lib/xdg-desktop-portal-termfilechooser"

hl.on("hyprland.start", function()
	exec(dbus)
	exec(wallpaper)
	exec(polkit)
	exec(keyring)
	exec(cliphistText)
	exec(cliphistImg)
	exec(quickshell)
	exec(term_file_chosser)
end)
