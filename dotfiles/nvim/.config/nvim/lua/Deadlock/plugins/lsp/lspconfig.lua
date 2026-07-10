return {
	"neovim/nvim-lspconfig",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		"saghen/blink.cmp", -- proveedor de capabilities LSP
		{ "antosha417/nvim-lsp-file-operations", config = true },
	},
	config = function()
		-- NOTE: LSP Keybinds
		vim.api.nvim_create_autocmd("LspAttach", {
			group = vim.api.nvim_create_augroup("UserLspConfig", {}),
			callback = function(ev)
				-- Buffer local mappings
				local opts = { buffer = ev.buf, silent = true }

				-- Keymaps
				opts.desc = "Show LSP references"
				vim.keymap.set("n", "gR", function()
					require("snacks").picker.lsp_references()
				end, opts)

				opts.desc = "Go to declaration"
				vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)

				opts.desc = "Show LSP definitions"
				vim.keymap.set("n", "gd", function()
					require("snacks").picker.lsp_definitions()
				end, opts)

				opts.desc = "Show LSP implementations"
				vim.keymap.set("n", "gi", function()
					require("snacks").picker.lsp_implementations()
				end, opts)

				opts.desc = "Show LSP type definitions"
				vim.keymap.set("n", "gt", function()
					require("snacks").picker.lsp_type_definitions()
				end, opts)

				opts.desc = "See available code actions"
				vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)

				opts.desc = "Smart rename"
				vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)

				opts.desc = "Show documentation for what is under cursor"
				vim.keymap.set("n", "K", function()
					vim.lsp.buf.hover({ border = "rounded" })
				end, opts)

				opts.desc = "Toggle inlay hints"
				vim.keymap.set("n", "<leader>uh", function()
					vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
				end, opts)

				-- Restart LSP: <leader>lr (global en keymaps.lua)
				-- Se omite aquí para evitar registrarlo en cada buffer individualmente

				vim.keymap.set("i", "<C-h>", function()
					vim.lsp.buf.signature_help({ border = "rounded" })
				end, opts)
			end,
		})

		-- Define sign icons for each severity
		local signs = {
			[vim.diagnostic.severity.ERROR] = " ",
			[vim.diagnostic.severity.WARN] = " ",
			[vim.diagnostic.severity.HINT] = "󰠠 ",
			[vim.diagnostic.severity.INFO] = " ",
		}

		-- Set diagnostic config
		vim.diagnostic.config({
			signs = {
				text = signs,
			},
			virtual_text = true,
			underline = true,
			update_in_insert = false,
			float = {
				border = "rounded",
				source = true,
			},
		})

		-- Setup servers
		-- blink.cmp extiende las capabilities nativas con soporte de snippets,
		-- labelDetails y otras extensiones del protocolo LSP.
		local capabilities = require("blink.cmp").get_lsp_capabilities()

		-- Global LSP settings (applied to all servers)
		vim.lsp.config("*", {
			capabilities = capabilities,
		})

		-- Configure and enable LSP servers
		-- lua_ls: lazydev.nvim maneja globals vim.*, vim.uv, Snacks, etc.
		-- y registra VIMRUNTIME + config/lua en el workspace automáticamente.
		-- Aquí solo configuramos lo que lazydev NO cubre.
		vim.lsp.config("lua_ls", {
			settings = {
				Lua = {
					completion = {
						callSnippet = "Replace",
					},
				},
			},
		})
		vim.lsp.enable("lua_ls")

		-- emmet_ls
		vim.lsp.config("emmet_ls", {
			filetypes = {
				"html",
				"typescriptreact",
				"javascriptreact",
				"css",
				"sass",
				"scss",
				"less",
				"svelte",
			},
		})
		vim.lsp.enable("emmet_ls")

		-- ts_ls (TypeScript/JavaScript)
		vim.lsp.config("ts_ls", {
			filetypes = {
				"javascript",
				"javascriptreact",
				"typescript",
				"typescriptreact",
			},
			single_file_support = true,
			init_options = {
				preferences = {
					includeCompletionsForModuleExports = true,
					includeCompletionsForImportStatements = true,
				},
			},
			settings = {
				typescript = {
					inlayHints = {
						includeInlayParameterNameHints = "all",
						includeInlayParameterNameHintsWhenArgumentMatchesName = false,
						includeInlayFunctionParameterTypeHints = true,
						includeInlayVariableTypeHints = true,
						includeInlayPropertyDeclarationTypeHints = true,
						includeInlayFunctionLikeReturnTypeHints = true,
						includeInlayEnumMemberValueHints = true,
					},
				},
				javascript = {
					inlayHints = {
						includeInlayParameterNameHints = "all",
						includeInlayParameterNameHintsWhenArgumentMatchesName = false,
						includeInlayFunctionParameterTypeHints = true,
						includeInlayVariableTypeHints = true,
						includeInlayPropertyDeclarationTypeHints = true,
						includeInlayFunctionLikeReturnTypeHints = true,
						includeInlayEnumMemberValueHints = true,
					},
				},
			},
		})
		vim.lsp.enable("ts_ls")

		-- gopls
		vim.lsp.config("gopls", {
			settings = {
				gopls = {
					analyses = {
						unusedparams = true,
					},
					staticcheck = true,
					gofumpt = true,
					hints = {
						assignVariableTypes = true,
						compositeLiteralFields = true,
						compositeLiteralTypes = true,
						constantValues = true,
						functionTypeParameters = true,
						parameterNames = true,
						rangeVariableTypes = true,
					},
				},
			},
		})
		vim.lsp.enable("gopls")

		-- pyright (Python)
		vim.lsp.config("pyright", {
			settings = {
				python = {
					analysis = {
						typeCheckingMode = "basic",
						autoSearchPaths = true,
						useLibraryCodeForTypes = true,
						diagnosticMode = "workspace",
					},
				},
			},
		})
		vim.lsp.enable("pyright")

		-- clangd (C/C++)
		vim.lsp.config("clangd", {
			cmd = {
				"clangd",
				"--background-index",
				"--clang-tidy",
				"--header-insertion=iwyu",
				"--completion-style=detailed",
				"--function-arg-placeholders",
				"--offset-encoding=utf-16",
			},
		})
		vim.lsp.enable("clangd")

		-- bashls (Bash/Shell)
		vim.lsp.config("bashls", {
			filetypes = { "sh", "bash", "zsh" },
		})
		vim.lsp.enable("bashls")

		-- csharp_ls (C#)
		vim.lsp.config("csharp_ls", {})
		vim.lsp.enable("csharp_ls")

		-- html (HTML)
		vim.lsp.config("html", {})
		vim.lsp.enable("html")

		-- cssls (CSS)
		vim.lsp.config("cssls", {})
		vim.lsp.enable("cssls")

		-- tailwindcss
		vim.lsp.config("tailwindcss", {
			filetypes = {
				"html",
				"css",
				"scss",
				"javascript",
				"javascriptreact",
				"typescript",
				"typescriptreact",
				"svelte",
			},
		})
		vim.lsp.enable("tailwindcss")

		-- angularls
		vim.lsp.config("angularls", {})
		vim.lsp.enable("angularls")

		-- marksman (Markdown)
		vim.lsp.config("marksman", {})
		vim.lsp.enable("marksman")

		-- rust_analyzer (Rust)
		vim.lsp.config("rust_analyzer", {
			settings = {
				["rust-analyzer"] = {
					checkOnSave = true,
					check = {
						command = "clippy",
					},
					inlayHints = {
						bindingModeHints = { enable = true },
						chainingHints = { enable = true },
						parameterHints = { enable = true },
						typeHints = { enable = true },
					},
				},
			},
		})
		vim.lsp.enable("rust_analyzer")
	end,
}
