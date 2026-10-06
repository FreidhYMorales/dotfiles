return {
	"max397574/better-escape.nvim",
	-- VeryLazy (not InsertEnter): the c/v/s mappings must exist before the
	-- first insert too.
	event = "VeryLazy",
	opts = {
		default_mappings = false,
		mappings = {
			i = {
				j = {
					k = "<Esc>",
					j = "<Esc>",
				},
			},
			-- <C-c>, not <Esc>: keys are fed as non-typed, and a non-typed <Esc>
			-- on the cmdline executes the command instead of cancelling it.
			c = {
				j = {
					k = "<C-c>",
					j = "<C-c>",
				},
			},
			-- No terminal-mode mappings: they hijacked j/k inside yazi and
			-- lazygit (both run in terminal buffers).
			v = {
				j = {
					k = "<Esc>",
				},
			},
			s = {
				j = {
					k = "<Esc>",
				},
			},
		},
	},
}
