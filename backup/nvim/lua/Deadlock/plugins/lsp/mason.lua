return {
	"williamboman/mason.nvim",
	lazy = false,
	dependencies = {
		"williamboman/mason-lspconfig.nvim",
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		"neovim/nvim-lspconfig",
		"saghen/blink.cmp", -- para que blink esté listo antes del LSP setup
	},
	config = function()
		local mason = require("mason")
		local mason_lspconfig = require("mason-lspconfig")
		local mason_tool_installer = require("mason-tool-installer")

		mason.setup({
			ui = {
				icons = {
					package_installed = "✓",
					package_pending = "➜",
					package_uninstalled = "✗",
				},
			},
		})

		mason_lspconfig.setup({
			automatic_enable = false,
			-- servers for mason to install
			ensure_installed = {
				"lua_ls", -- Lua
				"ts_ls", -- TypeScript/JavaScript
				"html", -- HTML
				"cssls", -- CSS
				"tailwindcss", -- Tailwind CSS
				"gopls", -- Go
				"pyright", -- Python
				"clangd", -- C/C++
				"bashls", -- Bash/Shell
				-- "csharp_ls",        -- C#
				"angularls", -- Angular
				"emmet_ls", -- Emmet
				"marksman", -- Markdown
				"rust_analyzer", -- Rust
			},
		})

		mason_tool_installer.setup({
			ensure_installed = {
				-- Formatters
				"prettier", -- JS/TS/HTML/CSS/JSON/YAML formatter
				"stylua", -- Lua formatter
				"black", -- Python formatter
				"isort", -- Python import formatter
				"shfmt", -- Shell script formatter
				"clang-format", -- C/C++/C# formatter
				"goimports", -- Go imports formatter (gofmt is built-in with Go)

				-- Linters
				"pylint", -- Python linter
				"shellcheck", -- Shell script linter
				"biome", -- JS/TS linter and formatter
				"cpplint", -- C/C++ linter

				-- Rust
				"codelldb", -- Rust/C++ DAP adapter
			},
		})
	end,
}
