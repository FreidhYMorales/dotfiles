return {
	"folke/todo-comments.nvim",
	event = { "BufReadPre", "BufNewFile" },
	keys = {
		{
			"]t",
			function()
				require("todo-comments").jump_next()
			end,
			desc = "Next todo comment",
		},
		{
			"[t",
			function()
				require("todo-comments").jump_prev()
			end,
			desc = "Previous todo comment",
		},
	},
	opts = {
		keywords = {
			FIX = {
				icon = " ", -- icon used for the sign, and in search results
				color = "error", -- can be a hex color, or a named color (see below)
				alt = { "FIXME", "BUG", "FIXIT", "ISSUE" }, -- a set of other keywords that all map to this FIX keywords
			},
			TODO = { icon = " ", color = "info", alt = { "Personal" } },
			HACK = { icon = " ", color = "warning", alt = { "DON SKIP" } },
			WARN = { icon = " ", color = "warning", alt = { "WARNING", "XXX" } },
			PERF = { icon = " ", alt = { "OPTIM", "PERFORMANCE", "OPTIMIZE" } },
			NOTE = { icon = " ", color = "hint", alt = { "INFO", "READ", "COLORS", "Custom" } },
			TEST = { icon = "⏲ ", color = "test", alt = { "TESTING", "PASSED", "FAILED" } },
			FORGETNOT = { icon = " ", color = "hint" },
		},
		highlight = {
			multiline = true,
			multiline_pattern = "^.",
			multiline_context = 10,
			before = "",
			keyword = "wide",
			after = "fg",
			pattern = {
				[[.*<(KEYWORDS)\s*:]], -- default pattern
				[[<!--\s*(KEYWORDS)\s*.*-->]], -- HTML comments (with or without colon)
			},
			comments_only = false, -- highlighting outside of comments
		},
		search = {
			command = "rg",
			args = {
				"--color=never",
				"--no-heading",
				"--with-filename",
				"--line-number",
				"--column",
			},
			pattern = [[\b(KEYWORDS)\b]],
		},
	},
}
