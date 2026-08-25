-- Window Rules

local rule = hl.window_rule

-- Suppress maximize requests from all apps
rule({
	name = "suppress-maximize",
	match = { class = ".*" },
	suppress_event = "maximize",
})

-- Fix XWayland empty-class floating windows stealing focus (e.g. Steam popups)
rule({
	name = "fix-xwayland-focus",
	match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
	no_focus = true,
})

-- Center all non-xwayland floating windows
rule({
	name = "center-floats",
	match = { float = true, xwayland = false },
	center = true,
})

-- Float + center: nwg-displays (nwg-look was never installed — bootstrap.sh
-- only pulls nwg-displays; pavucontrol/blueman-manager rules removed for the
-- same reason, wiremix/bluetui are the actual CLI tools this repo installs)
rule({
	name = "float-nwg",
	match = { class = "nwg-displays" },
	float = true,
	center = true,
})

-- Float: file/save dialogs (by title)
rule({
	name = "float-file-dialogs",
	match = { title = "(Select|Open|Save)( a)?( File| Folder)?" },
	float = true,
})

-- Float + center: Quickshell bluetooth panel
rule({
	name = "float-qs-bluetooth",
	match = { class = "qs-bluetooth" },
	float = true,
	center = true,
	size = "700 500",
})

-- Float + center: Quickshell wifi panel
rule({
	name = "float-qs-wifi",
	match = { class = "qs-wifi" },
	float = true,
	center = true,
	size = "700 500",
})

-- Float + center: TUI apps (wiremix / bluetui / impala)
rule({
	name = "float-tui-apps",
	match = { class = "wiremix|bluetui|impala" },
	float = true,
	center = true,
	size = "70% 65%",
})

-- Opacity + blur: Obsidian (Electron doesn't support this natively like kitty's
-- background_opacity, but forcing opacity via windowrule + the global blur
-- decoration already enabled above achieves the same effect on any window)
rule({
	name = "blur-obsidian",
	match = { class = "obsidian" },
	opacity = 0.85,
})

-- Layer rules: blur for Quickshell power menu overlay
hl.layer_rule({ match = { namespace = "qs-powermenu" }, blur = true })
hl.layer_rule({ match = { namespace = "qs-powermenu" }, ignore_alpha = 0.2 })
