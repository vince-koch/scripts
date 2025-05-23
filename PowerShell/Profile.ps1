function Welcome {
    $edition = if ($PSVersionTable.PSEdition -eq "Desktop") { "Windows PowerShell" } else { "PowerShell Core" }
    Write-Host "$edition " -ForegroundColor Blue -NoNewLine
    Write-Host "$($PSVersionTable.PSVersion)" -ForegroundColor Cyan
    Write-Host "$($PSScriptRoot)$([System.IO.Path]::DirectorySeparatorChar)" -ForegroundColor Blue -NoNewLine
    Write-Host "$([System.IO.Path]::GetFileName($PSCommandPath))" -ForegroundColor Cyan
}


function AutoUpdate {
    param (
        [int] $AutoUpdateCheckHours = 24
    )

    try {
        Push-Location $PSScriptRoot

        # see if an update check is required
        [string] $lastUpdateCheckPath = [System.IO.Path]::Combine($PSScriptRoot, "..", ".git", "update-check.txt")
        
        # if if we've checked for updates recently
        if ([System.IO.File]::Exists($lastUpdateCheckPath)) {
            $text = [System.IO.File]::ReadAllText($lastUpdateCheckPath)
            [System.DateTime] $lastUpdateCheck = $text -as [System.DateTime]
            if ($lastUpdateCheck -ne $null -and $lastUpdateCheck.AddHours($AutoUpdateCheckHours) -gt [System.DateTime]::Now) {
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


function Try-Import-Module {
    param (
        [Parameter(Mandatory)]
        [string] $ModulePath
    )

    $IsDebug = $false
    $resolvedPath = [System.IO.Path]::GetFullPath($ModulePath)

    # Check if module with that path is already loaded
    $alreadyLoaded = Get-Module | Where-Object {
        $_.Path -and ($_.Path -eq $resolvedPath)
    }

    if (-not $alreadyLoaded) {
        try {
            Import-Module -Name $resolvedPath -DisableNameChecking -Force -ErrorAction Stop
            Write-Host "Loaded module $([System.IO.Path]::GetFileNameWithoutExtension($resolvedPath))"
        }
        catch {
            Write-Host "Failed to import module from path '$resolvedPath': $_" -ForegroundColor Red
        }
    }
    elseif ($IsDebug) {
        Write-Host "Skipped already-loaded module: $resolvedPath" -ForegroundColor DarkGray
    }
}

# set aliases

function unzip {
    param (
        [string]$ZipFile,
        [string]$Destination = "."
    )
    Expand-Archive -Path $ZipFile -DestinationPath $Destination -Force @Args
}

function which {
    param([string]$name)
    (Get-Command $name).Source
}

$nuget_config = [System.IO.Path]::Combine($env:APPDATA, "Nuget", "Nuget.config")


# random functions

function Write-Colors {
    $colors = [Enum]::GetValues([System.ConsoleColor])

    foreach ($color in $colors) {
        Write-Host ("{0,-15}" -f $color) -ForegroundColor $color -NoNewLine
        Write-Host ("{0,-15}" -f $color)
    }
}


# startup welcome screen
Welcome
. $PSScriptRoot\Profile-TerminalIcons.ps1

# load modules

Try-Import-Module $PSScriptRoot\Aws.psm1
Try-Import-Module $PSScriptRoot\Bookmark.psm1
Try-Import-Module $PSScriptRoot\Console.psm1
Try-Import-Module $PSScriptRoot\Docker.psm1
Try-Import-Module $PSScriptRoot\Environment.psm1
Try-Import-Module $PSScriptRoot\Files.psm1
Try-Import-Module $PSScriptRoot\Git.psm1
Try-Import-Module $PSScriptRoot\Jira.psm1
Try-Import-Module $PSScriptRoot\Notepad++.psm1
Try-Import-Module $PSScriptRoot\Ps.psm1
Try-Import-Module $PSScriptRoot\Shebang.psm1
Try-Import-Module $PSScriptRoot\Studio3T.psm1
Try-Import-Module $PSScriptRoot\TabsToSpaces.psm1

AutoUpdate

# add $PSScriptRoot to the path
$env:Path += ";$PSScriptRoot"