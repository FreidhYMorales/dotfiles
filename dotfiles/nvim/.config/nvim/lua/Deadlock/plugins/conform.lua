return {
	"stevearc/conform.nvim",
	-- Recommended lazy-loading (conform docs/recipes): only needed to format
	event = "BufWritePre",
	cmd = "ConformInfo",
	keys = {
		-- Format: <leader>cf lives in keymaps.lua
		{
			"<leader>uf",
			function()
				if vim.b.disable_autoformat or vim.g.disable_autoformat then
					vim.b.disable_autoformat = false
					vim.g.disable_autoformat = false
					vim.notify("Format on save: enabled")
				else
					vim.b.disable_autoformat = true
					vim.g.disable_autoformat = true
					vim.notify("Format on save: disabled")
				end
			end,
			desc = "Toggle format on save",
		},
	},
	init = function()
		-- gq uses conform instead of the LSP formatexpr 0.12 sets by default
		vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
	end,
	opts = {
		-- Shared by format_on_save and manual formats (<leader>cf)
		default_format_opts = {
			lsp_format = "fallback",
			timeout_ms = 1000,
		},
		formatters = {
			-- Only runs in files that opt in with a <!-- toc --> marker
			["markdown-toc"] = {
				condition = function(_, ctx)
					for _, line in ipairs(vim.api.nvim_buf_get_lines(ctx.buf, 0, -1, false)) do
						if line:find("<!%-%- toc %-%->") then
							return true
						end
					end
				end,
			},
			prettier = {
				prepend_args = { "--tab-width", "4" },
			},
			shfmt = {
				prepend_args = { "-i", "4" },
			},
		},
		formatters_by_ft = {
			-- JavaScript/TypeScript
			javascript = { "biome-check" },
			typescript = { "biome-check" },
			javascriptreact = { "biome-check" },
			typescriptreact = { "biome-check" },

			-- Web
			css = { "biome-check" },
			html = { "prettier" },
			svelte = { "prettier" },
			json = { "prettier" },
			yaml = { "prettier" },
			graphql = { "prettier" },
			liquid = { "prettier" },

			-- Lua
			lua = { "stylua" },

			-- Python
			-- ruff replaces isort + black (autofixes stay as code actions)
			python = { "ruff_organize_imports", "ruff_format" },

			-- Shell scripts
			sh = { "shfmt" },
			bash = { "shfmt" },
			zsh = { "shfmt" },
			fish = { "fish_indent" },

			-- C/C++/C#
			c = { "clang-format" },
			cpp = { "clang-format" },
			cs = { "clang-format" },

			-- Go
			-- goimports fixes imports, gofumpt is a stricter gofmt
			-- (matches gopls `gofumpt = true`)
			go = { "goimports", "gofumpt" },

			-- Rust
			rust = { "rustfmt" },

			-- Markdown
			markdown = { "prettier", "markdown-toc" },
		},
		format_on_save = function(bufnr)
			-- Disable autoformat on certain filetypes
			local disable_filetypes = { c = true, cpp = true }
			if disable_filetypes[vim.bo[bufnr].filetype] then
				return
			end
			-- Disable with a global or buffer-local variable
			if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
				return
			end
			-- Skip writes triggered by the auto-save autocmd (autocmd.lua)
			if vim.b[bufnr].autosaving then
				return
			end
			return {} -- uses default_format_opts
		end,
	},
}
