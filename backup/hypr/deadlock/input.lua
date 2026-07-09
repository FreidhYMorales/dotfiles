-- Input Configs

-- Variables
local config  = hl.config
local layout  = "us"
local variant = "altgr-intl"
local numlock = true

-- Touchpad
local naturalScroll = true
local tapToClick    = true

config({
	input = {
		kb_layout          = layout,
		kb_variant         = variant,
		numlock_by_default = numlock,
		follow_mouse       = 1,
		touchpad = {
			natural_scroll = naturalScroll,
			tap_to_click   = tapToClick,
		},
	},
})
