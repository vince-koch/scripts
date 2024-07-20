param (
    [Parameter(Mandatory = $false)]
    [string] $command = $null
)

# install command
if ($command -eq "install") {
    # ensure profile folder exists
    $folder = [System.IO.Path]::GetDirectoryName($profile)
    if (-not [System.IO.Directory]::Exists($folder)) {
        $null = [System.IO.Directory]::CreateDirectory($folder)
    }

    # backup profile file if it already exists
    if ([System.IO.File]::Exists($profile)) {
        $backup = "$($profile).backup-$($(Get-Date).Ticks)"

        Write-Host "Backing up existing profile to" -NoNewLine
        Write-Host " $backup" -ForegroundColor DarkGray
        [System.IO.File]::Copy($profile, $backup)
    }

    # dot source this file into the profile file
    [System.IO.File]::WriteAllText($profile, ". $PSCommandPath")
    Write-Host "Profile has been installed" -NoNewLine
    Write-Host " $profile" -ForegroundColor DarkGray

    # all done
    return
}

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

# add $PSScriptRoot to the path
$env:Path += ";$PSScriptRoot"

Import-Module $PSScriptRoot\Console.psm1 -DisableNameChecking -Force
Import-Module $PSScriptRoot\Environment.psm1 -DisableNameChecking -Force
Import-Module $PSScriptRoot\Docker.psm1 -DisableNameChecking -Force
Import-Module $PSScriptRoot\Git.psm1 -DisableNameChecking -Force
Import-Module $PSScriptRoot\Jira.psm1 -DisableNameChecking -Force
Import-Module $PSScriptRoot\Notepad++.psm1 -DisableNameChecking -Force
Import-Module $PSScriptRoot\Ps.psm1 -DisableNameChecking -Force
Import-Module $PSScriptRoot\Shebang.psm1 -DisableNameChecking -Force
Import-Module $PSScriptRoot\TabsToSpaces.psm1 -DisableNameChecking -Force
Import-Module $PSScriptRoot\Touch.psm1 -DisableNameChecking -Force

Set-Alias -Name unzip -Value Expand-Archive

# startup welcome screen

. $PSScriptRoot\Profile-TerminalIcons.ps1
. $PSScriptRoot\Profile-Welcome.ps1
[Welcome]::DisplayWelcomeScreen()
[Welcome]::AutoUpdate()

# setup prompt

Import-Module $PSScriptRoot\Prompts.psm1 -DisableNameChecking -Force

function Global:Prompt {
	#return Prompt-SingleLine
    return Prompt-MultiLine
}