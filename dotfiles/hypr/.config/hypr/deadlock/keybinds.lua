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
local music = "kitty -e ncmpcpp"

-- Volume
local raiseVolume = "wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"
local lowerVolume = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
local mute = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
local micMute = "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"

-- LCD Brightness
local brightUp = "brightnessctl -e4 -n2 set 5%+"
local brightDown = "brightnessctl -e4 -n2 set 5%-"

-- Audio Control
local audioNext = "playerctl next"
local play = "playerctl play-pause"
local audioPrev = "playerctl previous"

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
local qsIpc = "qs ipc call"

-- Keybinds
-- Applications
keybind(mainMod .. " + RETURN", exec(terminal), descrip("Open Terminal"))
keybind(mainMod .. " + B", exec(browser), descrip("Open Browser"))
keybind(mainMod .. " + E", exec(fileManager), descrip("Open File Manager"))
keybind(mainMod .. " + SHIFT + M", exec(music), descrip("Open Local Music"))

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
keybind(mainMod .. " + left",  focus("left"),  descrip("Move focus left"))
keybind(mainMod .. " + right", focus("right"), descrip("Move focus right"))
keybind(mainMod .. " + up",    focus("up"),    descrip("Move focus up"))
keybind(mainMod .. " + down",  focus("down"),  descrip("Move focus down"))

-- Move window with mainMod + CTRL + arrow keys
keybind(mainMod .. " + CTRL + left",  movewindow("left"),  descrip("Move window left"))
keybind(mainMod .. " + CTRL + right", movewindow("right"), descrip("Move window right"))
keybind(mainMod .. " + CTRL + up",    movewindow("up"),    descrip("Move window up"))
keybind(mainMod .. " + CTRL + down",  movewindow("down"),  descrip("Move window down"))

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

-- Misc
keybind(mainMod .. " + W", close, descrip("Close current window"))

-- Laptop multimedia keys for volume and LCD brightness
keybind("XF86AudioRaiseVolume", exec(raiseVolume), lockRep)
keybind("XF86AudioLowerVolume", exec(lowerVolume), lockRep)
keybind("XF86AudioMute", exec(mute), lockRep)
keybind("XF86AudioMicMute", exec(micMute), lockRep)
keybind("XF86MonBrightnessUp", exec(brightUp), lockRep)
keybind("XF86MonBrightnessDown", exec(brightDown), lockRep)

-- Requires playerctl
keybind("XF86AudioNext", exec(audioNext), { locked = true })
keybind("XF86AudioPause", exec(play), { locked = true })
keybind("XF86AudioPlay", exec(play), { locked = true })
keybind("XF86AudioPrev", exec(audioPrev), { locked = true })

-- Screenshots (grim + slurp)
local screenshotDir = "~/Pictures/Screenshots/$(date +%Y%m%d_%H%M%S).png"
keybind("PRINT", exec("grim " .. screenshotDir), descrip("Screenshot fullscreen"))
keybind(mainMod .. " + PRINT", exec("slurp | grim -g - " .. screenshotDir), descrip("Screenshot region"))
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

-- Power button → lock screen (logind HandlePowerKey=ignore lets this through)
keybind("XF86PowerOff", exec("qs ipc call lock lock"), { description = "Power button: lock screen" })

-- TUI apps
keybind(mainMod .. " + A", exec("kitty --class wiremix -e wiremix"), descrip("Open audio mixer"))
keybind(mainMod .. " + SHIFT + B", exec("kitty --class bluetui -e bluetui"), descrip("Open bluetooth manager"))
keybind(mainMod .. " + SHIFT + W", exec("kitty --class impala -e impala"), descrip("Open wifi manager"))

-- Quickshell Panels
keybind(mainMod .. " + SPACE", exec(qsIpc .. " launcher toggle"), descrip("Toggle Launcher"))
keybind(mainMod .. " + D", exec(qsIpc .. " dashboard toggle"), descrip("Toggle Dashboard"))
keybind(mainMod .. " + N", exec(qsIpc .. " notifications toggle"), descrip("Toggle Notifications"))
keybind(mainMod .. " + C", exec(qsIpc .. " calendar toggle"), descrip("Toggle Calendar"))
keybind("CTRL + ALT + DELETE", exec(qsIpc .. " powermenu toggle"), descrip("Toggle Power Menu"))
