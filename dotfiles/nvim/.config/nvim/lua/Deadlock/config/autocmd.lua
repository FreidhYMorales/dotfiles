local acmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup

-- Highlight on yank (moved from keymaps.lua where it doesn't belong)
acmd("TextYankPost", {
	desc = "Highlight when yanking text",
	group = augroup("highlight-yank", { clear = true }),
	callback = function()
		vim.hl.on_yank()
	end,
})

-- Restore cursor position when reopening files
acmd("BufReadPost", {
	group = augroup("restore-cursor", { clear = true }),
	callback = function(ev)
		-- Commit/rebase messages are new each time: an old position is wrong
		if vim.tbl_contains({ "gitcommit", "gitrebase" }, vim.bo[ev.buf].filetype) then
			return
		end
		local mark = vim.api.nvim_buf_get_mark(ev.buf, '"')
		local lcount = vim.api.nvim_buf_line_count(ev.buf)
		if mark[1] > 0 and mark[1] <= lcount then
			pcall(vim.api.nvim_win_set_cursor, 0, mark)
		end
	end,
})

-- Auto-resize splits on terminal resize
acmd("VimResized", {
	group = augroup("auto-resize", { clear = true }),
	callback = function()
		local current_tab = vim.fn.tabpagenr()
		vim.cmd("tabdo wincmd =")
		vim.cmd("tabnext " .. current_tab)
	end,
})

-- Close certain buffer types with q
acmd("FileType", {
	group = augroup("close-with-q", { clear = true }),
	-- man and checkhealth already map q natively
	pattern = { "help", "qf", "dap-float" },
	callback = function(ev)
		vim.bo[ev.buf].buflisted = false
		vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = ev.buf, silent = true })
	end,
})

-- Auto-save on focus lost or buffer leave.
-- vim.b.autosaving makes conform skip format-on-save, so switching buffers
-- never blocks on a synchronous formatter; manual :w still formats.
acmd({ "FocusLost", "BufLeave" }, {
	group = augroup("auto-save", { clear = true }),
	callback = function(ev)
		local buf = ev.buf
		if vim.bo[buf].modified and vim.bo[buf].buftype == "" and vim.api.nvim_buf_get_name(buf) ~= "" then
			vim.b[buf].autosaving = true
			vim.api.nvim_buf_call(buf, function()
				vim.cmd("silent! write")
			end)
			vim.b[buf].autosaving = false
		end
	end,
})

-- Enable spell only for prose filetypes
acmd("FileType", {
	group = augroup("enable-spell", { clear = true }),
	pattern = { "markdown", "text", "gitcommit", "plaintex", "tex" },
	callback = function()
		vim.opt_local.spell = true
	end,
})
