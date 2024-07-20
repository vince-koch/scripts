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

# starship prompt

function Starship-Use-Preset {
    param (
        [string] $Preset
    )
    
    # Calculate source and target paths
    $presetFileName = $($Preset -replace ' ', '-') + '.toml'
    $sourcePath = [System.IO.Path]::Combine($PSScriptRoot, 'starship-presets', 'toml', $presetFileName)
    $targetPath = [System.IO.Path]::Combine($HOME, '.config', 'starship.toml')
    
    # Ensure the destination directory exists
    $targetDir = [System.IO.Path]::GetDirectoryName($targetPath)
    if (-not (Test-Path -Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    }
    
    # Copy the file
    [System.IO.File]::Copy($sourcePath, $targetPath, $true)
}

Starship-Use-Preset -Preset 'pastel-powerline'
#Starship-Use-Preset -Preset 'tokyo-night'
#Starship-Use-Preset -Preset 'gruvbox-rainbow'
#Starship-Use-Preset -Preset 'jetpack'

Invoke-Expression (&starship init powershell)