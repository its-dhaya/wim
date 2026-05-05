-- ============================================================
--  WIM — plugins/ui.lua
-- ============================================================

return {

  -- ---- Colorscheme ---------------------------------------
  {
      "catppuccin/nvim",
      name    = "catppuccin",
      lazy    = false,
      priority = 1000,
      opts = {
          flavour           = "mocha",
          transparent_background = false,
          integrations = {
              cmp        = true,
              gitsigns   = true,
              neo_tree   = true,
              telescope  = true,
              treesitter = true,
              which_key  = true,
          },
      },
      config = function(_, opts)
          require("catppuccin").setup(opts)
          vim.cmd("colorscheme catppuccin")
      end,
  },

  -- ---- Statusline ----------------------------------------
  {
      "nvim-lualine/lualine.nvim",
      event = "VeryLazy",
      dependencies = { "nvim-tree/nvim-web-devicons" },
      opts = {
          options = {
              theme            = "catppuccin",
              globalstatus     = true,
              component_separators = { left = "", right = "" },
              section_separators  = { left = "", right = "" },
          },
          sections = {
              lualine_a = { "mode" },
              lualine_b = { "branch", "diff", "diagnostics" },
              lualine_c = { { "filename", path = 1 } },  -- relative path
              lualine_x = { "filetype" },
              lualine_y = { "progress" },
              lualine_z = { "location" },
          },
      },
  },

  -- ---- File tree -----------------------------------------
  {
      "nvim-neo-tree/neo-tree.nvim",
      branch       = "v3.x",
      cmd          = "Neotree",
      dependencies = {
          "nvim-lua/plenary.nvim",
          "nvim-tree/nvim-web-devicons",
          "MunifTanjim/nui.nvim",
      },
      opts = {
          filesystem = {
              filtered_items = {
                  visible      = true,
                  hide_dotfiles = false,
              },
              -- Windows: follow symlinks properly
              follow_current_file = { enabled = true },
          },
          window = { width = 30 },
      },
  },

  -- ---- Which-key (keybind popup) -------------------------
  {
      "folke/which-key.nvim",
      event = "VeryLazy",
      opts  = {
          win = { border = "rounded" },
      },
  },

  -- ---- Bufferline (tabs) ---------------------------------
  {
      "akinsho/bufferline.nvim",
      event        = "VeryLazy",
      dependencies = "nvim-tree/nvim-web-devicons",
      opts = {
          options = {
              diagnostics            = "nvim_lsp",
              always_show_bufferline = false,
              offsets = {
                  { filetype = "neo-tree", text = "Files", padding = 1 },
              },
          },
      },
  },

  -- ---- Indent guides -------------------------------------
  {
      "lukas-reineke/indent-blankline.nvim",
      event = "BufReadPost",
      main  = "ibl",
      opts  = {
          indent = { char = "│" },
          scope  = { enabled = false },
      },
  },

  -- ---- Noice (better cmdline / notifications) ------------
  {
      "folke/noice.nvim",
      event        = "VeryLazy",
      dependencies = { "MunifTanjim/nui.nvim", "rcarriga/nvim-notify" },
      opts = {
          lsp = {
              override = {
                  ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
                  ["vim.lsp.util.stylize_markdown"]                = true,
                  ["cmp.entry.get_documentation"]                  = true,
              },
          },
          presets = {
              bottom_search   = true,
              command_palette = true,
          },
      },
  },

}