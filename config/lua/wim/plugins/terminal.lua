-- ============================================================
--  WIM — plugins/terminal.lua
-- ============================================================

return {
    {
        "akinsho/toggleterm.nvim",
        version = "*",
        event   = "VeryLazy",
        opts    = {
            size      = 15,
            direction = "horizontal",
            -- Windows: default to PowerShell
            shell     = vim.fn.has("win32") == 1
                and (vim.fn.executable("pwsh") == 1 and "pwsh" or "powershell")
                or  vim.o.shell,
            float_opts = { border = "curved" },
            highlights = {
                Normal         = { link = "Normal" },
                NormalFloat    = { link = "Normal" },
                FloatBorder    = { link = "FloatBorder" },
            },
        },
    },
}