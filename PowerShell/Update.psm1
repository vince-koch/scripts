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

function Update {
    if (-not (Update-GitPull)) {
        Write-Host "Update aborted." -ForegroundColor Red
        return
    }

    # Run the freshly-pulled Install.ps1 in a new process so we pick up any
    # changes that arrived with the git pull rather than the stale in-memory code.
    $installScript = Join-Path $PSScriptRoot "Update.Install.ps1"
    Write-Host "Running install steps..." -ForegroundColor DarkGray
    & pwsh -NoProfile -File $installScript
}

Export-ModuleMember -Function Update