return {
	"b0o/incline.nvim",
	event = "VeryLazy",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	opts = {
		-- With a single window lualine already shows the filename
		hide = { only_win = true },
		render = function(props)
			local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(props.buf), ":t")
			if filename == "" then
				filename = "[No Name]"
			end
			-- Icon lookup before the [+] prefix, so exact-name icons (Makefile,
			-- .gitignore) still match on modified buffers
			local icon, color = require("nvim-web-devicons").get_icon_color(filename, nil, { default = true })
			if vim.bo[props.buf].modified then
				filename = "[+] " .. filename
			end
			return { { icon, guifg = color }, { " " }, { filename } }
		end,
	},
}
