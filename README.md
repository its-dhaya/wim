# WIM — Windows Integrated Modular Neovim

> Neovim for Windows, done right.

LazyVim is incredible. But it assumes you're on Unix.  
**WIM is what LazyVim would be if Windows was a first-class citizen.**

---

## Why WIM?

Every existing Neovim config has the same problem on Windows:

- `mason.nvim` installs LSPs that silently fail
- Telescope needs `ripgrep` and `fd` — good luck figuring that out
- Clipboard (`+y`) randomly doesn't work after sleep
- `:term` opens `cmd.exe` instead of PowerShell
- Backslash path hell breaks half your Lua config
- Treesitter needs a C compiler nobody told you to install
- Font setup downloads 200MB when you only need 4 files
- Windows Defender scans every file on startup — editor feels slow
- CRLF vs LF fights between git and formatters on every save
- LSP servers installed by Mason invisible outside Neovim
- WSL paths (`/mnt/c/...`) confuse LSP on dual-boot setups

**WIM fixes all of this. Two commands. Zero config. Works on day one.**

Every bug WIM fixes was found by running it on real Windows hardware — not guessed from documentation.

---

## Installation

Open PowerShell as Administrator and run:

```powershell
git clone https://github.com/its-dhaya/wim.git
cd wim

# Step 1 — install dependencies + fix PATH
powershell -ExecutionPolicy Bypass -File installer\install.ps1
```

**Close the terminal. Open a new one as Administrator. Then:**

```powershell
cd wim

# Step 2 — deploy config, fonts, defender exclusions, git config
powershell -ExecutionPolicy Bypass -File installer\setup.ps1
```

Then just run `nvim` — plugins auto-install on first launch.

> **Why two steps?** Windows PATH changes require a fresh terminal to take effect. Running setup in the same session causes silent tool-not-found failures. WIM is honest about this instead of hoping it works.

---

## What the installer does

**Phase A — install.ps1**

- ✅ Installs Neovim, Git, Node.js, Python, ripgrep, fd, fzf, Zig, win32yank
- ✅ Repairs PATH — adds all known install locations permanently
- ✅ Prompts you to reopen terminal before continuing

**Phase B — setup.ps1**

- ✅ Verifies all dependencies are in PATH before doing anything
- ✅ Detects your terminal (Windows Terminal / Alacritty / ConEmu)
- ✅ Detects WSL and enables path normalization if needed
- ✅ Configures git line endings (autocrlf=input, eol=lf)
- ✅ Deploys global `.editorconfig` for consistent formatting
- ✅ Installs JetBrainsMono Nerd Font (4 files, ~1.2MB — not 200MB)
- ✅ Adds Neovim folders to Windows Defender exclusions
- ✅ Adds Mason bin to system PATH so LSP servers work everywhere
- ✅ Deploys WIM config to `%LOCALAPPDATA%\nvim`
- ✅ Auto-detects and configures PowerShell as default shell
- ✅ Runs full health check with plain English output

---

## Windows bugs WIM solves

| Problem                          | How WIM fixes it                                         |
| -------------------------------- | -------------------------------------------------------- |
| Font install downloads 200MB     | Downloads only 4 required TTF files (~1.2MB)             |
| Windows Defender slows startup   | Auto-adds nvim folders to exclusion list                 |
| CRLF vs LF formatter conflicts   | 3-layer fix: git config + editorconfig + plugin          |
| Mason LSPs invisible in terminal | Mason bin added to system PATH permanently               |
| WSL paths break LSP on dual-boot | Auto-converts `/mnt/c/` to `C:\` at URI level            |
| Clipboard breaks after sleep     | Auto-reconnects win32yank on focus, `:WimClipboardFix`   |
| Terminal colors/features vary    | Auto-detects WT/Alacritty/ConEmu, configures accordingly |
| PATH not updated after install   | Two-phase installer guarantees clean PATH before setup   |
| PS5.1 incompatible scripts       | All scripts tested on PowerShell 5.1 and above           |
| lspconfig v3 API change          | Pinned to stable v2, upgrade handled cleanly             |
| LuaSnip jsregexp submodule fails | Build disabled, snippets work without native module      |
| cmake `&&` fails in PS5.1        | Build commands split for PowerShell compatibility        |

---

## What's included

| Feature                 | Tool                            |
| ----------------------- | ------------------------------- |
| Plugin manager          | lazy.nvim                       |
| Colorscheme             | Catppuccin Mocha                |
| File explorer           | neo-tree.nvim                   |
| Fuzzy finder            | Telescope + ripgrep             |
| Syntax highlighting     | nvim-treesitter                 |
| Autocompletion          | nvim-cmp                        |
| LSP (Python)            | pyright                         |
| LSP (JS/TS)             | typescript-language-server      |
| LSP (Lua/JSON/HTML/CSS) | included                        |
| Formatter               | conform.nvim + prettier + black |
| Terminal                | toggleterm → PowerShell         |
| Git                     | gitsigns + lazygit              |
| Statusline              | lualine                         |
| Keybind helper          | which-key                       |
| Editorconfig            | editorconfig-vim                |

---

## Key bindings

| Key          | Action                       |
| ------------ | ---------------------------- |
| `Space`      | Leader key                   |
| `<leader>ff` | Find files                   |
| `<leader>fg` | Live grep                    |
| `<leader>e`  | Toggle file tree             |
| `<leader>t`  | Toggle terminal (PowerShell) |
| `<leader>gg` | Open LazyGit                 |
| `<leader>wh` | WIM health check             |
| `<leader>wu` | Update all plugins           |
| `K`          | Hover docs (LSP)             |
| `gd`         | Go to definition             |
| `<leader>rn` | Rename symbol                |
| `<leader>ca` | Code action                  |
| `<C-s>`      | Save file                    |

---

## WIM commands

| Command            | Description                              |
| ------------------ | ---------------------------------------- |
| `:WimInfo`         | Show terminal, OS, Neovim version, paths |
| `:WimClipboardFix` | Reconnect clipboard after sleep/wake     |
| `:checkhealth`     | Full Neovim health check                 |
| `:Lazy`            | Plugin manager panel                     |
| `:Mason`           | LSP server manager                       |

---

## Requirements

- Windows 10 / 11
- Windows Terminal (recommended — install from Microsoft Store)
- PowerShell 5.1+ (built into Windows — no install needed)
- Run as Administrator for font + Defender exclusion steps

---

## Coming from VSCode?

| VSCode         | WIM          |
| -------------- | ------------ |
| `Ctrl+P`       | `<leader>ff` |
| `Ctrl+Shift+F` | `<leader>fg` |
| `` Ctrl+` ``   | `<leader>t`  |
| `F2`           | `<leader>rn` |
| `F12`          | `gd`         |
| `Ctrl+S`       | `<C-s>`      |
| `Ctrl+/`       | `gcc`        |

---

## Coming from LazyVim on Linux/Mac?

WIM follows LazyVim conventions so muscle memory transfers directly.  
The difference is everything is pre-solved for Windows — paths, clipboard, shell, LSP installs, and line endings.

---

## License

MIT
