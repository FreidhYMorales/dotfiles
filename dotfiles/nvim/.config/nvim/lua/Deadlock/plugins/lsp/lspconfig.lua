return {
	"neovim/nvim-lspconfig",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		"saghen/blink.cmp", -- proveedor de capabilities LSP
		-- (LSP file renames come from oil's lsp_file_methods; nvim-lsp-file-operations
		-- only hooks nvim-tree/neo-tree, which aren't used)
		"b0o/SchemaStore.nvim", -- JSON/YAML schemas for jsonls/yamlls
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

				-- gI / gy (LazyVim convention): gi (insert at last position) and
				-- gt (next tab, used for tab navigation) stay native.
				opts.desc = "Show LSP implementations"
				vim.keymap.set("n", "gI", function()
					require("snacks").picker.lsp_implementations()
				end, opts)

				opts.desc = "Show LSP type definitions"
				vim.keymap.set("n", "gy", function()
					require("snacks").picker.lsp_type_definitions()
				end, opts)

				opts.desc = "See available code actions"
				vim.keymap.set({ "n", "x" }, "<leader>ca", vim.lsp.buf.code_action, opts)

				opts.desc = "Smart rename"
				vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)

				opts.desc = "Show documentation for what is under cursor"
				vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)

				-- Buffer scope (the global toggle is <leader>li in keymaps.lua)
				opts.desc = "Toggle inlay hints (buffer)"
				vim.keymap.set("n", "<leader>uh", function()
					local filter = { bufnr = ev.buf }
					vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled(filter), filter)
				end, opts)

				-- Restart LSP: <leader>lr (global en keymaps.lua).
				-- Signature help in insert mode: native <C-s> (0.11+).

				-- 0.12 highlights LSP document colors natively; nvim-highlight-colors
				-- already does it (and feeds blink's swatches), so avoid a double layer.
				vim.lsp.document_color.enable(false, { bufnr = ev.buf })
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
				source = true,
			},
			-- ]d/[d (native) open the diagnostic float after jumping
			jump = {
				on_jump = function(diagnostic, bufnr)
					if not diagnostic then
						return
					end
					vim.diagnostic.open_float({ bufnr = bufnr, scope = "cursor", focus = false })
				end,
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

		-- biome (JS/TS/CSS/JSON lint) — only starts in projects that use Biome
		-- (biome.json or biome in package.json). Formatting stays in conform.
		vim.lsp.enable("biome")

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

		-- pyright (Python) — types only; imports are organized by ruff
		vim.lsp.config("pyright", {
			settings = {
				pyright = {
					disableOrganizeImports = true,
				},
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

		-- ruff (Python lint + quick fixes). Hover is left to pyright.
		vim.lsp.config("ruff", {
			on_attach = function(client)
				client.server_capabilities.hoverProvider = false
			end,
		})
		vim.lsp.enable("ruff")

		-- clangd (C/C++)
		vim.lsp.config("clangd", {
			cmd = {
				"clangd",
				"--background-index",
				"--clang-tidy",
				"--header-insertion=iwyu",
				"--completion-style=detailed",
				"--function-arg-placeholders",
			},
		})
		vim.lsp.enable("clangd")

		-- bashls (Bash/Shell) — zsh excluded: bash-language-server reports
		-- false positives on zsh syntax
		vim.lsp.config("bashls", {
			filetypes = { "sh", "bash" },
		})
		vim.lsp.enable("bashls")

		-- csharp_ls (C#) — disabled: not installed by mason (requires .NET SDK).
		-- Re-enable together with its entry in mason.lua.
		-- vim.lsp.config("csharp_ls", {})
		-- vim.lsp.enable("csharp_ls")

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

		-- jsonls / yamlls — completion + validation from the SchemaStore catalog
		-- (package.json, tsconfig, GitHub workflows, docker-compose, ...).
		-- Formatting stays with prettier (conform).
		local schemastore = require("schemastore")
		vim.lsp.config("jsonls", {
			settings = {
				json = {
					schemas = schemastore.json.schemas(),
					validate = { enable = true },
				},
			},
		})
		vim.lsp.enable("jsonls")

		vim.lsp.config("yamlls", {
			settings = {
				yaml = {
					-- Built-in store must be off to use SchemaStore.nvim's catalog
					schemaStore = { enable = false, url = "" },
					schemas = schemastore.yaml.schemas(),
				},
			},
		})
		vim.lsp.enable("yamlls")

		-- qmlls (QML / Quickshell) — ships with qt6-declarative outside $PATH.
		-- Quickshell import paths come from the .qmlls.ini that Quickshell
		-- generates next to shell.qml (requires an empty .qmlls.ini to exist).
		vim.lsp.config("qmlls", {
			cmd = { "/usr/lib/qt6/bin/qmlls" },
			root_markers = { ".qmlls.ini", "shell.qml", ".git" },
		})
		vim.lsp.enable("qmlls")

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
