return {
	"utilyre/barbecue.nvim",
	event = "BufReadPost",
	dependencies = {
		"SmiteshP/nvim-navic",
		"nvim-tree/nvim-web-devicons",
	},
	opts = {
		-- Disable barbecue's own theme management — my-theme sets all BarbecueNormal,
		-- BarbecueDimmed, NavicIcons* etc. groups via nvim_set_hl; if theme ~= false
		-- barbecue would overwrite them with its own defaults.
		-- theme = false,
		attach_navic = true,
		show_modified = true,
		separator = "  ",
	},
}
