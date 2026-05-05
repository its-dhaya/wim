-- ============================================================
--  WIM — plugins/init.lua
--  All plugins loaded from here
-- ============================================================

return {
  { import = "wim.plugins.ui"       },
  { import = "wim.plugins.editor"   },
  { import = "wim.plugins.lsp"      },
  { import = "wim.plugins.terminal" },
  { import = "wim.plugins.git"      },
}