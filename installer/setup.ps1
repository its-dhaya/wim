# ============================================================
#  WIM - Windows Integrated Modular Neovim
#  PHASE B — setup.ps1
#  Deploys config, fonts, Defender exclusions, git config
#  Run AFTER install.ps1 in a NEW terminal:
#  powershell -ExecutionPolicy Bypass -File installer\setup.ps1
# ============================================================

$ErrorActionPreference = "Stop"

function Write-Header { Write-Host "`n  $args" -ForegroundColor Cyan }
function Write-Ok     { Write-Host "  [OK]  $args" -ForegroundColor Green }
function Write-Skip   { Write-Host "  [--]  $args" -ForegroundColor DarkGray }
function Write-Warn   { Write-Host "  [!!]  $args" -ForegroundColor Yellow }
function Write-Fail   { Write-Host "  [XX]  $args" -ForegroundColor Red }
function Write-Step   { Write-Host "  -->   $args" -ForegroundColor White }

Clear-Host
Write-Host ""
Write-Host "  WIM - Windows Integrated Modular Neovim" -ForegroundColor Cyan
Write-Host "  Phase B: Setup & Configuration" -ForegroundColor DarkGray
Write-Host ""

# ---- Verify Phase A was completed --------------------------
Write-Header "Verifying dependencies..."

$required = @(
    @{ Name = "nvim";   Label = "Neovim"   },
    @{ Name = "git";    Label = "Git"      },
    @{ Name = "node";   Label = "Node.js"  },
    @{ Name = "python"; Label = "Python"   },
    @{ Name = "rg";     Label = "ripgrep"  },
    @{ Name = "fd";     Label = "fd"       }
)

$missing = @()
foreach ($r in $required) {
    if (Get-Command $r.Name -ErrorAction SilentlyContinue) {
        $ver = & $r.Name --version 2>&1 | Select-Object -First 1
        Write-Ok "$($r.Label) - $ver"
    } else {
        Write-Fail "$($r.Label) not found in PATH"
        $missing += $r.Label
    }
}

if ($missing.Count -gt 0) {
    Write-Host ""
    Write-Fail "Missing dependencies: $($missing -join ', ')"
    Write-Warn "Did you run install.ps1 first and open a NEW terminal?"
    Write-Host "  Run: powershell -ExecutionPolicy Bypass -File installer\install.ps1" -ForegroundColor Yellow
    exit 1
}

# ---- Terminal detection ------------------------------------
Write-Header "Detecting terminal..."
if ($env:WT_SESSION) {
    Write-Ok "Windows Terminal detected - full truecolor enabled"
} elseif ($env:ALACRITTY_LOG) {
    Write-Ok "Alacritty detected"
} elseif ($env:ConEmuPID) {
    Write-Warn "ConEmu detected - limited color support"
} else {
    Write-Warn "Terminal not recognized - using safe defaults"
    Write-Host "  Recommended: install Windows Terminal from the Microsoft Store" -ForegroundColor DarkGray
}

# ---- WSL detection -----------------------------------------
Write-Header "Checking WSL..."
try {
    wsl --status 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Warn "WSL detected - WIM will auto-normalize WSL paths in LSP"
    } else {
        Write-Skip "WSL not detected"
    }
} catch {
    Write-Skip "WSL not detected"
}

# ---- Git CRLF config ---------------------------------------
Write-Header "Configuring Git line endings..."
try {
    git config --global core.autocrlf input
    git config --global core.eol lf
    Write-Ok "Git: core.autocrlf=input, core.eol=lf"
} catch {
    Write-Warn "Could not configure git line endings"
}

# ---- Deploy global editorconfig ----------------------------
Write-Header "Deploying global editorconfig..."
$editorconfig    = "$env:USERPROFILE\.editorconfig"
$wimEditorconfig = "$PSScriptRoot\wim.editorconfig"

if (Test-Path $editorconfig) {
    Write-Skip "Global .editorconfig already exists"
} elseif (Test-Path $wimEditorconfig) {
    Copy-Item $wimEditorconfig $editorconfig -Force
    Write-Ok "Global .editorconfig deployed to $editorconfig"
} else {
    Write-Warn "wim.editorconfig not found in installer folder"
}

# ---- Nerd Font ---------------------------------------------
Write-Header "Installing Nerd Font (JetBrainsMono)..."

$fontBase  = "https://github.com/ryanoasis/nerd-fonts/raw/HEAD/patched-fonts/JetBrainsMono/Ligatures"
$fontFiles = @(
    @{ Url = "$fontBase/Regular/JetBrainsMonoNerdFont-Regular.ttf";          Name = "JetBrainsMonoNerdFont-Regular.ttf"       },
    @{ Url = "$fontBase/Bold/JetBrainsMonoNerdFont-Bold.ttf";                Name = "JetBrainsMonoNerdFont-Bold.ttf"          },
    @{ Url = "$fontBase/Italic/JetBrainsMonoNerdFont-Italic.ttf";            Name = "JetBrainsMonoNerdFont-Italic.ttf"        },
    @{ Url = "$fontBase/BoldItalic/JetBrainsMonoNerdFont-BoldItalic.ttf";    Name = "JetBrainsMonoNerdFont-BoldItalic.ttf"   }
)
$fontTempDir = "$env:TEMP\WimFonts"
$fontShell   = (New-Object -ComObject Shell.Application).Namespace(0x14)

$regPath = "HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"
$alreadyInstalled = $false
if (Test-Path $regPath) {
    $installedFonts = Get-ItemProperty $regPath -ErrorAction SilentlyContinue
    if ($installedFonts -and ($installedFonts.PSObject.Properties.Name -like "*JetBrainsMono*")) {
        $alreadyInstalled = $true
    }
}

