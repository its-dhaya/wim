# ============================================================
#  WIM - Windows Integrated Modular Neovim
#  PHASE A — install.ps1
#  Installs all dependencies via winget + fixes PATH
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
Write-Host "  Phase A: Dependency Installer" -ForegroundColor DarkGray
Write-Host ""

# ---- Check Windows version ---------------------------------
Write-Header "Checking system..."
$winVer = [System.Environment]::OSVersion.Version
if ($winVer.Major -lt 10) {
    Write-Fail "WIM requires Windows 10 or higher."
    exit 1
}
Write-Ok "Windows $($winVer.Major).$($winVer.Minor) detected"

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Fail "winget not found. Install App Installer from the Microsoft Store."
    exit 1
}
Write-Ok "winget found"

# ---- Install via winget ------------------------------------
function Install-IfMissing {
    param([string]$Name, [string]$WingetId, [string]$Command)
    if (Get-Command $Command -ErrorAction SilentlyContinue) {
        Write-Skip "$Name already installed"
    } else {
        Write-Step "Installing $Name..."
        winget install --id $WingetId --silent --accept-source-agreements --accept-package-agreements | Out-Null
        Write-Ok "$Name installed"
    }
}

Write-Header "Installing dependencies..."
Install-IfMissing -Name "Neovim"     -WingetId "Neovim.Neovim"              -Command "nvim"
Install-IfMissing -Name "Git"        -WingetId "Git.Git"                    -Command "git"
Install-IfMissing -Name "Node.js"    -WingetId "OpenJS.NodeJS.LTS"          -Command "node"
Install-IfMissing -Name "Python"     -WingetId "Python.Python.3.12"         -Command "python"
Install-IfMissing -Name "ripgrep"    -WingetId "BurntSushi.ripgrep.MSVC"    -Command "rg"
Install-IfMissing -Name "fd"         -WingetId "sharkdp.fd"                 -Command "fd"
Install-IfMissing -Name "fzf"        -WingetId "junegunn.fzf"               -Command "fzf"
Install-IfMissing -Name "Zig"        -WingetId "zig.zig"                    -Command "zig"
Install-IfMissing -Name "win32yank"  -WingetId "win32yank.win32yank"        -Command "win32yank"

# ---- Repair PATH -------------------------------------------
Write-Header "Repairing PATH..."

function Repair-Paths {
    # All known install locations winget and manual installs use
    $knownPaths = @(
        # Neovim
        "C:\Program Files\Neovim\bin",
        # Git
        "C:\Program Files\Git\cmd",
        "C:\Program Files\Git\usr\bin",
        # Node.js
        "C:\Program Files\nodejs",
        # Python
        "$env:LOCALAPPDATA\Programs\Python\Python312",
        "$env:LOCALAPPDATA\Programs\Python\Python312\Scripts",
        "$env:APPDATA\Python\Python312\Scripts",
        # ripgrep (winget installs to different places depending on version)
        "$env:LOCALAPPDATA\Microsoft\WinGet\Links",
        "$env:LOCALAPPDATA\Microsoft\WinGet\Packages",
        # Zig
        "$env:LOCALAPPDATA\Programs\zig",
        # win32yank
        "$env:LOCALAPPDATA\Microsoft\WinGet\Links",
        # Mason LSP servers (for setup.ps1 phase)
        "$env:LOCALAPPDATA\nvim-data\mason\bin"
    )

    $userPath = [System.Environment]::GetEnvironmentVariable("PATH", "User")
    $pathList = $userPath -split ";" | Where-Object { $_ -ne "" }
    $added    = @()

    foreach ($p in $knownPaths) {
        # Expand any env vars in path
        $expanded = [System.Environment]::ExpandEnvironmentVariables($p)
        if ((Test-Path $expanded -ErrorAction SilentlyContinue) -and ($pathList -notcontains $expanded)) {
            $pathList += $expanded
            $added    += $expanded
        }
    }

    if ($added.Count -gt 0) {
        $newPath = $pathList -join ";"
        [System.Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
        foreach ($p in $added) {
            Write-Ok "Added to PATH: $p"
        }
    } else {
        Write-Skip "All known paths already configured"
    }
}

Repair-Paths

# ---- Done — instruct user to reopen terminal ---------------
Write-Host ""
Write-Host "  ============================================" -ForegroundColor Cyan
Write-Host "  Phase A complete!" -ForegroundColor Green
Write-Host "  ============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  IMPORTANT: PATH changes need a fresh terminal." -ForegroundColor Yellow
Write-Host ""
Write-Host "  Next steps:" -ForegroundColor White
Write-Host "  1. Close this terminal completely" -ForegroundColor White
Write-Host "  2. Open a NEW terminal as Administrator" -ForegroundColor White
Write-Host "  3. Navigate back to your wim folder" -ForegroundColor White
Write-Host "  4. Run:" -ForegroundColor White
Write-Host ""
Write-Host "     powershell -ExecutionPolicy Bypass -File installer\setup.ps1" -ForegroundColor Cyan
Write-Host ""