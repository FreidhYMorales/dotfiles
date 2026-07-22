-- Decorations Config -> Minimum

local config = hl.config
local colors = require("deadlock.colors")

local blurNoise      = 0.0
local sizeBlur       = 5
local brightnessBlur = 0.60
local contrastBlur   = 0.75
local rangeShadow    = 15

config({
	decoration = {
		rounding = 0,
		blur   = { noise = blurNoise, size = sizeBlur, brightness = brightnessBlur, contrast = contrastBlur },
		shadow = { color_inactive = "rgba(" .. colors.surface .. "d4)", range = rangeShadow },
	},
})

