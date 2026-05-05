# ============================================================
#  WIM - Windows Integrated Modular Neovim
#  Installer - compatible with PowerShell 5.1 and above
#  Run: powershell -ExecutionPolicy Bypass -File installer\install.ps1
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
Write-Host "  Neovim for Windows, done right." -ForegroundColor DarkGray
Write-Host ""

# ---- Check Windows version ---------------------------------
Write-Header "Checking system..."
$winVer = [System.Environment]::OSVersion.Version
if ($winVer.Major -lt 10) {
    Write-Fail "WIM requires Windows 10 or higher."
    exit 1
}
Write-Ok "Windows $($winVer.Major).$($winVer.Minor) detected"

# ---- Check winget ------------------------------------------
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Fail "winget not found. Install App Installer from the Microsoft Store."
    exit 1
}
Write-Ok "winget found"

# ---- Helper: install or skip via winget --------------------
function Install-IfMissing {
    param(
        [string]$Name,
        [string]$WingetId,
        [string]$Command
    )
    if (Get-Command $Command -ErrorAction SilentlyContinue) {
        Write-Skip "$Name already installed"
    } else {
        Write-Step "Installing $Name..."
        winget install --id $WingetId --silent --accept-source-agreements --accept-package-agreements | Out-Null
        $machinePath = [System.Environment]::GetEnvironmentVariable("PATH", "Machine")
        $userPath    = [System.Environment]::GetEnvironmentVariable("PATH", "User")
        $env:PATH    = "$machinePath;$userPath"
        if (Get-Command $Command -ErrorAction SilentlyContinue) {
            Write-Ok "$Name installed"
        } else {
            Write-Warn "$Name installed but needs terminal restart to appear in PATH"
        }
    }
}

# ---- Install dependencies ----------------------------------
Write-Header "Installing dependencies..."

Install-IfMissing -Name "Neovim"  -WingetId "Neovim.Neovim"           -Command "nvim"
Install-IfMissing -Name "Git"     -WingetId "Git.Git"                  -Command "git"
Install-IfMissing -Name "Node.js" -WingetId "OpenJS.NodeJS.LTS"        -Command "node"
Install-IfMissing -Name "Python"  -WingetId "Python.Python.3.12"       -Command "python"
Install-IfMissing -Name "ripgrep" -WingetId "BurntSushi.ripgrep.MSVC"  -Command "rg"
Install-IfMissing -Name "fd"      -WingetId "sharkdp.fd"               -Command "fd"
Install-IfMissing -Name "fzf"     -WingetId "junegunn.fzf"             -Command "fzf"
Install-IfMissing -Name "Zig"      -WingetId "zig.zig"                  -Command "zig"
Install-IfMissing -Name "win32yank" -WingetId "win32yank.win32yank"      -Command "win32yank"     -WingetId "zig.zig"                  -Command "zig"

# ---- Nerd Font (targeted download - 4 files only ~1.2MB) -----------------
Write-Header "Installing Nerd Font (JetBrainsMono)..."

