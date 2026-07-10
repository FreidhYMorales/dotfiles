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

-- Float + center: audio mixer
rule({
	name = "float-pavucontrol",
	match = { class = "org.pulseaudio.pavucontrol" },
	float = true,
	center = true,
	size = "60% 70%",
})

-- Float + center: bluetooth
rule({
	name = "float-blueman",
	match = { class = "blueman-manager" },
	float = true,
	center = true,
	size = "50% 60%",
})

-- Float + center: nwg-look / nwg-displays
rule({
	name = "float-nwg",
	match = { class = "nwg-look|nwg-displays" },
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

-- Float + center: wiremix (TUI audio mixer)
rule({
	name = "float-wiremix",
	match = { class = "wiremix" },
	float = true,
	center = true,
	size = "80% 70%",
})

-- Float + center: bluetui (TUI bluetooth manager)
rule({
	name = "float-bluetui",
	match = { class = "bluetui" },
	float = true,
	center = true,
	size = "70% 65%",
})

-- Float + center: impala (TUI wifi manager)
rule({
	name = "float-impala",
	match = { class = "impala" },
	float = true,
	center = true,
	size = "70% 65%",
})

-- Layer rules: blur for Quickshell power menu overlay
hl.layer_rule({ match = { namespace = "qs-powermenu" }, blur = true })
hl.layer_rule({ match = { namespace = "qs-powermenu" }, ignore_alpha = 0.2 })
