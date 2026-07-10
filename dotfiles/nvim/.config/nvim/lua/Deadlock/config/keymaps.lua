local key = vim.keymap.set

-- ============================================================================
-- GENERAL
-- ============================================================================

-- Disable Q (Ex mode — nunca útil en workflow moderno)
key("n", "Q", "<nop>")

-- Clear search highlighting
key("n", "<Esc>", "<cmd>nohl<CR>", { desc = "Clear search highlights" })
key("n", "<C-c>", "<cmd>nohl<CR>", { desc = "Clear search highlights" })

-- ============================================================================
-- FILE OPERATIONS
-- ============================================================================

-- Save — C-s funciona en Wayland/Hyprland sin XON/XOFF
key({ "n", "i", "v" }, "<C-s>", "<cmd>w<CR><Esc>", { desc = "Save file" })

-- Quit
key("n", "<leader>q", vim.cmd.quit, { desc = "Quit" })
key("n", "<leader>qa", function()
	vim.cmd.qall()
end, { desc = "Quit all" })
key("n", "<leader>Q", function()
	vim.cmd("qa!")
end, { desc = "Quit all (force)" })

-- Utilidades de archivo — grupo <leader>f
key("n", "<leader>fn", vim.cmd.enew, { desc = "New file" })

key("n", "<leader>fp", function()
	local path = vim.fn.expand("%:~")
	vim.fn.setreg("+", path)
	vim.notify("Path copiado: " .. path, vim.log.levels.INFO)
end, { desc = "Copy file path" })

key("n", "<leader>fx", function()
	local file = vim.fn.expand("%")
	vim.fn.system("chmod +x " .. vim.fn.shellescape(file))
	vim.notify("chmod +x: " .. file, vim.log.levels.INFO)
end, { desc = "Make file executable" })

-- ============================================================================
-- BUFFER NAVIGATION
-- ============================================================================

-- Dos estilos: bracket (convención Vim) + Shift-h/l (home row, más rápido)
-- Se eliminó <S-Left>/<S-Right> — arrow keys en normal mode = mala ergonomía
key("n", "[b", "<cmd>bprevious<CR>", { desc = "Previous buffer" })
key("n", "]b", "<cmd>bnext<CR>", { desc = "Next buffer" })
key("n", "<S-h>", "<cmd>bprevious<CR>", { desc = "Previous buffer" })
key("n", "<S-l>", "<cmd>bnext<CR>", { desc = "Next buffer" })

-- Buffer management
key("n", "<leader>bd", function()
	require("snacks").bufdelete()
end, { desc = "Delete buffer" })

key("n", "<leader>bD", function()
	require("snacks").bufdelete({ force = true })
end, { desc = "Delete buffer (force)" })

key("n", "<leader>bo", function()
	require("snacks").bufdelete.other()
end, { desc = "Delete other buffers" })

-- ============================================================================
-- WINDOW / SPLIT MANAGEMENT
-- ============================================================================

-- Splits — un solo par de atajos (sin duplicados con <leader>wh/wv)
key("n", "<leader>-", "<C-w>s", { desc = "Split horizontal" })
key("n", "<leader>|", "<C-w>v", { desc = "Split vertical" })

-- Window operations bajo <leader>w (which-key tiene proxy <c-w> aquí)
key("n", "<leader>we", "<C-w>=", { desc = "Equalize splits" })
key("n", "<leader>wx", "<cmd>close<CR>", { desc = "Close split" })
key("n", "<leader>wo", "<C-w>o", { desc = "Close other splits" })
key("n", "<leader>wm", "<cmd>WindowsMaximize<CR>", { desc = "Maximize split (toggle)" })

-- Navigate between splits — C-hjkl (Hyprland usa Mod+hjkl, sin conflicto)
key("n", "<C-h>", "<C-w>h", { desc = "Go to left window" })
key("n", "<C-j>", "<C-w>j", { desc = "Go to lower window" })
key("n", "<C-k>", "<C-w>k", { desc = "Go to upper window" })
key("n", "<C-l>", "<C-w>l", { desc = "Go to right window" })

