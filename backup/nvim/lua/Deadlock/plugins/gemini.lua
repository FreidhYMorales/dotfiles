-- Use snacks terminal for proper show/hide toggle instead of the plugin's own
-- window management (which destroys/recreates on each toggle).
-- A fixed cwd makes the terminal ID stable so the same instance is always reused.
local GEMINI_CWD = vim.fn.expand("~")
local GEMINI_WIN_OPTS = {
	win = { position = "left", width = 0.30 },
	cwd = GEMINI_CWD,
	auto_close = true,
	interactive = true,
}

local function gemini_send()
	local term = require("snacks").terminal.get("gemini", { cwd = GEMINI_CWD, create = false })
	if not term or not term:buf_valid() then
		vim.notify("Gemini is not running. Open it with <leader>ag first.", vim.log.levels.WARN)
		return
	end
	local _, sl, sc, _ = unpack(vim.fn.getpos("'<"))
	local _, el, ec, _ = unpack(vim.fn.getpos("'>"))
	if sl == 0 or el == 0 then
		return
	end
	local lines = vim.api.nvim_buf_get_lines(0, sl - 1, el, false)
	if #lines == 0 then
		return
	end
	if #lines == 1 then
		lines[1] = string.sub(lines[1], sc, ec)
	else
		lines[#lines] = string.sub(lines[#lines], 1, ec)
		lines[1] = string.sub(lines[1], sc)
	end
	local text = table.concat(lines, "\n")
	if text and #text > 0 then
		local ok, chan_id = pcall(vim.api.nvim_buf_get_var, term.buf, "terminal_job_id")
		if ok and chan_id then
			vim.fn.chansend(chan_id, text .. "\n")
			term:focus()
		end
	end
end

return {
	"jonroosevelt/gemini-cli.nvim",
	keys = {
		{
			"<leader>ag",
			function()
				require("snacks").terminal.toggle("gemini", GEMINI_WIN_OPTS)
			end,
			desc = "Toggle Gemini",
		},
		{
			"<leader>aG",
			gemini_send,
			mode = "v",
			desc = "Send selection to Gemini",
		},
	},
}
