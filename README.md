# WIM — Windows Integrated Modular Neovim

> Neovim for Windows, done right.

LazyVim is incredible. But it assumes you're on Unix.  
**WIM is what LazyVim would be if Windows was a first-class citizen.**

---

## Why WIM?

Every existing Neovim config has the same problem on Windows:

- `mason.nvim` installs LSPs that silently fail
- Telescope needs `ripgrep` and `fd` — good luck figuring that out
- Clipboard (`+y`) randomly doesn't work
- `:term` opens `cmd.exe` instead of PowerShell
- Backslash path hell breaks half your Lua config
- Treesitter needs a C compiler nobody told you to install

WIM fixes all of this. One installer. Zero config. Works on day one.

---

## Installation

Open PowerShell as Administrator and run:

```powershell
git clone https://github.com/yourusername/wim.git
cd wim
powershell -ExecutionPolicy Bypass -File installer\install.ps1
```

The installer will:
- ✅ Install Neovim (if not already installed)
- ✅ Install Git, Node.js, Python, ripgrep, fd, fzf, Zig
- ✅ Install and configure JetBrainsMono Nerd Font
- ✅ Deploy the WIM config to `%LOCALAPPDATA%\nvim`
- ✅ Set PowerShell as the default terminal shell
- ✅ Run a health check and tell you exactly what worked

---

## What's included

| Feature | Tool |
|---|---|
| Plugin manager | lazy.nvim |
| Colorscheme | Catppuccin Mocha |
| File explorer | neo-tree.nvim |
| Fuzzy finder | Telescope + ripgrep |
| Syntax highlighting | nvim-treesitter |
| Autocompletion | nvim-cmp |
| LSP (Python) | pyright |
| LSP (JS/TS) | typescript-language-server |
| LSP (Lua/JSON/HTML/CSS) | included |
| Formatter | conform.nvim + prettier + black |
| Terminal | toggleterm → PowerShell |
| Git | gitsigns + lazygit |
| Statusline | lualine |
| Keybind helper | which-key |

---

## Key bindings

| Key | Action |
|---|---|
| `Space` | Leader key |
| `<leader>ff` | Find files |
| `<leader>fg` | Live grep |
| `<leader>e` | Toggle file tree |
| `<leader>t` | Toggle terminal (PowerShell) |
| `<leader>gg` | Open LazyGit |
| `<leader>wh` | WIM health check |
| `<leader>wu` | Update all plugins |
| `K` | Hover docs (LSP) |
| `gd` | Go to definition |
| `<leader>rn` | Rename symbol |
| `<leader>ca` | Code action |
| `<C-s>` | Save file |

---

## Requirements

- Windows 10 / 11
- Windows Terminal (recommended)
- PowerShell 7+ (pwsh) — installed automatically if missing

---

## Coming from VSCode?

| VSCode | WIM |
|---|---|
| `Ctrl+P` | `<leader>ff` |
| `Ctrl+Shift+F` | `<leader>fg` |
| `Ctrl+\`` | `<leader>t` |
| `F2` | `<leader>rn` |
| `F12` | `gd` |
| `Ctrl+S` | `<C-s>` |
| `Ctrl+/` | `gcc` |

---

## Coming from LazyVim on Linux/Mac?

WIM follows the same conventions as LazyVim so muscle memory transfers.  
The key difference is everything is pre-solved for Windows paths, clipboard, shell, and LSP installs.

---

## Health check

Inside Neovim run:
```
:checkhealth
```
Or press `<leader>wh` at any time.

---

## License

MIT
