Try-Import-Module $PSScriptRoot\Git.psm1

$script:LastUpdateCheckPath = [System.IO.Path]::Combine($PSScriptRoot, "..", ".git", "update-check.txt")

function Update-LastChecked {
    try {
        Push-Location $PSScriptRoot

        if ([System.IO.File]::Exists($script:LastUpdateCheckPath)) {
            $text = [System.IO.File]::ReadAllText($script:LastUpdateCheckPath)
            [System.DateTime] $lastUpdateCheck = $text -as [System.DateTime]
            $ago = (Get-Date) - $lastUpdateCheck

            Write-Host "Last update check was " -ForegroundColor Blue -NoNewline
            Write-Host ("{0}d {1}h {2}m ago" -f $ago.Days, $ago.Hours, $ago.Minutes) -ForegroundColor Cyan
        }
    }
    finally {
        Pop-Location
    }
}

function Update-Check {
    param (
        [int] $AutoUpdateCheckHours = 24
    )

    try {
        Push-Location $PSScriptRoot
        
        # update our last update check file
        [System.IO.File]::WriteAllText($script:LastUpdateCheckPath, [System.DateTime]::Now.ToString())

        # perform an update check
        [int] $check = Git-UpdateCheck
        if ($check -eq 1) { 
            Write-Host " / " -ForegroundColor DarkGray -NoNewLine
            Write-Host "AHEAD" -ForegroundColor Yellow
        }
        elseif ($check -eq 0) {
            Write-Host " / " -ForegroundColor DarkGray -NoNewLine
            Write-Host "CURRENT" -ForegroundColor Green
        }
        elseif ($check -eq -1) {
            Write-Host " / " -ForegroundColor DarkGray -NoNewLine
            Write-Host "UPDATE AVAILABLE" -ForegroundColor Red

            $confirm = Console-Confirm -Prompt "An update is available.  Would you like to update now? [Y/n] " -Default $true
            if ($confirm) {
                # do the update
                git pull

                # and if it was successful restart powershell
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "Update successful" -ForegroundColor Green
                    Write-Host "Restaring powerhsell is recommended" -ForegroundColor Yellow
                }
                else {
                    Write-Host "Update was not successful.  Please reveiew messages above to resolve." -ForegroundColor Red
                }
            }
        }
    }
    finally {
        Pop-Location
    }
}

Export-ModuleMember -Function Update-LastChecked
Export-ModuleMember -Function Update-Check
