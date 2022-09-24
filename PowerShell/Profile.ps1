function Write-Colors {
    Write-Host "Black" -ForegroundColor Black
    Write-Host "Blue" -ForegroundColor Blue
    Write-Host "Cyan" -ForegroundColor Cyan
    Write-Host "DarkBlue" -ForegroundColor DarkBlue
    Write-Host "DarkCyan" -ForegroundColor DarkCyan
    Write-Host "DarkGray" -ForegroundColor DarkGray
    Write-Host "DarkGreen" -ForegroundColor DarkGreen
    Write-Host "DarkMagenta" -ForegroundColor DarkMagenta
    Write-Host "DarkRed" -ForegroundColor DarkRed
    Write-Host "DarkYellow" -ForegroundColor DarkYellow
    Write-Host "Gray" -ForegroundColor Gray
    Write-Host "Green" -ForegroundColor Green
    Write-Host "Magenta" -ForegroundColor Magenta
    Write-Host "Red" -ForegroundColor Red
    Write-Host "White" -ForegroundColor White
    Write-Host "Yellow" -ForegroundColor Yellow
}

Set-Alias -Name unzip -Value Expand-Archive

Import-Module $PSScriptRoot\Git.psm1 -DisableNameChecking -Force
Import-Module $PSScriptRoot\Notepad++.psm1 -DisableNameChecking -Force
Import-Module $PSScriptRoot\Prompt-Default.psm1 -DisableNameChecking -Force
Import-Module $PSScriptRoot\Shebang.psm1 -DisableNameChecking -Force
Import-Module $PSScriptRoot\TabsToSpaces.psm1 -DisableNameChecking -Force
Import-Module $PSScriptRoot\Console.psm1 -DisableNameChecking -Force

# add $PSScriptRoot to the path, and some aliases for loose ps1 files
$env:Path += ";$PSScriptRoot"
Set-Alias -Name move-windows -Value Move-WindowsToScreen
Set-Alias -Name move-to-screen -Value Move-WindowsToScreen

function Which {
    param ([string] $command)
    (get-command $command).Path
}

# set prompt
function Global:Prompt {
	return Prompt-Default
}

class Welcome {
    static [void] DisplayWelcomeScreen() {
        try {
            $psVersion = (Get-Host).Version
            Write-Host "PowerShell Version $($PsVersion)" -ForegroundColor DarkGray

            Push-Location $PSScriptRoot
            Write-Host "$([System.IO.Path]::GetFileName($PSCommandPath))" -NoNewLine

            $branch = Git-GetBranchName
            if ($branch) {
                Write-Host " / " -ForegroundColor DarkGray -NoNewLine
                Write-Host "$branch" -ForegroundColor Cyan -NoNewLine

                $commitDate = Git-GetCommitDate
                Write-Host " / " -ForegroundColor DarkGray -NoNewLine
                Write-Host "$commitDate" -ForegroundColor Blue -NoNewLine

                [Welcome]::AutoUpdate()
            }
        }
        finally {
            Write-Host ""
            Pop-Location
        }

        # $p = Get-Process -Id $PID
        # If ($p.Parent.Name -eq $p.Name -and !($p.MainWindowTitle)) {
        #     Stop-Process -Id $p.Parent.Id -Force
        # }
    }

    static [void] AutoUpdate() {
        # see if an update check is required
        [string] $lastUpdateCheckPath = ".git/update-check.txt"
        
        # if if we've checked for updates recently
        if ([System.IO.File]::Exists($lastUpdateCheckPath)) {
            $text = [System.IO.File]::ReadAllText($lastUpdateCheckPath)
            [System.DateTime] $lastUpdateCheck = $text -as [System.DateTime]
            if ($lastUpdateCheck -ne $null -and $lastUpdateCheck.AddHours(24) -gt [System.DateTime]::Now) {
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
}

[Welcome]::DisplayWelcomeScreen()