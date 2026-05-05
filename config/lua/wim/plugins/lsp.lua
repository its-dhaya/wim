-- ============================================================
--  WIM — plugins/lsp.lua
--  Windows-tested LSPs only: pyright + typescript-language-server
-- ============================================================

return {
    {
        "neovim/nvim-lspconfig",
        event        = "BufReadPre",
        dependencies = {
            -- Mason: LSP installer, Windows-aware config
            {
                "williamboman/mason.nvim",
                opts = {
                    -- Windows: install to a path with no spaces
                    install_root_dir = vim.fn.stdpath("data") .. "\\mason",
                    ui = {
                        border = "rounded",
                        icons  = { package_installed = "✓", package_pending = "➜", package_uninstalled = "✗" },
                    },
                    -- Windows: force PATH update after install
                    PATH = "prepend",
                },
            },
            {
                "williamboman/mason-lspconfig.nvim",
                opts = {
                    -- Only Windows-verified LSPs
                    ensure_installed = {
                        "pyright",                  -- Python
                        "ts_ls",                    -- TypeScript / JavaScript
                        "lua_ls",                   -- Lua (for editing WIM config itself)
                        "jsonls",                   -- JSON
                        "html",                     -- HTML
                        "cssls",                    -- CSS
                    },
                    automatic_installation = true,
                },
            },
            "hrsh7th/cmp-nvim-lsp",
        },

        config = function()
            local lspconfig    = require("lspconfig")
            local capabilities = require("cmp_nvim_lsp").default_capabilities()

            -- ---- Shared on_attach (keymaps set per buffer) ----
            local on_attach = function(_, bufnr)
                local map = function(mode, lhs, rhs, desc)
                    vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
                end
                map("n", "gd",         vim.lsp.buf.definition,      "Go to definition")
                map("n", "gD",         vim.lsp.buf.declaration,     "Go to declaration")
                map("n", "gr",         vim.lsp.buf.references,      "References")
                map("n", "gi",         vim.lsp.buf.implementation,  "Implementation")
                map("n", "K",          vim.lsp.buf.hover,           "Hover docs")
                map("n", "<leader>rn", vim.lsp.buf.rename,          "Rename symbol")
                map("n", "<leader>ca", vim.lsp.buf.code_action,     "Code action")
                map("n", "<leader>d",  vim.diagnostic.open_float,   "Show diagnostic")
                map("n", "[d",         vim.diagnostic.goto_prev,    "Prev diagnostic")
                map("n", "]d",         vim.diagnostic.goto_next,    "Next diagnostic")
                map("n", "<leader>f",  function() vim.lsp.buf.format({ async = true }) end, "Format file")
            end

            -- ---- Python (pyright) ----------------------------
            lspconfig.pyright.setup({
                capabilities = capabilities,
                on_attach    = on_attach,
                settings     = {
                    python = {
                        analysis = {
                            typeCheckingMode   = "basic",
                            autoSearchPaths    = true,
                            useLibraryCodeForTypes = true,
                        },
                    },
                },
            })

            -- ---- TypeScript / JavaScript ---------------------
            lspconfig.ts_ls.setup({
                capabilities = capabilities,
                on_attach    = on_attach,
                -- Windows: normalize root detection
                root_dir     = require("lspconfig.util").root_pattern(
                    "tsconfig.json", "jsconfig.json", "package.json", ".git"
                ),
            })

            -- ---- Lua (for editing WIM itself) ----------------
            lspconfig.lua_ls.setup({
                capabilities = capabilities,
                on_attach    = on_attach,
                settings     = {
                    Lua = {
                        diagnostics = { globals = { "vim" } },
                        workspace   = { checkThirdParty = false },
                        telemetry   = { enable = false },
                    },
                },
            })

            -- ---- JSON ----------------------------------------
            lspconfig.jsonls.setup({ capabilities = capabilities, on_attach = on_attach })

            -- ---- HTML / CSS ----------------------------------
            lspconfig.html.setup({ capabilities = capabilities, on_attach = on_attach })
            lspconfig.cssls.setup({ capabilities = capabilities, on_attach = on_attach })

            -- ---- Diagnostics UI ------------------------------
            vim.diagnostic.config({
                virtual_text   = { prefix = "●" },
                severity_sort  = true,
                float          = { border = "rounded", source = "always" },
                signs          = true,
                underline      = true,
                update_in_insert = false,
            })
        end,
    },

    -- ---- Formatter -----------------------------------------
    {
        "stevearc/conform.nvim",
        event = "BufWritePre",
        opts  = {
            formatters_by_ft = {
                python     = { "black" },
                javascript = { "prettier" },
                typescript = { "prettier" },
                json       = { "prettier" },
                html       = { "prettier" },
                css        = { "prettier" },
            },
            format_on_save = {
                timeout_ms = 500,
                lsp_fallback = true,
            },
        },
    },

}
