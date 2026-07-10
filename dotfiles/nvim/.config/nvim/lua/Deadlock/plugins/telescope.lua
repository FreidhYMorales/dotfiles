-- Telescope removed: all pickers migrated to snacks.picker.
-- Keeping telescope-themes as optional if you want :Telescope themes.
return {
	{
		"nvim-telescope/telescope.nvim",
		lazy = true,
		cmd = "Telescope",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"andrew-george/telescope-themes",
		},
		config = function()
			require("telescope").load_extension("themes")
		end,
	},
}
