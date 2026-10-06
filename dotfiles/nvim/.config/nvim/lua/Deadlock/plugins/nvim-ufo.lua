return {
	{
		"kevinhwang91/nvim-ufo",
		event = { "BufReadPost", "BufNewFile" },
		keys = {
			{
				"zR",
				function()
					require("ufo").openAllFolds()
				end,
				desc = "Open all folds",
			},
			{
				"zM",
				function()
					require("ufo").closeAllFolds()
				end,
				desc = "Close all folds",
			},
		},
		dependencies = {
			"kevinhwang91/promise-async",
		},
		-- Fold options in init (not config): config runs on BufReadPost, after
		-- the first buffer is read, so foldlevelstart came too late for it.
		init = function()
			vim.o.foldenable = true
			vim.o.foldcolumn = "0"
			vim.o.foldlevel = 99 -- ufo needs a large value
			vim.o.foldlevelstart = 99
		end,
		opts = {
			-- ufo uses the same folds.scm queries as treesitter folding
			provider_selector = function(_, _, _)
				return { "treesitter", "indent" }
			end,
			open_fold_hl_timeout = 0, -- Disable highlight timeout after opening
		},
	},
}