-- Resize splits — C-Arrow (acciones poco frecuentes, arrow keys aceptables aquí)
key("n", "<C-Up>", "<cmd>resize +2<CR>", { desc = "Increase window height" })
key("n", "<C-Down>", "<cmd>resize -2<CR>", { desc = "Decrease window height" })
key("n", "<C-Left>", "<cmd>vertical resize -2<CR>", { desc = "Decrease window width" })
key("n", "<C-Right>", "<cmd>vertical resize +2<CR>", { desc = "Increase window width" })

-- ============================================================================
-- TAB MANAGEMENT  (<leader><tab> group)
-- ============================================================================

-- Tab/S-Tab reservados para blink.cmp en insert. En normal mode:
key("n", "<leader><tab><tab>", "<cmd>tabnew<CR>", { desc = "New tab" })
key("n", "<leader><tab>n", "<cmd>tabnew<CR>", { desc = "New tab" })
key("n", "<leader><tab>x", "<cmd>tabclose<CR>", { desc = "Close tab" })
key("n", "<leader><tab>o", "<cmd>tabonly<CR>", { desc = "Close other tabs" })
key("n", "<leader><tab>f", "<cmd>tabnew %<CR>", { desc = "Buffer in new tab" })
key("n", "<leader><tab>]", "<cmd>tabn<CR>", { desc = "Next tab" })
key("n", "<leader><tab>[", "<cmd>tabp<CR>", { desc = "Previous tab" })
-- Navegación de tabs con gt/gT (nativa de Vim — mejor que Tab en normal mode)

-- ============================================================================
-- TEXT EDITING
-- ============================================================================

-- Comentar — delegado a ts-comments (gc/gcc)
key("n", "<leader>/", "gcc", { desc = "Toggle comment", remap = true })
key("v", "<leader>/", "gc", { desc = "Toggle comment", remap = true })