$fontBase  = "https://github.com/ryanoasis/nerd-fonts/raw/HEAD/patched-fonts/JetBrainsMono/Ligatures"
$fontFiles = @(
    @{ Url = "$fontBase/Regular/JetBrainsMonoNerdFont-Regular.ttf";       Name = "JetBrainsMonoNerdFont-Regular.ttf"       },
    @{ Url = "$fontBase/Bold/JetBrainsMonoNerdFont-Bold.ttf";             Name = "JetBrainsMonoNerdFont-Bold.ttf"           },
    @{ Url = "$fontBase/Italic/JetBrainsMonoNerdFont-Italic.ttf";         Name = "JetBrainsMonoNerdFont-Italic.ttf"         },
    @{ Url = "$fontBase/BoldItalic/JetBrainsMonoNerdFont-BoldItalic.ttf"; Name = "JetBrainsMonoNerdFont-BoldItalic.ttf"    }
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

# ---- Deploy global editorconfig ----------------------------
Write-Header "Deploying global editorconfig..."

$editorconfig = "$env:USERPROFILE\.editorconfig"
$wimEditorconfig = "$PSScriptRoot\wim.editorconfig"

if (Test-Path $editorconfig) {
    Write-Skip "Global .editorconfig already exists at $editorconfig"
} else {
    if (Test-Path $wimEditorconfig) {
        Copy-Item $wimEditorconfig $editorconfig -Force
        Write-Ok "Global .editorconfig deployed to $editorconfig"
    } else {
        Write-Warn "wim.editorconfig not found in installer folder"
    }
}

# ---- Deploy WIM config -------------------------------------
Write-Header "Deploying WIM config..."

$nvimConfig = "$env:LOCALAPPDATA\nvim"
$wimSource  = Split-Path -Parent $PSScriptRoot

if (Test-Path $nvimConfig) {
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backup = "$env:LOCALAPPDATA\nvim-backup-$timestamp"
    Write-Warn "Existing config found - backing up to $backup"
    Move-Item $nvimConfig $backup
}

Write-Step "Copying WIM config to $nvimConfig..."
Copy-Item -Path "$wimSource\config" -Destination $nvimConfig -Recurse -Force
Write-Ok "WIM config deployed to $nvimConfig"

# ---- Detect PowerShell -------------------------------------
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

# ---- Terminal detection -------------------------------------------
Write-Header "Detecting terminal..."

$terminal = "unknown"
if ($env:WT_SESSION) {
    $terminal = "Windows Terminal"
    Write-Ok "Windows Terminal detected - full truecolor + transparency enabled"
} elseif ($env:ALACRITTY_LOG) {
    $terminal = "Alacritty"
    Write-Ok "Alacritty detected - truecolor enabled"
} elseif ($env:ConEmuPID) {
    $terminal = "ConEmu"
    Write-Warn "ConEmu detected - limited color support, undercurl disabled"
} else {
    Write-Warn "Terminal not recognized - using safe defaults"
    Write-Host "  Recommended: install Windows Terminal from the Microsoft Store" -ForegroundColor DarkGray
}

# ---- WSL detection ------------------------------------------------
Write-Header "Checking WSL status..."

$wslInstalled = $false
try {
    $wslOutput = wsl --status 2>$null
    if ($LASTEXITCODE -eq 0) {
        $wslInstalled = $true
    }
} catch {}

if ($wslInstalled) {
    Write-Warn "WSL detected - WIM will auto-normalize WSL paths in LSP"
    Write-Ok "WSL path conflict protection enabled"
} else {
    Write-Skip "WSL not detected - path normalization not needed"
}

# ---- Mason PATH fix ------------------------------------------------
Write-Header "Configuring Mason PATH..."

$masonBin = "$env:LOCALAPPDATA\nvim-data\mason\bin"

# Create mason bin dir if it doesn't exist yet (first install)
if (-not (Test-Path $masonBin)) {
    New-Item -ItemType Directory -Force -Path $masonBin | Out-Null
    Write-Step "Created Mason bin directory"
}

# Check if already in user PATH
$userPath = [System.Environment]::GetEnvironmentVariable("PATH", "User")
if ($userPath -split ";" -contains $masonBin) {
    Write-Skip "Mason bin already in PATH"
} else {
    # Add to user PATH permanently
    $newPath = $userPath.TrimEnd(";") + ";" + $masonBin
    [System.Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
    # Also update current session
    $env:PATH = $env:PATH.TrimEnd(";") + ";" + $masonBin
    Write-Ok "Mason bin added to PATH: $masonBin"
    Write-Warn "LSP servers installed by Mason will now be accessible system-wide"
}

# ---- Git CRLF configuration ----------------------------------------
Write-Header "Configuring Git line endings..."

try {
    # input = commit as LF, checkout as-is (no auto CRLF conversion)
    # This stops git from fighting with prettier/black over line endings
    git config --global core.autocrlf input
    git config --global core.eol lf
    Write-Ok "Git configured: core.autocrlf=input, core.eol=lf"
} catch {
    Write-Warn "Could not configure git line endings"
}

# ---- Windows Defender exclusions ----------------------------------
Write-Header "Configuring Windows Defender exclusions..."

$exclusions = @(
    "$env:LOCALAPPDATA\nvim",
    "$env:LOCALAPPDATA\nvim-data",
    $(if (Get-Command nvim -ErrorAction SilentlyContinue) { (Get-Command nvim).Source } else { $null })
)

$addedAny = $false
foreach ($path in $exclusions) {
    if ($path -and (Test-Path $path -ErrorAction SilentlyContinue)) {
        try {
            $existing = (Get-MpPreference).ExclusionPath
            if ($existing -notcontains $path) {
                Add-MpPreference -ExclusionPath $path -ErrorAction Stop
                Write-Ok "Excluded: $path"
                $addedAny = $true
            } else {
                Write-Skip "Already excluded: $path"
            }
        } catch {
            Write-Warn "Could not add exclusion for $path (run as Administrator for this)"
        }
    }
}

# Also exclude neovim process itself
try {
    $existing = (Get-MpPreference).ExclusionProcess
    if ($existing -notcontains "nvim.exe") {
        Add-MpPreference -ExclusionProcess "nvim.exe" -ErrorAction Stop
        Write-Ok "Excluded process: nvim.exe"
    } else {
        Write-Skip "nvim.exe process already excluded"
    }
} catch {
    Write-Warn "Could not exclude nvim.exe process (run as Administrator for this)"
}

if ($addedAny) {
    Write-Ok "Defender exclusions configured - startup will be significantly faster"
} 

# ---- Health check ------------------------------------------
Write-Header "Running health check..."

$checks = @(
    @{ Name = "nvim";   Label = "Neovim"  },
    @{ Name = "git";    Label = "Git"     },
    @{ Name = "node";   Label = "Node.js" },
    @{ Name = "python"; Label = "Python"  },
    @{ Name = "rg";     Label = "ripgrep" },
    @{ Name = "fd";     Label = "fd"      },
    @{ Name = "zig";       Label = "Zig"       },
    @{ Name = "win32yank"; Label = "win32yank" }
)

$allGood = $true
foreach ($check in $checks) {
    if (Get-Command $check.Name -ErrorAction SilentlyContinue) {
        if ($check.Name -eq "zig") { $ver = "installed" } else { $ver = & $check.Name --version 2>&1 | Select-Object -First 1 }
        Write-Ok "$($check.Label) - $ver"
    } else {
        Write-Fail "$($check.Label) not found in PATH"
        $allGood = $false
    }
}

Write-Host ""
if ($allGood) {
    Write-Host "  WIM installed successfully!" -ForegroundColor Green
} else {
    Write-Host "  WIM installed with warnings." -ForegroundColor Yellow
    Write-Host "  Restart terminal then run: nvim" -ForegroundColor DarkGray
}
Write-Host ""
Write-Host "  Run 'nvim' to launch WIM." -ForegroundColor Cyan
Write-Host ""