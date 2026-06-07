param(
    [switch]$Quiet
)

function Write-Step {
    param([string]$Message)
    if (-not $Quiet) {
        Write-Host $Message -ForegroundColor DarkGray
    }
}

function Write-StepResult {
    param([string]$Message, [string]$Color = "Green")
    if (-not $Quiet) {
        Write-Host $Message -ForegroundColor $Color
    }
}

# ---- AI Instructions --------------------------------------------------------

function Install-AiInstructions {
    Write-Step "Updating AI instructions..."

    $source = Join-Path (Split-Path $PSScriptRoot -Parent) "Resources\AI\user.md"
    if (-not (Test-Path $source)) {
        Write-Step "  Source not found, skipping: $source"
        return
    }

    $destinations = @(
        "$HOME\.claude\CLAUDE.md",
        "$HOME\.copilot\copilot-instructions.md"
    )

    foreach ($dest in $destinations) {
        $dir = Split-Path $dest -Parent
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
        Copy-Item -Path $source -Destination $dest -Force
        Write-Step "  -> $dest"
    }

    Write-StepResult "AI instructions updated."
}

# ---- Fonts ------------------------------------------------------------------

function Install-Fonts {
    Write-Step "Updating fonts..."

    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        Write-StepResult "  Skipping fonts: must be run as Administrator." "Yellow"
        return
    }

    $fontsSource = Join-Path (Split-Path $PSScriptRoot -Parent) "Resources\Fonts"
    if (-not (Test-Path $fontsSource)) {
        Write-Step "  No fonts directory found, skipping."
        return
    }

    $fontFiles = Get-ChildItem -Path $fontsSource -Include "*.ttf","*.otf","*.ttc" -Recurse
    if (-not $fontFiles) {
        Write-Step "  No font files found, skipping."
        return
    }

    $systemFontsPath = "$env:SystemRoot\Fonts"
    foreach ($font in $fontFiles) {
        $dest = Join-Path $systemFontsPath $font.Name
        if (Test-Path $dest) {
            Write-Step "  Already installed: $($font.Name)"
            continue
        }

        Copy-Item -Path $font.FullName -Destination $dest -Force
        $regPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"
        Set-ItemProperty -Path $regPath -Name $font.BaseName -Value $font.Name
        Write-Step "  Installed: $($font.Name)"
    }

    Write-StepResult "Fonts updated."
}

# ---- Windows Terminal Icons -------------------------------------------------

function Install-WindowsTerminalIcons {
    Write-Step "Updating Windows Terminal icons..."

    $iconsSource = Join-Path (Split-Path $PSScriptRoot -Parent) "Resources\windows-terminal-icons\icons"
    if (-not (Test-Path $iconsSource)) {
        Write-Step "  No icons directory found, skipping."
        return
    }

    $wtPackage = Get-ChildItem "$env:LOCALAPPDATA\Packages" -Directory -Filter "Microsoft.WindowsTerminal_*" |
        Select-Object -First 1

    if (-not $wtPackage) {
        Write-StepResult "  Windows Terminal package not found, skipping." "Yellow"
        return
    }

    $dest = Join-Path $wtPackage.FullName "LocalState\icons"
    if (-not (Test-Path $dest)) {
        New-Item -ItemType Directory -Path $dest -Force | Out-Null
    }

    $iconFiles = Get-ChildItem -Path $iconsSource -File
    foreach ($icon in $iconFiles) {
        Copy-Item -Path $icon.FullName -Destination $dest -Force
        Write-Step "  -> $($icon.Name)"
    }

    Write-StepResult "Windows Terminal icons updated."
}

# ---- Run all install steps --------------------------------------------------

Install-AiInstructions
Install-Fonts
Install-WindowsTerminalIcons