-- ============================================================
--  WIM — keymaps.lua
-- ============================================================

local map = function(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { silent = true, desc = desc })
end

-- ---- Window navigation (feels natural on Windows) ----------
map("n", "<C-h>", "<C-w>h",    "Move to left window")
map("n", "<C-l>", "<C-w>l",    "Move to right window")
map("n", "<C-j>", "<C-w>j",    "Move to lower window")
map("n", "<C-k>", "<C-w>k",    "Move to upper window")

-- ---- Resize windows ----------------------------------------
map("n", "<C-Up>",    ":resize +2<CR>",          "Increase height")
map("n", "<C-Down>",  ":resize -2<CR>",          "Decrease height")
map("n", "<C-Left>",  ":vertical resize -2<CR>", "Decrease width")
map("n", "<C-Right>", ":vertical resize +2<CR>", "Increase width")

-- ---- Buffers -----------------------------------------------
map("n", "<S-l>", ":bnext<CR>",     "Next buffer")
map("n", "<S-h>", ":bprevious<CR>", "Prev buffer")
map("n", "<leader>bd", ":bdelete<CR>", "Delete buffer")

-- ---- Move lines (Alt+j/k like VSCode) ----------------------
map("n", "<A-j>", ":m .+1<CR>==",        "Move line down")
map("n", "<A-k>", ":m .-2<CR>==",        "Move line up")
map("v", "<A-j>", ":m '>+1<CR>gv=gv",   "Move selection down")
map("v", "<A-k>", ":m '<-2<CR>gv=gv",   "Move selection up")

-- ---- Better indenting (stay in visual mode) ----------------
map("v", "<", "<gv", "Unindent")
map("v", ">", ">gv", "Indent")

-- ---- Save & Quit -------------------------------------------
map("n", "<C-s>", ":w<CR>",  "Save file")       -- Ctrl+S like VSCode
map("n", "<leader>q", ":q<CR>", "Quit")
map("n", "<leader>Q", ":qa!<CR>", "Force quit all")

-- ---- Clear search highlight --------------------------------
map("n", "<Esc>", ":nohl<CR>", "Clear search highlight")

-- ---- Terminal (opens PowerShell) ---------------------------
map("n", "<leader>t", ":ToggleTerm<CR>", "Toggle terminal")
map("t", "<Esc>", "<C-\\><C-n>",         "Exit terminal mode")

-- ---- File explorer -----------------------------------------
map("n", "<leader>e", ":Neotree toggle<CR>", "Toggle file tree")

-- ---- Telescope (fuzzy finder) ------------------------------
map("n", "<leader>ff", ":Telescope find_files<CR>",  "Find files")
map("n", "<leader>fg", ":Telescope live_grep<CR>",   "Live grep")
map("n", "<leader>fb", ":Telescope buffers<CR>",     "Find buffers")
map("n", "<leader>fh", ":Telescope help_tags<CR>",   "Help tags")
map("n", "<leader>fr", ":Telescope oldfiles<CR>",    "Recent files")

-- ---- LSP (set inside lsp.lua on_attach) --------------------
-- Defined per buffer in plugins/lsp.lua

-- ---- WIM commands ------------------------------------------
map("n", "<leader>wu", ":Lazy update<CR>",       "WIM: Update plugins")
map("n", "<leader>wh", ":checkhealth<CR>",       "WIM: Health check")
map("n", "<leader>wl", ":Lazy<CR>",              "WIM: Lazy panel")
