-- Animations Config -> Fast

-- Variables
local curve = hl.curve
local animation = hl.animation

-- Set animations On/Off
hl.config({
	animations = {
		enabled = true,
	},
})

-- Animations Curves (Bezier)
curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
curve("md3_standard", { type = "bezier", points = { { 0.2, 0 }, { 1, 1 } } })
curve("md3_decel", { type = "bezier", points = { { 0.5, 0.7 }, { 0.1, 1 } } })
curve("md3_accel", { type = "bezier", points = { { 0.3, 0 }, { 0.8, 0.15 } } })
curve("overshot", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.1 } } })
curve("crazyshot", { type = "bezier", points = { { 0.1, 1.5 }, { 0.76, 0.92 } } })
curve("hyprnostretch", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1 } } })
curve("fluent_decel", { type = "bezier", points = { { 0.1, 1 }, { 0, 1 } } })
curve("easeInOutCirc", { type = "bezier", points = { { 0.85, 0 }, { 0.15, 1 } } })
curve("easeOutCirc", { type = "bezier", points = { { 0, 0.55 }, { 0.45, 1 } } })
curve("easeOutExpo", { type = "bezier", points = { { 0.16, 1 }, { 0.3, 1 } } })

-- Animations
animation({ leaf = "windows", enabled = true, speed = 3, bezier = "md3_decel", style = "popin 60%" })
animation({ leaf = "border", enabled = true, speed = 10, bezier = "default" })
animation({ leaf = "fade", enabled = true, speed = 2.5, bezier = "md3_decel" })
animation({ leaf = "workspaces", enabled = true, speed = 3.5, bezier = "easeOutExpo", style = "slide" })
animation({ leaf = "specialWorkspace", enabled = true, speed = 3, bezier = "md3_decel", style = "slidevert" })
