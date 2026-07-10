-- LOAD THEME FIRST to define all highlight groups
local theme = require("Deadlock.my-theme.init")

-- ─── Utils ────────────────────────────────────────────────────────────────

local function parse_theme_variant(name)
	local theme_name, variant = name:match("^(.-)%-(.+)$")
	return theme_name, variant
end

-- Force-load the lazy plugin that owns a given colorscheme name.
local function lazy_load_for(cs_name)
	local ok, lazy_cfg = pcall(require, "lazy.core.config")
	if not ok then
		return
	end
	for _, plugin in pairs(lazy_cfg.plugins) do
		if plugin.dir then
			local cd = plugin.dir .. "/colors/"
			if
				vim.fn.filereadable(cd .. cs_name .. ".lua") == 1
				or vim.fn.filereadable(cd .. cs_name .. ".vim") == 1
			then
				-- Only add to rtp — avoid lazy.load() which would trigger the
				-- plugin's auto-config and emit "Lua module not found" warnings.
				vim.opt.rtp:append(plugin.dir)
				return
			end
		end
	end
end

local function apply_external(name)
	local theme_name, variant = parse_theme_variant(name)

	-- Special cases (themes with internal variants)
	if theme_name == "tokyonight" and variant then
		lazy_load_for("tokyonight")
		require("tokyonight").setup({ style = variant })
		return pcall(vim.cmd.colorscheme, "tokyonight")
	end

	lazy_load_for(name)
	return pcall(vim.cmd.colorscheme, name)
end

-- ─── Restore saved state ───────────────────────────────────────────────────

-- Formats:
--   "nw:<variant>"  → Night Wolf variant
--   "ext:<name>"    → external colorscheme plugin
--   "<variant>"     → legacy, treated as nw
local _saved = (function()
	local f = io.open(vim.fn.stdpath("data") .. "/my-theme-variant", "r")
	if not f then
		return nil
	end
	local line = f:read("*l")
	f:close()
	if not line or line == "" then
		return nil
	end

	local ext = line:match("^ext:(.+)$")
	if ext then
		return { kind = "ext", name = ext }
	end

	local nw = line:match("^nw:(.+)$") or line
	return { kind = "nw", name = nw }
end)()

-- ─── Apply Night Wolf (base always loads) ──────────────────────────────────

theme.setup({
	-- Variants: "default", "black", "dark", "darker", "dark_blue", "light", "light_transparent"
	variant = (_saved and _saved.kind == "nw") and _saved.name or "black",
	italics = {
		comments = true,
		keywords = true,
		functions = false,
		strings = false,
		variables = false,
	},
})

theme.colorscheme()

-- ─── Apply external theme (after plugins load) ─────────────────────────────

if _saved and _saved.kind == "ext" then
	vim.api.nvim_create_autocmd("User", {
		pattern = "VeryLazy",
		once = true,
		callback = function()
			local ok = apply_external(_saved.name)

			if not ok then
				vim.notify("Could not load colorscheme: " .. _saved.name, vim.log.levels.WARN, { title = "theme" })
			end
		end,
	})
end

-- ─── LOAD MAIN MODULES (includes lazy.nvim and plugins) ────────────────────
require("Deadlock.config")
