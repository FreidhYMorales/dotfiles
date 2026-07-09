local config = {
	defaults = {
		-- Variants:
		--   dark:  "default" (transparent), "black" (#000000), "dark" (#0f0f0f), "darker" (#141414)
		--   light: "light" (#ffffff), "light_transparent"
		variant = "default",
		italics = {
			comments  = true,
			keywords  = true,
			functions = true,
			strings   = true,
			variables = true,
			bufferline = false,
		},
		-- Global highlight overrides applied after all integrations.
		-- Can be a table or a function returning a table.
		overrides = {},
		-- Per-variant overrides applied after global overrides.
		-- Keys are variant names, values are tables or functions like overrides.
		-- Example:
		--   polish_hl = {
		--     dark_blue = { Normal = { fg = "#c0d8f0" } },
		--   }
		polish_hl = {},
	},
}

setmetatable(config, { __index = config.defaults })

return config
