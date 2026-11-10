-- Keybinds Configs

-- Variables
-- Global
local keybind = hl.bind
local exec = hl.dsp.exec_cmd
local close = hl.dsp.window.close()

-- Configurations
local mainMod = "SUPER"

-- Programs
local terminal = "kitty"
local browser = "zen-browser"
local fileManager = "kitty -e yazi"

-- Volume
local raiseVolume = "wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"
local lowerVolume = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
local mute = "mute-toggle output"
local micMute = "mute-toggle input"

-- LCD Brightness
local brightUp = "brightnessctl -e4 -n2 set 5%+"
local brightDown = "brightnessctl -e4 -n2 set 5%-"

-- Flags
local lockRep = { locked = true, repeating = true }
local repeating = { repeating = true }

-- Functions
local function descrip(desc)
	return { description = desc }
end

local function focus(direction)
	return hl.dsp.focus({ direction = direction })
end

local function movewindow(direction)
	return hl.dsp.window.move({ direction = direction })
end

local function fullscreen(mode, action)
	return hl.dsp.window.fullscreen({ mode = mode, action = action })
end

local function resize(x, y)
	return hl.dsp.window.resize({ x = x, y = y, relative = true })
end

-- Quickshell panels
local qsIpc = "qs -c notch ipc call"

-- Keybinds
-- Applications
keybind(mainMod .. " + RETURN", exec(terminal), descrip("Open Terminal"))
keybind(mainMod .. " + B", exec("launch-or-focus zen " .. browser), descrip("Open or focus Browser"))
keybind(mainMod .. " + E", exec(fileManager), descrip("Open File Manager"))

-- Window
-- Behaviore
keybind(mainMod .. " + F", fullscreen("fullscreen", "toggle"), descrip("Toggle Fullscreen Window"))
keybind(mainMod .. " + M", fullscreen("maximized", "toggle"), descrip("Toggle Maximize Window"))
keybind(mainMod .. " + T", hl.dsp.window.float({ action = "toggle" }), descrip("Toggle Floating"))

-- Resize
keybind(
	mainMod .. " + SHIFT + right",
	resize(100, 0),
	{ repeating = true, description = "Increase window width with keyboard" }
)
keybind(
	mainMod .. " + SHIFT + left",
	resize(-100, 0),
	{ repeating = true, description = "Reduce window width with keyboard" }
)
keybind(
	mainMod .. " + SHIFT + down",
	resize(0, 100),
	{ repeating = true, description = "Increase window height with keyboard" }
)
keybind(
	mainMod .. " + SHIFT + up",
	resize(0, -100),
	{ repeating = true, description = "Reduce window height with keyboard" }
)

-- Movement
-- Move focus with mainMod + arrow keys
keybind(mainMod .. " + left", focus("left"), descrip("Move focus left"))
keybind(mainMod .. " + right", focus("right"), descrip("Move focus right"))
keybind(mainMod .. " + up", focus("up"), descrip("Move focus up"))
keybind(mainMod .. " + down", focus("down"), descrip("Move focus down"))

-- Move window with mainMod + CTRL + arrow keys
keybind(mainMod .. " + CTRL + left", movewindow("left"), descrip("Move window left"))
keybind(mainMod .. " + CTRL + right", movewindow("right"), descrip("Move window right"))
keybind(mainMod .. " + CTRL + up", movewindow("up"), descrip("Move window up"))
keybind(mainMod .. " + CTRL + down", movewindow("down"), descrip("Move window down"))

-- Move / resize window with mouse
keybind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true, description = "Move window with the mouse" })
keybind(
	mainMod .. " + mouse:273",
	hl.dsp.window.resize(),
	{ mouse = true, description = "Resize window with the mouse" }
)

-- Worksapces
-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
	local key = i % 10 -- 10 maps to key 0
	keybind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
	keybind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Special workspaces
-- Scratchpad genérico
keybind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"), descrip("Toggle scratchpad"))
keybind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }), descrip("Move to scratchpad"))

-- Música
keybind(mainMod .. " + SHIFT + M", hl.dsp.workspace.toggle_special("music"), descrip("Toggle music workspace"))
keybind(
	mainMod .. " + ALT + M",
	hl.dsp.window.move({ workspace = "special:music" }),
	descrip("Move to music workspace")
)

