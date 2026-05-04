# ============================================================
#  WIM - Windows Integrated Modular Neovim
#  Installer Script for Windows 11
#  Run with: powershell -ExecutionPolicy Bypass -File install.ps1
# ============================================================

$ErrorActionPreference = "Stop"

# ---- Colors ------------------------------------------------
function Write-Header  { Write-Host "`n  $args" -ForegroundColor Cyan }
function Write-Ok      { Write-Host "  [OK]  $args" -ForegroundColor Green }
function Write-Skip    { Write-Host "  [--]  $args" -ForegroundColor DarkGray }
function Write-Warn    { Write-Host "  [!!]  $args" -ForegroundColor Yellow }
function Write-Fail    { Write-Host "  [XX]  $args" -ForegroundColor Red }
function Write-Step    { Write-Host "  -->   $args" -ForegroundColor White }

# ---- Banner ------------------------------------------------
Clear-Host
Write-Host ""
Write-Host "  ██╗    ██╗██╗███╗   ███╗" -ForegroundColor Cyan
Write-Host "  ██║    ██║██║████╗ ████║" -ForegroundColor Cyan
Write-Host "  ██║ █╗ ██║██║██╔████╔██║" -ForegroundColor Cyan
Write-Host "  ██║███╗██║██║██║╚██╔╝██║" -ForegroundColor Cyan
Write-Host "  ╚███╔███╔╝██║██║ ╚═╝ ██║" -ForegroundColor Cyan
Write-Host "   ╚══╝╚══╝ ╚═╝╚═╝     ╚═╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Windows Integrated Modular Neovim" -ForegroundColor White
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
    Write-Fail "winget not found. Please install App Installer from the Microsoft Store."
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
        # Refresh PATH for this session
        $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH","Machine") + ";" +
                    [System.Environment]::GetEnvironmentVariable("PATH","User")
        if (Get-Command $Command -ErrorAction SilentlyContinue) {
            Write-Ok "$Name installed"
        } else {
            Write-Warn "$Name installed but not yet in PATH — restart terminal after setup"
        }
    }
}

# ---- Install dependencies ----------------------------------
Write-Header "Installing dependencies..."

Install-IfMissing -Name "Neovim"     -WingetId "Neovim.Neovim"              -Command "nvim"
Install-IfMissing -Name "Git"        -WingetId "Git.Git"                    -Command "git"
Install-IfMissing -Name "Node.js"    -WingetId "OpenJS.NodeJS.LTS"          -Command "node"
Install-IfMissing -Name "Python"     -WingetId "Python.Python.3.12"         -Command "python"
Install-IfMissing -Name "ripgrep"    -WingetId "BurntSushi.ripgrep.MSVC"    -Command "rg"
Install-IfMissing -Name "fd"         -WingetId "sharkdp.fd"                 -Command "fd"
Install-IfMissing -Name "fzf"        -WingetId "junegunn.fzf"               -Command "fzf"
Install-IfMissing -Name "Zig"        -WingetId "zig.zig"                    -Command "zig"

# ---- Install Nerd Font -------------------------------------
Write-Header "Installing Nerd Font (JetBrainsMono)..."
$fontName = "JetBrainsMonoNerdFont-Regular.ttf"
$fontUrl  = "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
$fontDest = "$env:TEMP\JetBrainsMono.zip"
$fontDir  = "$env:TEMP\JetBrainsMonoFont"

$fontsInstalled = (Get-ItemProperty 'HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts' -ErrorAction SilentlyContinue)
if ($fontsInstalled -and ($fontsInstalled.PSObject.Properties.Name -like "*JetBrainsMono*")) {
    Write-Skip "JetBrainsMono Nerd Font already installed"
} else {
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
        Write-Warn "Set JetBrainsMonoNF as your font in Windows Terminal settings"
    } catch {
        Write-Warn "Font download failed — install manually from nerdfonts.com"
    }
}

# ---- Deploy WIM config -------------------------------------
Write-Header "Deploying WIM config..."

$nvimConfig = "$env:LOCALAPPDATA\nvim"
$wimSource  = Split-Path -Parent $PSScriptRoot

# Backup existing config if present
if (Test-Path $nvimConfig) {
    $backup = "$env:LOCALAPPDATA\nvim-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Write-Warn "Existing Neovim config found — backing up to $backup"
    Move-Item $nvimConfig $backup
}

# Copy WIM config
Write-Step "Copying WIM config to $nvimConfig..."
Copy-Item -Path "$wimSource\config" -Destination $nvimConfig -Recurse -Force
Write-Ok "WIM config deployed"

# ---- Configure PowerShell as default shell in config -------
$psPath = (Get-Command pwsh -ErrorAction SilentlyContinue)?.Source
if (-not $psPath) {
    $psPath = (Get-Command powershell -ErrorAction SilentlyContinue)?.Source
}
if ($psPath) {
    $shellConfig = "$nvimConfig\lua\wim\shell.lua"
    $shellContent = "-- Auto-generated by WIM installer`nvim.opt.shell = '$($psPath -replace '\\', '\\\\')'"
    Set-Content -Path $shellConfig -Value $shellContent
    Write-Ok "PowerShell configured as default shell ($psPath)"
}

# ---- Run health check --------------------------------------
Write-Header "Running health check..."

$checks = @(
    @{ Name = "nvim";   Label = "Neovim"   },
    @{ Name = "git";    Label = "Git"      },
    @{ Name = "node";   Label = "Node.js"  },
    @{ Name = "python"; Label = "Python"   },
    @{ Name = "rg";     Label = "ripgrep"  },
    @{ Name = "fd";     Label = "fd"       },
    @{ Name = "zig";    Label = "Zig"      }
)

$allGood = $true
foreach ($check in $checks) {
    if (Get-Command $check.Name -ErrorAction SilentlyContinue) {
        $ver = & $check.Name --version 2>&1 | Select-Object -First 1
        Write-Ok "$($check.Label) — $ver"
    } else {
        Write-Fail "$($check.Label) not found in PATH"
        $allGood = $false
    }
}

# ---- Done --------------------------------------------------
Write-Host ""
if ($allGood) {
    Write-Host "  WIM installed successfully!" -ForegroundColor Green
} else {
    Write-Host "  WIM installed with warnings." -ForegroundColor Yellow
    Write-Host "  Restart your terminal and run: nvim +'checkhealth'" -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "  Run 'nvim' to launch. Plugins will auto-install on first launch." -ForegroundColor Cyan
Write-Host "  Run ':WimHealth' inside Neovim anytime to check status." -ForegroundColor DarkGray
Write-Host ""
