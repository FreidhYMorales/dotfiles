return {
	"saghen/blink.cmp",
	version = "1.*",
	dependencies = {
		{
			"L3MON4D3/LuaSnip",
			version = "v2.*",
			build = "make install_jsregexp",
			dependencies = { "rafamadriz/friendly-snippets" },
		},
		-- Native spell source (replaces blink.compat + cmp-spell)
		"ribru17/blink-cmp-spell",
	},
	opts = {
		snippets = { preset = "luasnip" },

		keymap = {
			preset = "none",
			["<C-Space>"] = { "show", "show_documentation", "hide_documentation" },
			["<C-e>"] = { "hide", "fallback" },
			["<C-d>"] = { "hide_documentation", "fallback" },
			["<C-b>"] = { "scroll_documentation_up", "fallback" },
			["<C-f>"] = { "scroll_documentation_down", "fallback" },
			["<C-k>"] = { "select_prev", "fallback" },
			["<C-j>"] = { "select_next", "fallback" },
			["<C-p>"] = { "select_prev", "fallback" },
			["<C-n>"] = { "select_next", "fallback" },
			["<Up>"] = { "select_prev", "fallback" },
			["<Down>"] = { "select_next", "fallback" },
			["<C-y>"] = { "accept", "fallback" },
			["<CR>"] = { "accept", "fallback" },
			["<Tab>"] = { "snippet_forward", "select_next", "fallback" },
			["<S-Tab>"] = { "snippet_backward", "select_prev", "fallback" },
		},

		sources = {
			default = { "lsp", "path", "snippets", "buffer", "spell" },
			-- lazydev only for Lua (in `default` it was required in every filetype)
			per_filetype = {
				lua = { inherit_defaults = true, "lazydev" },
			},
			providers = {
				lazydev = {
					name = "LazyDev",
					module = "lazydev.integrations.blink",
					score_offset = 100,
				},
				spell = {
					name = "Spell",
					module = "blink-cmp-spell",
					score_offset = -3,
					enabled = function()
						local ft = vim.bo.filetype
						return ft == "markdown" or ft == "text"
					end,
				},
			},
		},

		-- Spell suggestions keep their spellsuggest order (label sort), as the
		-- blink-cmp-spell README recommends; everything else uses the defaults.
		fuzzy = {
			sorts = {
				function(a, b)
					if a.source_id == "spell" and b.source_id == "spell" then
						return require("blink.cmp.fuzzy.sort").label(a, b)
					end
				end,
				"score",
				"kind",
				"label",
			},
		},

		appearance = {
			nerd_font_variant = "mono",
		},

		completion = {
			documentation = {
				auto_show = true,
				auto_show_delay_ms = 200,
			},
			ghost_text = { enabled = true },
			-- Borders come from vim.o.winborder (blink uses it when border is nil)
			menu = {
				draw = {
					treesitter = { "lsp" },
					columns = {
						{ "kind_icon" },
						{ "label", "label_description", gap = 1 },
						{ "kind" },
						{ "source_name" },
					},
					components = {
						-- Override the kind icon for LSP color items so the icon itself
						-- becomes a swatch of the actual color instead of a generic ● symbol.
						kind_icon = {
							text = function(ctx)
								if ctx.item.source_name == "LSP" then
									local hl = require("nvim-highlight-colors")
									local color = hl.format(ctx.item.documentation, { kind = ctx.kind })
									if color and color.abbr ~= "" then
										return color.abbr .. ctx.icon_gap
									end
								end
								return ctx.kind_icon .. ctx.icon_gap
							end,
							highlight = function(ctx)
								if ctx.item.source_name == "LSP" then
									local hl = require("nvim-highlight-colors")
									local color = hl.format(ctx.item.documentation, { kind = ctx.kind })
									if color and color.abbr_hl_group then
										return color.abbr_hl_group
									end
								end
								return "BlinkCmpKind" .. ctx.kind
							end,
						},
					},
				},
			},
		},
	},
	config = function(_, opts)
		require("luasnip.loaders.from_vscode").lazy_load()
		require("blink.cmp").setup(opts)
	end,
}
