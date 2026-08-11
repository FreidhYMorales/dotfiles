-- General Configs

local config = hl.config
local colors = require("deadlock.colors")

config({
	general = {
		border_size = 2,
		resize_on_border = false,
		layout = "master",
		-- Matched to the bar's own side margin (Bar.qml, 10px — must be a
		-- multiple of 5 so it lands on a whole physical pixel at this
		-- monitor's 1.2 scale) so tiled windows line up with the bar's edges.
		gaps_out = "10",
		col = {
			active_border = "rgba(" .. colors.primary .. "e6)",
			inactive_border = "rgba(" .. colors.outline_variant .. "40)",
		},
	},
})

config({
	master = {
		new_status = "slave",
		mfact = 0.55,
	},
})

config({
	misc = {
		force_default_wallpaper = -1,
		disable_hyprland_logo = true,
		middle_click_paste = false,
		session_lock_xray = true,
		allow_session_lock_restore = true,
		on_focus_under_fullscreen = 2,
		mouse_move_enables_dpms = true,
		key_press_enables_dpms = true,
	},
})
