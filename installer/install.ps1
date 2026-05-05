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
Install-IfMissing -Name "Zig"     -WingetId "zig.zig"                  -Command "zig"

# ---- Install Nerd Font -------------------------------------
Write-Header "Installing Nerd Font (JetBrainsMono)..."

$fontUrl  = "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
$fontDest = "$env:TEMP\JetBrainsMono.zip"
$fontDir  = "$env:TEMP\JetBrainsMonoFont"

try {
    Write-Step "Downloading JetBrainsMono Nerd Font..."
    Invoke-WebRequest -Uri $fontUrl -OutFile $fontDest -UseBasicParsing
    Expand-Archive -Path $fontDest -DestinationPath $fontDir -Force
    $fonts = Get-ChildItem $fontDir -Filter "*.ttf" | Where-Object { $_.Name -notlike "*Windows*" }
    $fontFolder = (New-Object -ComObject Shell.Application).Namespace(0x14)
    foreach ($font in $fonts) {
        $fontFolder.CopyHere($font.FullName, 0x10)
    }
    Write-Ok "JetBrainsMono Nerd Font installed"
    Write-Warn "Set font to JetBrainsMono Nerd Font in Windows Terminal settings"
} catch {
    Write-Warn "Font download failed - install manually from nerdfonts.com"
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
Write-Ok "WIM config deployed"

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

# ---- Health check ------------------------------------------
Write-Header "Running health check..."

$checks = @(
    @{ Name = "nvim";   Label = "Neovim"  },
    @{ Name = "git";    Label = "Git"     },
    @{ Name = "node";   Label = "Node.js" },
    @{ Name = "python"; Label = "Python"  },
    @{ Name = "rg";     Label = "ripgrep" },
    @{ Name = "fd";     Label = "fd"      },
    @{ Name = "zig";    Label = "Zig"     }
)

$allGood = $true
foreach ($check in $checks) {
    if (Get-Command $check.Name -ErrorAction SilentlyContinue) {
        $ver = & $check.Name --version 2>&1 | Select-Object -First 1
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