-- Mover líneas con Alt — consistente en todos los modos, sin solapar J/K built-in
-- J/K visual built-in (join lines en visual) se preserva
key("n", "<M-j>", function()
	vim.cmd("m .+1")
	vim.cmd("normal! ==")
end, { desc = "Move line down" })
key("n", "<M-k>", function()
	vim.cmd("m .-2")
	vim.cmd("normal! ==")
end, { desc = "Move line up" })
key("v", "<M-j>", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
key("v", "<M-k>", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- Indent en visual — mantiene la selección
key("v", "<", "<gv", { desc = "Indent left" })
key("v", ">", ">gv", { desc = "Indent right" })

-- Paste sin perder el registro en visual
key("v", "p", '"_dP', { desc = "Paste without yanking selection" })

-- Join lines preservando posición del cursor
key("n", "J", "mzJ`z", { desc = "Join lines" })

-- Scroll centrado — esencial para mantener contexto visual
key("n", "<C-d>", "<C-d>zz", { desc = "Scroll down (centered)" })
key("n", "<C-u>", "<C-u>zz", { desc = "Scroll up (centered)" })
key("n", "n", "nzzzv", { desc = "Next match (centered)" })
key("n", "N", "Nzzzv", { desc = "Prev match (centered)" })

-- ============================================================================
-- SEARCH & REPLACE  (<leader>s group)
-- ============================================================================

-- Sustitución rápida de la palabra bajo cursor (sin abrir grug-far)
-- Deja el cursor antes de <CR> para editar el reemplazo
key("n", "<leader>ss", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], {
	desc = "Substitute word (global)",
})
key("v", "<leader>ss", [[:s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], {
	desc = "Substitute word (selection)",
})
-- <leader>sr → grug-far (configurado en grug-far.lua)

-- ============================================================================
-- CODE / LSP  (<leader>c group)
-- ============================================================================

-- Format — un solo atajo, aquí y en conform.lua se unifica en <leader>cf
-- (se eliminó <leader>mp de conform.lua para no duplicar)
key({ "n", "v" }, "<leader>cf", function()
	require("conform").format({ lsp_format = "fallback", async = false, timeout_ms = 1000 })
end, { desc = "Format file or range" })

-- Diagnostics
key("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Line diagnostics" })

-- Toggle diagnostics — estado persistente en la sesión
local _diag_visible = true
key("n", "<leader>ud", function()
	_diag_visible = not _diag_visible
	vim.diagnostic.config({
		virtual_text = _diag_visible,
		underline = _diag_visible,
		signs = _diag_visible,
	})
	vim.notify("Diagnostics " .. (_diag_visible and "on" or "off"))
end, { desc = "Toggle diagnostics" })

-- Navegación de diagnósticos — consistente con ]h/[h de gitsigns
key("n", "]d", function()
	vim.diagnostic.goto_next({ float = true })
end, { desc = "Next diagnostic" })
key("n", "[d", function()
	vim.diagnostic.goto_prev({ float = true })
end, { desc = "Prev diagnostic" })

-- ============================================================================
-- LSP  (<leader>l group — keymaps globales; buffer-local en lspconfig LspAttach)
-- ============================================================================

-- Restart LSP del buffer actual (buffer-local también en lspconfig.lua)
key("n", "<leader>lr", function()
	vim.lsp.stop_client(vim.lsp.get_clients({ bufnr = 0 }))
	vim.cmd("edit")
end, { desc = "Restart LSP" })

-- Toggle inlay hints (global — el buffer-local en LspAttach usa <leader>uh)
key("n", "<leader>li", function()
	local enabled = vim.lsp.inlay_hint.is_enabled()
	vim.lsp.inlay_hint.enable(not enabled)
	vim.notify("Inlay hints " .. (not enabled and "on" or "off"))
end, { desc = "Toggle inlay hints (global)" })

-- Log del LSP (útil para debugging)
key("n", "<leader>ll", "<cmd>LspLog<CR>", { desc = "LSP log" })
key("n", "<leader>lI", "<cmd>LspInfo<CR>", { desc = "LSP info" })

-- ============================================================================
-- PLUGIN MANAGERS  (<leader>L / <leader>pm)
-- ============================================================================

key("n", "<leader>L", "<cmd>Lazy<CR>", { desc = "Lazy" })
key("n", "<leader>lm", "<cmd>Mason<CR>", { desc = "Mason" })
-- Nota: <leader>lm bajo el grupo LSP es coherente (Mason gestiona LSP servers)

-- ============================================================================
-- FILE EXPLORER
-- ============================================================================

-- Oil como explorador primario — \ para acceso ultra-rápido (1 tecla)
key("n", "\\", "<cmd>Oil<CR>", { desc = "Open parent dir (Oil)" })
key("n", "<leader>e", "<cmd>Oil<CR>", { desc = "Explorer (Oil)" })

-- ============================================================================
-- TERMINAL
-- ============================================================================

-- Snacks maneja <C-/> en normal y terminal mode (configurado en snacks.lua).
-- Solo se mantiene la salida de terminal mode aquí:
key("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- ============================================================================
-- TROUBLE  (<leader>x group) — añadido <leader>xx para toggle principal
-- ============================================================================

key("n", "<leader>xx", "<cmd>Trouble diagnostics toggle<CR>", { desc = "Toggle Trouble" })

-- ============================================================================
-- UI / TOGGLE  (<leader>u group)
-- ============================================================================

-- Cambiar variante del tema en runtime (picker estilo NvChad con preview live)
key("n", "<leader>uv", function()
	require("Deadlock.config.theme-picker").open()
end, { desc = "Theme variant" })

-- ============================================================================
-- COMMAND LINE — edición estilo shell (Home Row en cmdline)
-- ============================================================================

key("c", "<C-a>", "<Home>", { desc = "Start of line" })
key("c", "<C-e>", "<End>", { desc = "End of line" })
key("c", "<M-b>", "<S-Left>", { desc = "Word backward" })
key("c", "<M-f>", "<S-Right>", { desc = "Word forward" })

-- ============================================================================
-- CHEAT SHEET
-- ============================================================================

-- <F1> reasignado a help de Neovim (más útil que duplicar <leader>pk)
-- El cheat sheet de keymaps está en <leader>pk (snacks picker)
key("n", "<F1>", "<cmd>help<CR>", { desc = "Neovim help" })

-- Buffer-local keymaps (which-key)
-- <leader>? está configurado en which-key.lua

-- ============================================================================
-- MAN SHEET
-- ============================================================================
key("n", "K", "<cmd>Man<CR>", { desc = "Open man pages" })
