-- ============================================================
--  WIM — autocmds.lua
-- ============================================================

local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

-- ---- Highlight on yank -------------------------------------
augroup("YankHighlight", { clear = true })
autocmd("TextYankPost", {
    group    = "YankHighlight",
    callback = function()
        vim.highlight.on_yank({ higroup = "IncSearch", timeout = 150 })
    end,
})

-- ---- Remove trailing whitespace on save --------------------
augroup("TrimWhitespace", { clear = true })
autocmd("BufWritePre", {
    group   = "TrimWhitespace",
    pattern = "*",
    command = "%s/\\s\\+$//e",
})

-- ---- Restore cursor position on file open ------------------
augroup("RestoreCursor", { clear = true })
autocmd("BufReadPost", {
    group    = "RestoreCursor",
    callback = function()
        local mark = vim.api.nvim_buf_get_mark(0, '"')
        local line_count = vim.api.nvim_buf_line_count(0)
        if mark[1] > 0 and mark[1] <= line_count then
            pcall(vim.api.nvim_win_set_cursor, 0, mark)
        end
    end,
})

-- ---- Auto resize splits on terminal resize -----------------
augroup("AutoResize", { clear = true })
autocmd("VimResized", {
    group   = "AutoResize",
    command = "tabdo wincmd =",
})

-- ---- Filetype specific settings ----------------------------
augroup("FileTypeSettings", { clear = true })

-- JS/TS — 2 space indent
autocmd("FileType", {
    group   = "FileTypeSettings",
    pattern = { "javascript", "typescript", "javascriptreact",
                "typescriptreact", "json", "html", "css", "scss" },
    callback = function()
        vim.opt_local.tabstop    = 2
        vim.opt_local.shiftwidth = 2
    end,
})

-- Python — 4 space (PEP8)
autocmd("FileType", {
    group   = "FileTypeSettings",
    pattern = "python",
    callback = function()
        vim.opt_local.tabstop    = 4
        vim.opt_local.shiftwidth = 4
    end,
})

-- ---- WimInfo command ---------------------------------------------
vim.api.nvim_create_user_command("WimInfo", function()
    local lines = {
        "  WIM - Windows Integrated Modular Neovim",
        "  ─────────────────────────────────────────",
        "  Terminal : " .. (vim.g.wim_terminal or "unknown"),
        "  OS       : " .. vim.loop.os_uname().sysname,
        "  Neovim   : " .. tostring(vim.version()),
        "  Config   : " .. vim.fn.stdpath("config"),
        "  Data     : " .. vim.fn.stdpath("data"),
        "  WSL      : " .. (vim.fn.getenv("WSL_DISTRO_NAME") ~= vim.NIL and "yes" or "no"),
        "",
        "  Commands:",
        "  :WimInfo          - show this screen",
        "  :WimClipboardFix  - reconnect clipboard after sleep",
        "  :checkhealth      - full health check",
        "  :Lazy             - plugin manager",
        "  :Mason            - LSP manager",
    }
    vim.notify(table.concat(lines, "
"), vim.log.levels.INFO, { title = "WIM" })
end, { desc = "WIM: Show system info" })

-- ---- Windows: clipboard reconnect after sleep/wake ---------------
-- win32yank sometimes stops working after Windows sleep.
-- This auto-reconnects it when Neovim regains focus.
if vim.fn.has("win32") == 1 then
    augroup("ClipboardReconnect", { clear = true })
    autocmd("FocusGained", {
        group    = "ClipboardReconnect",
        callback = function()
            -- Re-register the clipboard provider on focus
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
            -- Silently verify win32yank is still responsive
            local ok = pcall(vim.fn.system, "win32yank.exe -o --lf")
            if not ok then
                vim.notify(
                    "WIM: Clipboard reconnect failed. Try :WimClipboardFix",
                    vim.log.levels.WARN
                )
            end
        end,
    })

    -- Manual fix command if auto-reconnect fails
    vim.api.nvim_create_user_command("WimClipboardFix", function()
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
        vim.notify("WIM: Clipboard reconnected", vim.log.levels.INFO)
    end, { desc = "WIM: Reconnect win32yank clipboard" })
end

-- ---- Windows: fix line endings on paste --------------------
if vim.fn.has("win32") == 1 then
    augroup("WindowsCRLF", { clear = true })
    autocmd("BufReadPost", {
        group    = "WindowsCRLF",
        callback = function()
            -- Silently convert CRLF to LF in memory
            if vim.bo.modifiable then
                vim.cmd("silent! %s/\\r//g")
            end
        end,
    })
end