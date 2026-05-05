-- ============================================================
--  WIM — options.lua
--  Windows-aware Neovim settings
-- ============================================================

local opt = vim.opt

-- ---- Leader key --------------------------------------------
vim.g.mapleader      = " "
vim.g.maplocalleader = " "

-- ---- UI ----------------------------------------------------
opt.number         = true
opt.relativenumber = true
opt.signcolumn     = "yes"
opt.cursorline     = true
opt.termguicolors  = true
opt.showmode       = false        -- lualine handles this
opt.pumheight      = 10           -- max autocomplete items
opt.scrolloff      = 8
opt.sidescrolloff  = 8
opt.wrap           = false
opt.splitright     = true
opt.splitbelow     = true
opt.laststatus     = 3            -- single global statusline

-- ---- Editing -----------------------------------------------
opt.tabstop        = 4
opt.shiftwidth     = 4
opt.expandtab      = true
opt.smartindent    = true
opt.autoindent     = true
opt.iskeyword:append("-")

-- ---- Search ------------------------------------------------
opt.ignorecase     = true
opt.smartcase      = true
opt.hlsearch       = false
opt.incsearch      = true

-- ---- Files & Encoding --------------------------------------
opt.encoding       = "utf-8"
opt.fileencoding   = "utf-8"
opt.undofile       = true         -- persistent undo across sessions

-- ---- Windows specific: fix clipboard -----------------------
-- win32yank is the most reliable clipboard provider on Windows
if vim.fn.has("win32") == 1 then
    vim.g.clipboard = {
        name  = "win32yank",
        copy  = {
            ["+"] = "win32yank.exe -i --crlf",
            ["*"] = "win32yank.exe -i --crlf",
        },
        paste = {
            ["+"] = "win32yank.exe -o --lf",
            ["*"] = "win32yank.exe -o --lf",
        },
        cache_enabled = 0,
    }
end

-- ---- Windows specific: normalize paths ---------------------
-- Neovim on Windows sometimes returns mixed separators.
-- This ensures all internal path operations use forward slashes.
if vim.fn.has("win32") == 1 then
    vim.fn.setenv("NVIM_WIN_PATHS", "1")
end

-- ---- Performance -------------------------------------------
opt.updatetime     = 200          -- faster CursorHold events
opt.timeoutlen     = 300          -- which-key popup delay
opt.redrawtime     = 1500
opt.synmaxcol      = 300          -- don't highlight very long lines
