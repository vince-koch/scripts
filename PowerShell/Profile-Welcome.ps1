class Welcome {
    static [void] DisplayWelcomeScreen() {
        # print current powershell version
        $psVersion = (Get-Host).Version
        if ($psVersion.Major -lt 6) {
            Write-Host "PowerShell $($PsVersion.Major).$($PsVersion.Minor)"
        }

        try {
            Push-Location $PSScriptRoot
            Write-Host "$([System.IO.Path]::GetFileName($PSCommandPath))" -NoNewLine

            $branch = Git-GetBranchName
            if ($branch) {
                Write-Host " / " -ForegroundColor DarkGray -NoNewLine
                Write-Host "$branch" -ForegroundColor Cyan -NoNewLine

                $commitDate = Git-GetCommitDate
                Write-Host " / " -ForegroundColor DarkGray -NoNewLine
                Write-Host "$commitDate" -ForegroundColor Blue -NoNewLine
            }
        }
        finally {
            Write-Host ""
            Pop-Location
        }
    }

    static [int] $AutoUpdateCheckHours = 24

    static [void] AutoUpdate() {
        try {
            Push-Location $PSScriptRoot

            # see if an update check is required
            [string] $lastUpdateCheckPath = [System.IO.Path]::Combine($PSScriptRoot, "..", ".git", "update-check.txt")
            
            # if if we've checked for updates recently
            if ([System.IO.File]::Exists($lastUpdateCheckPath)) {
                $text = [System.IO.File]::ReadAllText($lastUpdateCheckPath)
                [System.DateTime] $lastUpdateCheck = $text -as [System.DateTime]
                if ($lastUpdateCheck -ne $null -and $lastUpdateCheck.AddHours([Welcome]::AutoUpdateCheckHours) -gt [System.DateTime]::Now) {
                    return
                }
            }

            # update our last update check file
            [System.IO.File]::WriteAllText($lastUpdateCheckPath, [System.DateTime]::Now.ToString())

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
            Write-Host ""
            Pop-Location
        }
    }
}
