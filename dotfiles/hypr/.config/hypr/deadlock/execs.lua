-- Autostart

-- Variables
local exec = hl.exec_cmd

-- Every autostart app runs through uwsm, so each one gets its own systemd
-- scope (visible in the journal) and is stopped with the session.
local function app(cmd)
	exec("uwsm app -- " .. cmd)
end

-- Not started here, on purpose:
-- - environment export: uwsm already exports WAYLAND_DISPLAY and
--   XDG_CURRENT_DESKTOP to systemd and D-Bus activation.
-- - gnome-keyring: started by PAM (pam_gnome_keyring auto_start) and
--   D-Bus activatable as org.freedesktop.secrets.
-- - xdg-desktop-portal-termfilechooser: D-Bus activated by the portal.
-- - polkit agent: Quickshell registers its own (only one per session),
--   see auditorias/autenticacion/README.md §11.

-- Use the notch's last saved wallpaper at startup, falling back to the normal
-- hyprpaper configuration until the notch has generated one.
local wallpaper = 'sh -c \'config="${XDG_STATE_HOME:-$HOME/.local/state}/quickshell-notch/hyprpaper.conf"; if [ -f "$config" ]; then exec hyprpaper -c "$config"; else exec hyprpaper; fi\''
local cliphistText = "wl-paste --type text --watch cliphist store"
local cliphistImg = "wl-paste --type image --watch cliphist store"
local quickshell = "qs -c notch"
-- Auto-empties trash items older than 30 days (trash-cli, already in bootstrap.sh)
local trashCleanup = "trash-empty 30"
-- Forwards Bluetooth AVRCP media controls (headphone buttons) to the active
-- MPRIS player (mpd/spotify/etc) — without this, BT media buttons do nothing
local mprisProxy = "mpris-proxy"

hl.on("hyprland.start", function()
	app(wallpaper)
	app(cliphistText)
	app(cliphistImg)
	app(quickshell)
	app(trashCleanup)
	app(mprisProxy)
end)
