return {
	"gbprod/yanky.nvim",
	-- Loaded on read (not only on y/p): until setup runs, its TextYankPost
	-- handler doesn't exist and deletes/changes never reach the ring.
	event = "BufReadPost",
	-- Snacks must load first so Snacks.picker.yanky registers
	dependencies = { "folke/snacks.nvim" },
	opts = {
		-- ring/preserve_cursor_position were the defaults; only the timer differs
		highlight = {
			timer = 200,
		},
	},
	keys = {
		{
			"<leader>py",
			function()
				require("snacks").picker.yanky()
			end,
			desc = "Yank History",
		},
		{ "y", "<Plug>(YankyYank)", mode = { "n", "x" }, desc = "Yank text" },
		{ "p", "<Plug>(YankyPutAfter)", desc = "Put yanked text after cursor" },
		-- Visual p uses the P variant: replaces the selection without yanking it
		-- (keeps the register, like the old `"_dP` mapping in keymaps.lua)
		{ "p", "<Plug>(YankyPutBefore)", mode = "x", desc = "Paste without yanking selection" },
		{ "P", "<Plug>(YankyPutBefore)", mode = { "n", "x" }, desc = "Put yanked text before cursor" },
		{ "gp", "<Plug>(YankyGPutAfter)", mode = { "n", "x" }, desc = "Put yanked text after selection" },
		{ "gP", "<Plug>(YankyGPutBefore)", mode = { "n", "x" }, desc = "Put yanked text before selection" },
		{ "[y", "<Plug>(YankyCycleForward)", desc = "Cycle forward through yank history" },
		{ "]y", "<Plug>(YankyCycleBackward)", desc = "Cycle backward through yank history" },
		{ "]p", "<Plug>(YankyPutIndentAfterLinewise)", desc = "Put indented after cursor (linewise)" },
		{ "[p", "<Plug>(YankyPutIndentBeforeLinewise)", desc = "Put indented before cursor (linewise)" },
		{ "]P", "<Plug>(YankyPutIndentAfterLinewise)", desc = "Put indented after cursor (linewise)" },
		{ "[P", "<Plug>(YankyPutIndentBeforeLinewise)", desc = "Put indented before cursor (linewise)" },
		{ ">p", "<Plug>(YankyPutIndentAfterShiftRight)", desc = "Put and indent right" },
		{ "<p", "<Plug>(YankyPutIndentAfterShiftLeft)", desc = "Put and indent left" },
		{ ">P", "<Plug>(YankyPutIndentBeforeShiftRight)", desc = "Put before and indent right" },
		{ "<P", "<Plug>(YankyPutIndentBeforeShiftLeft)", desc = "Put before and indent left" },
		{ "=p", "<Plug>(YankyPutAfterFilter)", desc = "Put after applying a filter" },
		{ "=P", "<Plug>(YankyPutBeforeFilter)", desc = "Put before applying a filter" },
	},
}