if ($alreadyInstalled) {
    Write-Skip "JetBrainsMono Nerd Font already installed"
} else {
    New-Item -ItemType Directory -Force -Path $fontTempDir | Out-Null
    $allOk = $true
    foreach ($font in $fontFiles) {
        try {
            Write-Step "Downloading $($font.Name)..."
            $dest = "$fontTempDir\$($font.Name)"
            Invoke-WebRequest -Uri $font.Url -OutFile $dest -UseBasicParsing -TimeoutSec 30
            $fontShell.CopyHere($dest, 0x10)
        } catch {
            Write-Warn "Failed: $($font.Name)"
            $allOk = $false
        }
    }
    if ($allOk) {
        Write-Ok "JetBrainsMono Nerd Font installed (4 files ~1.2MB)"
        Write-Warn "ACTION: Windows Terminal -> Settings -> Profile -> Font -> JetBrainsMono Nerd Font"
    } else {
        Write-Warn "Some fonts failed - install manually from nerdfonts.com/font-downloads"
    }
    Remove-Item -Recurse -Force $fontTempDir -ErrorAction SilentlyContinue
}

# ---- Windows Defender exclusions ---------------------------
Write-Header "Configuring Windows Defender exclusions..."

$exclusionPaths = @(
    "$env:LOCALAPPDATA\nvim",
    "$env:LOCALAPPDATA\nvim-data"
)

# Add nvim.exe if found
if (Get-Command nvim -ErrorAction SilentlyContinue) {
    $exclusionPaths += (Get-Command nvim).Source
}

foreach ($path in $exclusionPaths) {
    if (Test-Path $path -ErrorAction SilentlyContinue) {
        try {
            $existing = (Get-MpPreference).ExclusionPath
            if ($existing -notcontains $path) {
                Add-MpPreference -ExclusionPath $path -ErrorAction Stop
                Write-Ok "Excluded: $path"
            } else {
                Write-Skip "Already excluded: $path"
            }
        } catch {
            Write-Warn "Could not add exclusion (run as Administrator for this)"
        }
    }
}

try {
    $existingProc = (Get-MpPreference).ExclusionProcess
    if ($existingProc -notcontains "nvim.exe") {
        Add-MpPreference -ExclusionProcess "nvim.exe" -ErrorAction Stop
        Write-Ok "Excluded process: nvim.exe"
    } else {
        Write-Skip "nvim.exe already excluded"
    }
} catch {
    Write-Warn "Could not exclude nvim.exe process"
}

# ---- Deploy WIM config -------------------------------------
Write-Header "Deploying WIM config..."

$nvimConfig = "$env:LOCALAPPDATA\nvim"
$wimSource  = Split-Path -Parent $PSScriptRoot

if (Test-Path $nvimConfig) {
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backup    = "$env:LOCALAPPDATA\nvim-backup-$timestamp"
    Write-Warn "Existing config found - backing up to $backup"
    Move-Item $nvimConfig $backup
}

Write-Step "Copying WIM config to $nvimConfig..."
Copy-Item -Path "$wimSource\config" -Destination $nvimConfig -Recurse -Force
Write-Ok "WIM config deployed"

# ---- Detect PowerShell and write shell config --------------
$psExe = $null
if (Get-Command pwsh -ErrorAction SilentlyContinue) {
    $psExe = (Get-Command pwsh).Source
} elseif (Get-Command powershell -ErrorAction SilentlyContinue) {
    $psExe = (Get-Command powershell).Source
}

if ($psExe -ne $null) {
    $psExeEscaped = $psExe -replace "\\", "\\\\"
    $shellConfig  = "$nvimConfig\lua\wim\shell.lua"
    $shellContent = "-- Auto-generated by WIM installer`nvim.opt.shell = '$psExeEscaped'"
    Set-Content -Path $shellConfig -Value $shellContent -Encoding UTF8
    Write-Ok "Shell configured: $psExe"
}

# ---- Final health check ------------------------------------
Write-Header "Final health check..."

$checks = @(
    @{ Name = "nvim";       Label = "Neovim"    },
    @{ Name = "git";        Label = "Git"       },
    @{ Name = "node";       Label = "Node.js"   },
    @{ Name = "python";     Label = "Python"    },
    @{ Name = "rg";         Label = "ripgrep"   },
    @{ Name = "fd";         Label = "fd"        },
    @{ Name = "fzf";        Label = "fzf"       },
    @{ Name = "win32yank";  Label = "win32yank" }
)

$allGood = $true
foreach ($check in $checks) {
    if (Get-Command $check.Name -ErrorAction SilentlyContinue) {
        if ($check.Name -eq "zig" -or $check.Name -eq "win32yank") {
            Write-Ok "$($check.Label) - installed"
        } else {
            $ver = & $check.Name --version 2>&1 | Select-Object -First 1
            Write-Ok "$($check.Label) - $ver"
        }
    } else {
        Write-Fail "$($check.Label) not found"
        $allGood = $false
    }
}

# ---- Done --------------------------------------------------
Write-Host ""
Write-Host "  ============================================" -ForegroundColor Cyan
if ($allGood) {
    Write-Host "  WIM installed successfully!" -ForegroundColor Green
} else {
    Write-Host "  WIM installed with warnings." -ForegroundColor Yellow
}
Write-Host "  ============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Run 'nvim' to launch WIM." -ForegroundColor White
Write-Host "  Plugins auto-install on first launch." -ForegroundColor DarkGray
Write-Host "  Run ':WimInfo' inside Neovim to check status." -ForegroundColor DarkGray
Write-Host ""