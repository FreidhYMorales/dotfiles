-- General Configs

local config = hl.config
local colors = require("deadlock.colors")

config({
	general = {
		border_size      = 2,
		resize_on_border = false,
		layout           = "master",
		col = {
			active_border   = "rgba(" .. colors.primary .. "e6)",
			inactive_border = "rgba(" .. colors.outline_variant .. "40)",
		},
	},
})

config({
	master = {
		new_status = "slave",
		mfact      = 0.55,
	},
})

config({
	misc = {
		force_default_wallpaper = -1,
		disable_hyprland_logo   = false,
	},
})
