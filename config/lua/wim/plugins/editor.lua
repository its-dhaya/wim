-- ============================================================
--  WIM — plugins/editor.lua
-- ============================================================

return {

    -- ---- Telescope (fuzzy finder) --------------------------
    {
        "nvim-telescope/telescope.nvim",
        cmd          = "Telescope",
        dependencies = {
            "nvim-lua/plenary.nvim",
            -- Windows fix: split cmake commands, no && operator (PS5.1 incompatible)
        { "nvim-telescope/telescope-fzf-native.nvim", build = "cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release & cmake --build build --config Release & cmake --install build --prefix build" },
        },
        opts = {
            defaults = {
                path_display = { "truncate" },
                -- Windows: use ripgrep with forward slashes
                vimgrep_arguments = {
                    "rg", "--color=never", "--no-heading",
                    "--with-filename", "--line-number",
                    "--column", "--smart-case", "--path-separator", "/",
                },
            },
        },
    },

    -- ---- Treesitter (syntax highlighting) ------------------
    {
        "nvim-treesitter/nvim-treesitter",
        build  = ":TSUpdate",
        event  = "BufReadPost",
        opts = {
            ensure_installed = {
                "lua", "python", "javascript",
                "typescript", "tsx", "json",
                "html", "css", "markdown",
            },
            highlight    = { enable = true },
            indent       = { enable = true },
            auto_install = true,
        },
        config = function(_, opts)
            require("nvim-treesitter.configs").setup(opts)
            -- Windows: use zig as compiler for treesitter parsers
            require("nvim-treesitter.install").compilers = { "zig", "cl", "cc", "gcc", "clang" }
        end,
    },

    -- ---- Autocompletion ------------------------------------
    {
        "hrsh7th/nvim-cmp",
        event = "InsertEnter",
        dependencies = {
            "hrsh7th/cmp-nvim-lsp",
            "hrsh7th/cmp-buffer",
            "hrsh7th/cmp-path",
            -- Windows fix: disable jsregexp submodule build (causes git submodule errors)
            { "L3MON4D3/LuaSnip", build = "" },
            "saadparwaiz1/cmp_luasnip",
            "rafamadriz/friendly-snippets",
        },
        config = function()
            local cmp     = require("cmp")
            local luasnip = require("luasnip")
            require("luasnip.loaders.from_vscode").lazy_load()

            cmp.setup({
                snippet = {
                    expand = function(args) luasnip.lsp_expand(args.body) end,
                },
                mapping = cmp.mapping.preset.insert({
                    ["<C-Space>"] = cmp.mapping.complete(),
                    ["<CR>"]      = cmp.mapping.confirm({ select = true }),
                    ["<Tab>"]     = cmp.mapping(function(fallback)
                        if cmp.visible() then cmp.select_next_item()
                        elseif luasnip.expand_or_jumpable() then luasnip.expand_or_jump()
                        else fallback() end
                    end, { "i", "s" }),
                    ["<S-Tab>"]   = cmp.mapping(function(fallback)
                        if cmp.visible() then cmp.select_prev_item()
                        elseif luasnip.jumpable(-1) then luasnip.jump(-1)
                        else fallback() end
                    end, { "i", "s" }),
                }),
                sources = cmp.config.sources({
                    { name = "nvim_lsp" },
                    { name = "luasnip"  },
                    { name = "buffer"   },
                    { name = "path"     },
                }),
                window = {
                    completion    = cmp.config.window.bordered(),
                    documentation = cmp.config.window.bordered(),
                },
            })
        end,
    },

    -- ---- Editorconfig (respects per-project .editorconfig) ------
    {
        "editorconfig/editorconfig-vim",
        event = "BufReadPre",
    },

    -- ---- Autopairs -----------------------------------------
    {
        "windwp/nvim-autopairs",
        event = "InsertEnter",
        opts  = { check_ts = true },
    },

    -- ---- Comment toggle ------------------------------------
    {
        "numToStr/Comment.nvim",
        event = "BufReadPost",
        opts  = {},
    },

    -- ---- Surround ------------------------------------------
    {
        "kylechui/nvim-surround",
        event   = "BufReadPost",
        version = "*",
        opts    = {},
    },

}