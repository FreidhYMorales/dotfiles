local opt = vim.opt

-- PROVIDERS
vim.g.python3_host_prog = "/usr/bin/pynvim-python"
vim.g.ruby_host_prog = vim.fn.expand("~/.local/share/gem/ruby/3.4.0/bin/neovim-ruby-host")

-- MOUSE
opt.mouse = "a"

-- PERFORMANCE
opt.updatetime = 200 -- Faster completion (default 4000ms)
opt.timeoutlen = 300 -- Faster key sequence completion (better for which-key)

-- INDENTATION
-- Convención del proyecto: tabs reales, ancho visual = 4 columnas.
-- Para lenguajes que requieren espacios (Python, YAML) se sobreescribe
-- con expandtab=true vía autocmd FileType en autocmd.lua.
opt.shiftwidth = 4 -- columnas por nivel de indentación (>> / <<)
opt.tabstop = 4 -- ancho visual de un carácter tab
opt.softtabstop = 0 -- 0 = deshabilita softtabstop (usa tabstop directamente)
opt.expandtab = false -- tabs reales, no espacios
opt.autoindent = true
opt.smartindent = true

-- NUMBER and RNUMBER
opt.nu = true
opt.relativenumber = true

--TEXT and SPELL
opt.wrap = false
opt.linebreak = true -- Wrap on word boundary
opt.colorcolumn = "80"
opt.showmatch = true
opt.ignorecase = true
opt.smartcase = true -- Don't ignore case with capitals
opt.wildmode = { "longest", "list" }
opt.cursorline = true
opt.formatoptions = "jcroqlnt" -- tcqj (better text formatting)
opt.grepformat = "%f:%l:%c:%m"
opt.grepprg = "rg --vimgrep" -- Use ripgrep for :grep
opt.virtualedit = "block" -- Allow cursor to move where there is no text in visual block mode
opt.smoothscroll = true -- Smooth scrolling
opt.spelllang = { "en", "es" } -- Spell check languages
opt.spelloptions = "camel" -- Treat CamelCase words as separate words
-- Spell enabled per filetype in autocmd.lua (markdown, text, gitcommit)

-- CLIPBOARD
opt.clipboard = "unnamedplus"

-- BACKUP and UNDO
opt.swapfile = false
opt.backup = false
opt.writebackup = false -- Don't make a backup before overwriting a file
opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
opt.undofile = true
opt.undolevels = 10000 -- Maximum number of changes that can be undone

-- SEARCH
opt.inccommand = "split" -- Preview incremental substitution
opt.incsearch = true -- Show search matches as you type

--SPLIT WINDOW
opt.splitright = true
opt.splitbelow = true

-- MISC
opt.scrolloff = 10 -- Lines of context
opt.sidescrolloff = 8 -- Columns of context
opt.signcolumn = "yes" -- Always show the signcolumn
opt.hlsearch = true -- Highlight search results
opt.confirm = true -- Confirm to save changes before exiting modified buffer
opt.laststatus = 3 -- Global statusline
opt.pumblend = 10 -- Popup blend (transparency for completion menu)
opt.pumheight = 10 -- Maximum number of entries in a popup
opt.sessionoptions = { "buffers", "curdir", "tabpages", "winsize", "help", "globals", "skiprtp", "folds" }
opt.shortmess:append({ W = true, I = true, c = true, C = true }) -- Reduce command line messages
opt.showmode = false -- Don't show mode since we have a statusline
opt.termguicolors = true -- True color support (moved from init.lua)
vim.g.netrw_banner = 0
-- Highlight groups handled by my-theme (set_background_transparent)
