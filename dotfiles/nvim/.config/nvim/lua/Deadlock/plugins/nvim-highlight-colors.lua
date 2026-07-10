return {
	"brenoprata10/nvim-highlight-colors",
	event = { "BufReadPre", "BufNewFile" },
	opts = {
		-- "foreground" colors the hex/rgb text itself — no virtual text inserted,
		-- so redraws are much lighter on files with many color values.
		render = "foreground",

		enable_hex                = true,
		enable_short_hex          = true,
		enable_rgb                = true,
		enable_hsl                = true,
		enable_hsl_without_function = true,
		-- Disabled: requires scanning the entire buffer on every change to resolve
		-- CSS custom properties (--var: ...). High cost, low value outside CSS files.
		enable_var_usage          = false,
		enable_named_colors       = false, -- too noisy (matches plain words like "red")
		enable_tailwind           = true,  -- tailwindcss is in the LSP stack

		exclude_filetypes = {
			"lazy", "mason", "dashboard", "help", "TelescopePrompt",
			"snacks_dashboard", "snacks_picker_list", "snacks_picker_input",
			"oil", "trouble", "qf",
		},
		exclude_buftypes = { "nofile", "prompt", "popup" },
	},
	config = function(_, opts)
		require("nvim-highlight-colors").setup(opts)

		-- Disable for large files to avoid extmark overhead on every change.
		vim.api.nvim_create_autocmd("BufReadPost", {
			group = vim.api.nvim_create_augroup("highlight_colors_perf", { clear = true }),
			callback = function(args)
				local path = vim.api.nvim_buf_get_name(args.buf)
				if path ~= "" and vim.fn.getfsize(path) > 100 * 1024 then
					-- Disable globally while this large buffer is focused, re-enable on leave.
					vim.api.nvim_create_autocmd("BufEnter", {
						buffer = args.buf,
						callback = function()
							vim.cmd("HighlightColors Off")
						end,
					})
					vim.api.nvim_create_autocmd("BufLeave", {
						buffer = args.buf,
						callback = function()
							vim.cmd("HighlightColors On")
						end,
					})
				end
			end,
		})
	end,
}
