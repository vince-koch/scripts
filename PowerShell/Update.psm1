Try-Import-Module $PSScriptRoot\Git.psm1

function Update-GitPull {
    Push-Location $PSScriptRoot

    try {
        Write-Host "Checking for local changes..." -ForegroundColor DarkGray
        $localChanges = git status --porcelain
        if ($localChanges) {
            Write-Host "  Local changes detected - please commit or stash before updating:" -ForegroundColor Yellow
            $localChanges | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkYellow }
            return $false
        }

        Write-Host "  Fetching from remote..." -ForegroundColor DarkGray
        git remote update
        if ($LASTEXITCODE -ne 0) {
            Write-Host "  Failed to fetch from remote." -ForegroundColor Red
            return $false
        }

        Write-Host "  Pulling latest changes..." -ForegroundColor DarkGray
        git pull
        if ($LASTEXITCODE -ne 0) {
            Write-Host "  Failed to pull changes." -ForegroundColor Red
            return $false
        }

        Write-Host "  Git pull complete." -ForegroundColor Green
        return $true
    }
    finally {
        Pop-Location
    }
}

function Update-AiInstructions {
    Write-Host "Updating AI instructions..." -ForegroundColor DarkGray

    $source = Join-Path $PSScriptRoot "Home\AI\user.md"
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
        Write-Host "  -> $dest" -ForegroundColor DarkGray
    }

    Write-Host "AI instructions updated." -ForegroundColor Green
}

function Update-Fonts {
    Write-Host "Updating fonts..." -ForegroundColor DarkGray

    $fontsSource = Join-Path (Split-Path $PSScriptRoot -Parent) "Fonts"
    if (-not (Test-Path $fontsSource)) {
        Write-Host "  No fonts directory found, skipping." -ForegroundColor DarkGray
        return
    }

    $systemFontsPath = "$env:SystemRoot\Fonts"
    $fontFiles = Get-ChildItem -Path $fontsSource -Include "*.ttf","*.otf","*.ttc" -Recurse

    if (-not $fontFiles) {
        Write-Host "  No font files found, skipping." -ForegroundColor DarkGray
        return
    }

    foreach ($font in $fontFiles) {
        $dest = Join-Path $systemFontsPath $font.Name
        if (Test-Path $dest) {
            Write-Host "  Already installed: $($font.Name)" -ForegroundColor DarkGray
            continue
        }

        Copy-Item -Path $font.FullName -Destination $dest -Force
        $regPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"
        Set-ItemProperty -Path $regPath -Name $font.BaseName -Value $font.Name
        Write-Host "  Installed: $($font.Name)" -ForegroundColor DarkGray
    }

    Write-Host "Fonts updated." -ForegroundColor Green
}

function Update {
    if (-not (Update-GitPull)) {
        Write-Host "Update aborted." -ForegroundColor Red
        return
    }

    Update-Fonts
    Update-AiInstructions
}

Export-ModuleMember -Function Update