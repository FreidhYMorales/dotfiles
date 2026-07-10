return {
	"stevearc/conform.nvim",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		local conform = require("conform")

		conform.setup({
            formatters = {
                ["markdown-toc"] = {
                    condition = function(_, ctx)
                        for _, line in ipairs(vim.api.nvim_buf_get_lines(ctx.buf, 0, -1, false)) do
                            if line:find("<!%-%- toc %-%->") then
                                return true
                            end
                        end
                    end,
                },
                ["markdownlint-cli2"] = {
                    condition = function(_, ctx)
                        local diag = vim.tbl_filter(function(d)
                            return d.source == "markdownlint"
                        end, vim.diagnostic.get(ctx.buf))
                        return #diag > 0
                    end,
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
				python = { "isort", "black" },

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
				go = { "gofmt", "goimports" },

				-- Rust
				rust = { "rustfmt" },

				-- Markdown
                markdown = { "prettier" , "markdown-toc" },
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
				return {
					lsp_format = "fallback",
					async = false,
					timeout_ms = 1000,
				}
			end,
		})

		-- Configure individual formatters
		conform.formatters.prettier = {
			prepend_args = {
				"--tab-width",
				"4",
			},
		}
		conform.formatters.shfmt = {
			prepend_args = { "-i", "4" },
		}

		-- Format: <leader>cf definido en keymaps.lua (evita duplicar aquí)

		-- Toggle format on save
		vim.keymap.set("n", "<leader>uf", function()
			if vim.b.disable_autoformat or vim.g.disable_autoformat then
				vim.b.disable_autoformat = false
				vim.g.disable_autoformat = false
				print("✓ Format on save: ENABLED")
			else
				vim.b.disable_autoformat = true
				vim.g.disable_autoformat = true
				print("✗ Format on save: DISABLED")
			end
		end, { desc = "Toggle format on save" })
	end,
}
