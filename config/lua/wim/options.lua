-- ============================================================
--  WIM — options.lua
--  Windows-aware Neovim settings
-- ============================================================

local opt = vim.opt

-- ---- Windows: disable unused providers to avoid errors ----
if vim.fn.has("win32") == 1 then
    vim.g.loaded_python3_provider = 0
    vim.g.loaded_ruby_provider    = 0
    vim.g.loaded_perl_provider    = 0
    vim.g.loaded_node_provider    = 0
end

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

-- ---- Windows Terminal auto detection ---------------------------
-- Detects which terminal is running and configures accordingly.
-- Supports: Windows Terminal, Alacritty, ConEmu, Cmder, plain cmd
if vim.fn.has("win32") == 1 then
    local function detect_terminal()
        -- WT_SESSION is only set by Windows Terminal
        if vim.fn.getenv("WT_SESSION") ~= vim.NIL then
            return "windows-terminal"
        end
        -- Alacritty sets this env var
        if vim.fn.getenv("ALACRITTY_LOG") ~= vim.NIL then
            return "alacritty"
        end
        -- ConEmu sets this
        if vim.fn.getenv("ConEmuPID") ~= vim.NIL then
            return "conemu"
        end
        return "unknown"
    end

    local term = detect_terminal()
    vim.g.wim_terminal = term

    if term == "windows-terminal" then
        -- Windows Terminal supports full truecolor + undercurl
        vim.opt.termguicolors = true
        vim.opt.pumblend      = 10    -- popup transparency
        vim.opt.winblend      = 10    -- window transparency
    elseif term == "alacritty" then
        -- Alacritty supports truecolor
        vim.opt.termguicolors = true
        vim.opt.pumblend      = 0
    elseif term == "conemu" then
        -- ConEmu has limited true color support
        vim.opt.termguicolors = true
        -- Disable undercurl as ConEmu doesn't support it
        vim.cmd("hi DiagnosticUnderlineError gui=underline")
        vim.cmd("hi DiagnosticUnderlineWarn  gui=underline")
    else
        -- Unknown terminal - safe fallbacks
        vim.opt.termguicolors = true
    end
end

-- ---- WSL path confusion fix ------------------------------------
-- When WSL is installed alongside Windows Neovim, LSP servers
-- sometimes return /mnt/c/... paths instead of C:\... paths.
-- This normalizes all paths to Windows format.
if vim.fn.has("win32") == 1 then
    -- Detect if WSL is present
    local wsl_check = vim.fn.system("wsl --status 2>nul")
    local has_wsl   = vim.v.shell_error == 0

    if has_wsl then
        -- Override LSP path handling to normalize WSL paths
        local orig_uri_to_fname = vim.uri_to_fname
        vim.uri_to_fname = function(uri)
            local fname = orig_uri_to_fname(uri)
            -- Convert /mnt/c/... to C:\...
            fname = fname:gsub("^/mnt/(%a)/", function(drive)
                return drive:upper() .. ":\"
            end)
            -- Normalize remaining forward slashes
            fname = fname:gsub("/", "\")
            return fname
        end

        local orig_fname_to_uri = vim.uri_from_fname
        vim.uri_from_fname = function(fname)
            -- Normalize Windows paths before converting to URI
            fname = fname:gsub("\", "/")
            fname = fname:gsub("^(%a):/", function(drive)
                return "/" .. drive:lower() .. "/"
            end)
            return orig_fname_to_uri(fname)
        end
    end
end

-- ---- Performance -------------------------------------------
opt.updatetime     = 200          -- faster CursorHold events
opt.timeoutlen     = 300          -- which-key popup delay
opt.redrawtime     = 1500
opt.synmaxcol      = 300          -- don't highlight very long lines