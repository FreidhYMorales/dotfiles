return {
	"max397574/better-escape.nvim",
	event = "InsertEnter",
	opts = {
		timeout = vim.o.timeoutlen,
		default_mappings = false,
		mappings = {
			i = {
				j = {
					k = "<Esc>",
					j = "<Esc>",
				},
			},
			c = {
				j = {
					k = "<Esc>",
					j = "<Esc>",
				},
			},
			t = {
				j = {
					k = "<Esc>",
					j = "<Esc>",
				},
			},
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
