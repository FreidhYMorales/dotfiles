local M = {}

-- ─── Constants ────────────────────────────────────────────────────────────────

local VARIANTS = {
	"default",
	"black",
	"dark",
	"darker",
	"dark_blue",
	"light",
	"light_transparent",
	"terminal",
}

local STATE_FILE = vim.fn.stdpath("data") .. "/my-theme-variant"

-- ─── Debounce ──────────────────────────────────────────────────────────────
local function debounce(fn, ms)
	local timer = vim.loop.new_timer()
	return function(...)
		local args = { ... }
		timer:stop()
		timer:start(ms, 0, function()
			vim.schedule(function()
				fn(unpack(args))
			end)
		end)
	end
end

-- ─── Persistence ──────────────────────────────────────────────────────────────

-- Returns { kind = "nw"|"ext", name = "..." } or nil
local function read_saved()
	local f = io.open(STATE_FILE, "r")
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
	for _, v in ipairs(VARIANTS) do
		if v == nw then
			return { kind = "nw", name = nw }
		end
	end
	return nil
end

-- Public: still used by init.lua to restore the NW variant on startup
function M.read_saved_variant()
	local saved = read_saved()
	if saved and saved.kind == "nw" then
		return saved.name
	end
	return nil
end

local function save(kind, name)
	local f = io.open(STATE_FILE, "w")
	if f then
		f:write(kind == "ext" and ("ext:" .. name) or ("nw:" .. name))
		f:close()
	end
end

-- ─── Apply ────────────────────────────────────────────────────────────────────

local function apply_nw(variant)
	local t = require("Deadlock.my-theme.init")
	local cfg = require("Deadlock.my-theme.config")
	t.setup({ variant = variant, italics = cfg.italics, overrides = cfg.overrides })
	t.colorscheme()
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
			if vim.fn.filereadable(cd .. cs_name .. ".lua") == 1
				or vim.fn.filereadable(cd .. cs_name .. ".vim") == 1 then
				vim.opt.rtp:append(plugin.dir)
				return
			end
		end
	end
end

local function apply_item(item)
	if item.kind == "nw" then
		apply_nw(item.name)
	elseif item.kind == "ext" then
		lazy_load_for(item.name)
		local ok, err = pcall(vim.cmd.colorscheme, item.name)
		if not ok then
			vim.notify("Could not apply: " .. item.name .. "\n" .. err, vim.log.levels.WARN, { title = "theme" })
		end
	end
end

-- ─── Preview Theme ────────────────────────────────────────────────────────────────────

local function preview_theme(item, state)
	if not item or item.kind == "sep" then
		return
	end

	if state.last_preview == item.name and state.last_kind == item.kind then
		return
	end

	state.last_preview = item.name
	state.last_kind = item.kind

	apply_item(item)

	-- redraw limpio
	vim.cmd("redraw")
end

-- ─── Plugin colorscheme discovery ─────────────────────────────────────────────

local function get_plugin_colorschemes()
	local ok, lazy_config = pcall(require, "lazy.core.config")
	if not ok then
		return {}
	end
	local themes, seen = {}, {}
	for _, plugin in pairs(lazy_config.plugins) do
		if plugin.dir then
			local colors_dir = plugin.dir .. "/colors"
			if vim.fn.isdirectory(colors_dir) == 1 then
				for _, file in ipairs(vim.fn.glob(colors_dir .. "/*", false, true)) do
					local name = vim.fn.fnamemodify(file, ":t:r")
					-- Skip empty names and Night Wolf itself
					if name ~= "" and name ~= "my-theme" and not seen[name] then
						seen[name] = true
						table.insert(themes, name)
					end
				end
			end
		end
	end
	table.sort(themes)
	return themes
end

-- ─── Picker ───────────────────────────────────────────────────────────────────

function M.open()
	local cfg = require("Deadlock.my-theme.config")
	local saved = read_saved()

	local state = {
		last_preview = nil,
		last_kind = nil,
	}

	-- Detect the current state so we can revert on cancel
	local original_kind, original_name
	if vim.g.colors_name == "my-theme" then
		original_kind = "nw"
		original_name = cfg.variant or "black"
	else
		original_kind = "ext"
		original_name = vim.g.colors_name or "my-theme"
	end
	local current_kind, current_name = original_kind, original_name

	-- ── Build item list ──────────────────────────────────────────────────────
	-- NW section: current NW variant floats to the top so the cursor opens on it
	local items = {}
	for _, v in ipairs(VARIANTS) do
		local entry = { text = v, kind = "nw", name = v }
		if v == original_name and original_kind == "nw" then
			table.insert(items, 1, entry)
		else
			table.insert(items, entry)
		end
	end

	-- Plugin section (only when plugins with a colors/ dir are installed)
	local ext_themes = get_plugin_colorschemes()
	if #ext_themes > 0 then
		table.insert(items, { text = " ── plugins ──", kind = "sep", name = "" })
		for _, cs in ipairs(ext_themes) do
			table.insert(items, { text = cs, kind = "ext", name = cs })
		end
	end

	local confirmed = false

	require("snacks").picker({
		title = " Theme Variant ",
		finder = function()
			return items
		end,

		format = function(item)
			if item.kind == "sep" then
				return { { item.text, "Comment" } }
			end

			local is_saved = saved and saved.kind == item.kind and saved.name == item.name

			local is_current = current_kind == item.kind and current_name == item.name

			local prefix = "   "
			if is_current then
				prefix = " ▶ "
			elseif is_saved then
				prefix = " ● "
			end

			local name_hl = item.kind == "nw" and "Normal" or "SnacksPickerFile"

			return {
				{ prefix, "SnacksPickerSpecial" },
				{ item.text, name_hl },
			}
		end,

		-- Live preview: apply the focused theme while browsing
		on_change = debounce(function(_, item)
			preview_theme(item, state)
		end, 80),

		actions = {
			confirm = function(picker, item)
				if not item or item.kind == "sep" then
					return
				end
				confirmed = true
				if item.kind ~= current_kind or item.name ~= current_name then
					save(item.kind, item.name)
				end
				picker:close()
				local label = item.kind == "nw" and ("Night Wolf › " .. item.name) or ("Plugin › " .. item.name)
				vim.notify(label, vim.log.levels.INFO, { title = "theme" })
			end,
		},

		-- Cancel: revert to whatever was active when the picker opened
		on_close = function()
			if not confirmed then
				if original_kind == "nw" then
					apply_nw(original_name)
				else
					vim.cmd.colorscheme(original_name)
				end
			end
		end,

		layout = {
			preset = "select",
			preview = false,
			layout = {
				backdrop = false,
				min_width = 32,
				border = "rounded",
				title = " Theme Variant ",
				title_pos = "center",
				box = "vertical",
				config = function(layout)
					for _, box in ipairs(layout.layout) do
						if box.win == "list" and not box.height then
							box.height = math.min(#items, 15)
						end
					end
				end,
			},
		},
	})
end

return M