-- Mensajería
keybind(mainMod .. " + C", hl.dsp.workspace.toggle_special("messaging"), descrip("Toggle messaging workspace"))
keybind(
	mainMod .. " + SHIFT + C",
	hl.dsp.window.move({ workspace = "special:messaging" }),
	descrip("Move to messaging workspace")
)

-- Misc
keybind(mainMod .. " + W", close, descrip("Close current window"))

-- Laptop multimedia keys for volume and LCD brightness
keybind("XF86AudioRaiseVolume", exec(raiseVolume), lockRep)
keybind("XF86AudioLowerVolume", exec(lowerVolume), lockRep)
keybind("XF86AudioMute", exec(mute), lockRep)
keybind("XF86AudioMicMute", exec(micMute), lockRep)
keybind("XF86MonBrightnessUp", exec(brightUp), lockRep)
keybind("XF86MonBrightnessDown", exec(brightDown), lockRep)

-- No media playback binds: the X1 Carbon Gen 13 has no play/next/prev keys
-- (ThinkPad Extra Buttons exposes none of them), and Bluetooth headphone
-- buttons reach MPRIS players through mpris-proxy (execs.lua).

-- Screenshots (screenshot script — smart snap, satty editor, notification)
keybind("PRINT", exec("screenshot fullscreen"), descrip("Screenshot fullscreen"))
keybind(mainMod .. " + PRINT", exec("screenshot region"), descrip("Screenshot region"))
-- Active-window capture kept as raw grim/jq — the screenshot script has no
-- zero-interaction "grab focused window" mode (all its modes require a slurp click)
local screenshotDir = "~/Pictures/Screenshots/$(date +%Y%m%d_%H%M%S).png"
keybind(
	mainMod .. " + SHIFT + PRINT",
	exec(
		'grim -g "$(hyprctl activewindow -j | jq -r \'"\\(.at[0]),\\(.at[1]) \\(.size[0])x\\(.size[1])"\')" '
			.. screenshotDir
	),
	descrip("Screenshot active window")
)

-- Utilities
local colorPicker = "hyprpicker -a"
local clipHistory = "cliphist list | fuzzel --dmenu | cliphist decode | wl-copy"

keybind(mainMod .. " + P", exec(colorPicker), descrip("Pick color to clipboard"))
keybind(mainMod .. " + V", exec(clipHistory), descrip("Clipboard history"))
keybind(mainMod .. " + SHIFT + V", exec("clipboard --delete"), descrip("Delete clipboard history entries"))
keybind(mainMod .. " + O", exec("ocr"), descrip("OCR: extract text from screen region"))
keybind(mainMod .. " + R", exec("reminder show"), descrip("Show active reminders"))

-- Power button → lock screen (logind HandlePowerKey=ignore lets this through)
keybind("XF86PowerOff", exec("qs -c notch ipc call lock lock"), { description = "Power button: lock screen" })

-- NOTE: lid close is intentionally NOT bound here. A "switch:on:Lid Switch"
-- bind was tried and never fired in this fork's Lua bridge (confirmed live
-- across two lid close/open cycles + reboots — no trace in hyprland.log).
-- logind handles lid → suspend natively instead (system/logind), with
-- lock-before-sleep done via a systemd system-sleep hook, not Hyprland.

-- TUI apps
keybind(mainMod .. " + A", exec("kitty --class wiremix -e wiremix"), descrip("Open audio mixer"))
keybind(mainMod .. " + SHIFT + B", exec("kitty --class bluetui -e bluetui"), descrip("Open bluetooth manager"))
keybind(mainMod .. " + SHIFT + W", exec("kitty --class impala -e impala"), descrip("Open wifi manager"))

-- Quickshell Panels
keybind(mainMod .. " + L", exec(qsIpc .. " lock lock"), descrip("Lock Screen"))
keybind(mainMod .. " + ALT + W", exec(qsIpc .. " quickWallpaper toggle"), descrip("Toggle Wallpaper Picker"))
keybind(mainMod .. " + SPACE", exec(qsIpc .. " launcher toggle"), descrip("Toggle Launcher"))
keybind(mainMod .. " + D", exec(qsIpc .. " controlcenter open"), descrip("Open Control Center"))
keybind(mainMod .. " + N", exec(qsIpc .. " controlcenter notifications"), descrip("Open Notifications"))
keybind(mainMod .. " + ALT + C", exec(qsIpc .. " expanded toggle"), descrip("Toggle Expanded Notch"))
keybind("CTRL + ALT + DELETE", exec(qsIpc .. " power open"), descrip("Open Power Menu"))
