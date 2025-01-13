# add $PSScriptRoot to the path
$env:Path += ";$PSScriptRoot"

function Try-Import-Module {
    param (
        [string] $ModulePath
    )

    $IsDebug = $false
    $ModuleName = [System.IO.Path]::GetFileNameWithoutExtension($ModulePath)
    
    if (-not (Get-Module -Name $ModuleName)) {
        try {
            Import-Module -Name $ModulePath -DisableNameChecking -Force -ErrorAction Stop
            if ($IsDebug -eq $true) {
                Write-Host "Loaded module '$ModuleName'" -Foreground DarkGray
            }
        }
        catch {
            Write-Error "Failed to import module from path '$ModulePath': $_" -Foreground Red
        }
    }
    elseif ($IsDebug -eq $true) {
        Write-Host "Skipped module '$ModuleName'" -Foreground DarkGray
    }
}

# load modules

Try-Import-Module $PSScriptRoot\Aws.psm1
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

# startup welcome screen

. $PSScriptRoot\Profile-TerminalIcons.ps1
. $PSScriptRoot\Profile-Welcome.ps1
[Welcome]::DisplayWelcomeScreen()
[Welcome]::AutoUpdate()
