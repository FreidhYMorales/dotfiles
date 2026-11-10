local key = vim.keymap.set

-- ============================================================================
-- GENERAL
-- ============================================================================

-- Clear search highlighting
key("n", "<Esc>", "<cmd>nohl<CR>", { desc = "Clear search highlights" })
key("n", "<C-c>", "<cmd>nohl<CR>", { desc = "Clear search highlights" })

-- ============================================================================
-- FILE OPERATIONS
-- ============================================================================

-- Save — C-s funciona en Wayland/Hyprland sin XON/XOFF.
-- Sin modo insert: ahí <C-s> es la signature help nativa (0.11+).
key({ "n", "x" }, "<C-s>", "<cmd>w<CR><Esc>", { desc = "Save file" })

-- Quit — <leader>qq (no <leader>q): <leader>q es el prefijo de qa y de
-- persistence (qs/qS/ql/qd), mapearlo solo esperaba timeoutlen y luego salía.
key("n", "<leader>qq", vim.cmd.quit, { desc = "Quit" })
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

-- Shift-h/l (home row). [b/]b ya son defaults de Neovim 0.11+.
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
key("n", "<leader>wm", function()
	require("snacks").zen.zoom()
end, { desc = "Maximize split (toggle)" })

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
key("x", "<leader>/", "gc", { desc = "Toggle comment", remap = true })

-- Mover líneas con Alt — consistente en todos los modos, sin solapar J/K built-in
-- J/K visual built-in (join lines en visual) se preserva
key("n", "<M-j>", function()
	if vim.fn.line(".") == vim.fn.line("$") then
		return
	end
	vim.cmd("m .+1")
	vim.cmd("normal! ==")
end, { desc = "Move line down" })
key("n", "<M-k>", function()
	vim.cmd("m .-2")
	vim.cmd("normal! ==")
end, { desc = "Move line up" })
-- Modo "x" (no "v"): "v" incluye select mode y rompía escribir <, > o p
-- dentro de los placeholders de snippets.
key("x", "<M-j>", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
key("x", "<M-k>", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- Indent en visual — mantiene la selección
key("x", "<", "<gv", { desc = "Indent left" })
key("x", ">", ">gv", { desc = "Indent right" })

-- Paste sin perder el registro en visual: lo hace yanky (yanky.lua, x-mode p)

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
key("x", "<leader>ss", [[:s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], {
	desc = "Substitute word (selection)",
})
-- <leader>sr → grug-far (configurado en grug-far.lua)

-- ============================================================================
-- CODE / LSP  (<leader>c group)
-- ============================================================================

-- Format — un solo atajo, aquí y en conform.lua se unifica en <leader>cf
-- (se eliminó <leader>mp de conform.lua para no duplicar)
key({ "n", "x" }, "<leader>cf", function()
	require("conform").format() -- options from conform's default_format_opts
end, { desc = "Format file or range" })

-- Diagnostics
key("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Line diagnostics" })

-- Toggle diagnostics — enable() conserva la config (íconos de signs custom);
-- reescribir signs = true los reemplazaba por letras.
key("n", "<leader>ud", function()
	local enabled = not vim.diagnostic.is_enabled()
	vim.diagnostic.enable(enabled)
	vim.notify("Diagnostics " .. (enabled and "on" or "off"))
end, { desc = "Toggle diagnostics" })

-- ]d/[d: defaults de Neovim (vim.diagnostic.jump). El float al saltar se
-- configura con jump.on_jump en vim.diagnostic.config (lspconfig.lua).

-- ============================================================================
-- LSP  (<leader>l group — keymaps globales; buffer-local en lspconfig LspAttach)
-- ============================================================================

-- Restart LSP (:lsp restart, 0.12 — vim.lsp.stop_client está deprecado)
key("n", "<leader>lr", "<cmd>lsp restart<CR>", { desc = "Restart LSP" })

-- Toggle inlay hints (global — el buffer-local en LspAttach usa <leader>uh)
key("n", "<leader>li", function()
	local enabled = vim.lsp.inlay_hint.is_enabled()
	vim.lsp.inlay_hint.enable(not enabled)
	vim.notify("Inlay hints " .. (not enabled and "on" or "off"))
end, { desc = "Toggle inlay hints (global)" })

-- Log / info del LSP (:LspLog y :LspInfo ya no existen en lspconfig + 0.12)
key("n", "<leader>ll", function()
	vim.cmd.tabnew(vim.lsp.log.get_filename())
end, { desc = "LSP log" })
key("n", "<leader>lI", "<cmd>checkhealth vim.lsp<CR>", { desc = "LSP info" })

-- ============================================================================
-- PLUGIN MANAGERS  (<leader>L / <leader>pm)
-- ============================================================================

key("n", "<leader>L", "<cmd>Lazy<CR>", { desc = "Lazy" })
key("n", "<leader>lm", "<cmd>Mason<CR>", { desc = "Mason" })
-- Nota: <leader>lm bajo el grupo LSP es coherente (Mason gestiona LSP servers)

-- ============================================================================
-- FILE EXPLORER
-- ============================================================================

-- Oil como explorador primario — \ para acceso ultra-rápido (1 tecla).
-- <leader>ee (no <leader>e): <leader>e es el prefijo del grupo explorer
-- (Yazi en <leader>ey/eY/er), mapearlo solo hacía esperar timeoutlen.
key("n", "\\", "<cmd>Oil<CR>", { desc = "Open parent dir (Oil)" })
key("n", "<leader>ee", "<cmd>Oil<CR>", { desc = "Explorer (Oil)" })

-- ============================================================================
-- TERMINAL
-- ============================================================================

-- Snacks maneja <C-/> en normal y terminal mode (configurado en snacks.lua).
-- Solo se mantiene la salida de terminal mode aquí:
key("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- ============================================================================
-- UI / TOGGLE  (<leader>u group)
-- ============================================================================

-- Cambiar variante del tema en runtime (picker estilo NvChad con preview live)
key("n", "<leader>uv", function()
	require("Deadlock.config.theme-picker").open()
end, { desc = "Theme variant" })

-- Undo tree (built-in since Nvim 0.12; :Undotree toggles the window)
key("n", "<leader>uu", function()
	vim.cmd.packadd("nvim.undotree")
	vim.cmd.Undotree()
end, { desc = "Toggle undo tree" })

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

-- <F1> → :help ya es default de Neovim. Cheat sheet de keymaps: <leader>pk
-- (snacks picker); buffer-local: <leader>? (which-key.lua).
-- K: sin mapeo global — 'keywordprg' por filetype (help, vim, man) y el K
-- buffer-local del LSP (lspconfig.lua) ya cubren todos los casos.
