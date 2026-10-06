return {
	"lewis6991/gitsigns.nvim",
	event = { "BufReadPost", "BufNewFile", "BufWritePre" },
	opts = {
		signs = {
			add = { text = "▎" },
			change = { text = "▎" },
			delete = { text = "" },
			topdelete = { text = "" },
			changedelete = { text = "▎" },
			untracked = { text = "▎" },
		},
		signs_staged = {
			add = { text = "▎" },
			change = { text = "▎" },
			delete = { text = "" },
			topdelete = { text = "" },
			changedelete = { text = "▎" },
		},
		-- Show blame line by default (can be toggled)
		current_line_blame = false,
		current_line_blame_opts = {
			virt_text = true,
			virt_text_pos = "eol", -- 'eol' | 'overlay' | 'right_align'
			delay = 500,
			ignore_whitespace = false,
		},
		current_line_blame_formatter = "<author>, <author_time:%Y-%m-%d> - <summary>",
		-- Preview options
		preview_config = {
			border = "rounded",
			style = "minimal",
			relative = "cursor",
			row = 0,
			col = 1,
		},
		-- diff_opts left unset on purpose: when set, gitsigns stops following
		-- changes to 'diffopt' (internal diff is already the default)
		update_debounce = 100,
		on_attach = function(buffer)
			local gs = package.loaded.gitsigns

			local function map(mode, l, r, desc)
				vim.keymap.set(mode, l, r, { buffer = buffer, desc = desc, silent = true })
			end

			-- Navigation
			map("n", "]h", function()
				if vim.wo.diff then
					vim.cmd.normal({ "]c", bang = true })
				else
					gs.nav_hunk("next")
				end
			end, "Next Hunk")

			map("n", "[h", function()
				if vim.wo.diff then
					vim.cmd.normal({ "[c", bang = true })
				else
					gs.nav_hunk("prev")
				end
			end, "Prev Hunk")

			map("n", "]H", function()
				gs.nav_hunk("last")
			end, "Last Hunk")

			map("n", "[H", function()
				gs.nav_hunk("first")
			end, "First Hunk")

			-- Stage / Reset Hunks
			map("n", "<leader>ghs", gs.stage_hunk, "Stage Hunk")
			map("v", "<leader>ghs", function()
				gs.stage_hunk({ vim.fn.line("v"), vim.fn.line(".") })
			end, "Stage Hunk")

			map("n", "<leader>ghr", gs.reset_hunk, "Reset Hunk")
			map("v", "<leader>ghr", function()
				gs.reset_hunk({ vim.fn.line("v"), vim.fn.line(".") })
			end, "Reset Hunk")

			map("n", "<leader>ghS", gs.stage_buffer, "Stage Buffer")
			-- (undo_stage_hunk is deprecated: <leader>ghs on a staged hunk unstages it)
			map("n", "<leader>ghR", gs.reset_buffer, "Reset Buffer")

			-- Preview
			map("n", "<leader>ghp", gs.preview_hunk, "Preview Hunk")
			map("n", "<leader>ghP", gs.preview_hunk_inline, "Preview Hunk Inline")

			-- Blame
			map("n", "<leader>ghb", function()
				gs.blame_line({ full = true })
			end, "Blame Line")

			map("n", "<leader>ghB", function()
				gs.blame()
			end, "Blame Buffer")

			map("n", "<leader>gtb", gs.toggle_current_line_blame, "Toggle Line Blame")

			-- Diff
			map("n", "<leader>ghd", gs.diffthis, "Diff This")
			map("n", "<leader>ghD", function()
				gs.diffthis("~")
			end, "Diff This ~")

			-- (toggle_deleted is deprecated: use <leader>ghP, preview_hunk_inline)
			map("n", "<leader>gtw", gs.toggle_word_diff, "Toggle Word Diff")

			-- Text objects
			map({ "o", "x" }, "ih", gs.select_hunk, "GitSigns Select Hunk")
		end,
	},
	keys = {
		-- Additional global keymaps
		{ "<leader>gS", "<cmd>Gitsigns stage_buffer<CR>", desc = "Stage Buffer" },
		{ "<leader>gR", "<cmd>Gitsigns reset_buffer<CR>", desc = "Reset Buffer" },
	},
}
