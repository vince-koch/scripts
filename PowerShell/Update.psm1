Try-Import-Module $PSScriptRoot\Git.psm1

function Update-GitPull {
    # git will walk up and find the .git/ folder, so no
    # problem calling this from a subdirectory
    Push-Location $PSScriptRoot

    try {
        Write-Host "Step 1: Checking for local changes..." -ForegroundColor DarkGray
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
}

Export-ModuleMember -Function Update

# Write-Host "(Enter " -ForegroundColor DarkGray -NoNewLine
# Write-Host "Update" -ForegroundColor Gray -NoNewLine
# Write-Host " to update profile scripts)" -ForegroundColor DarkGray