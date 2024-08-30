# add $PSScriptRoot to the path
$env:Path += ";$PSScriptRoot"

Import-Module $PSScriptRoot\Console.psm1 -DisableNameChecking -Force
Import-Module $PSScriptRoot\Environment.psm1 -DisableNameChecking -Force
Import-Module $PSScriptRoot\Docker.psm1 -DisableNameChecking -Force
Import-Module $PSScriptRoot\Files.psm1 -DisableNameChecking -Force
Import-Module $PSScriptRoot\Git.psm1 -DisableNameChecking -Force
Import-Module $PSScriptRoot\Jira.psm1 -DisableNameChecking -Force
Import-Module $PSScriptRoot\Notepad++.psm1 -DisableNameChecking -Force
Import-Module $PSScriptRoot\Ps.psm1 -DisableNameChecking -Force
Import-Module $PSScriptRoot\Shebang.psm1 -DisableNameChecking -Force
Import-Module $PSScriptRoot\TabsToSpaces.psm1 -DisableNameChecking -Force

Set-Alias -Name unzip -Value Expand-Archive

# startup welcome screen

. $PSScriptRoot\Profile-TerminalIcons.ps1
. $PSScriptRoot\Profile-Welcome.ps1
[Welcome]::DisplayWelcomeScreen()
[Welcome]::AutoUpdate()

# starship prompt

function Starship-Use-Preset {
    param (
        [string] $Preset = $null
    )

    [string] $presetFolder  = [System.IO.Path]::Combine($PSScriptRoot, 'starship-presets', 'toml')

    if ([string]::IsNullOrWhiteSpace($Preset)) {
        $presets = [System.IO.Directory]::GetFiles($presetFolder, "*.toml")
        $presetNames = $presets | ForEach-Object { [System.IO.Path]::GetFileNameWithoutExtension($_) }
        $Preset = Console-Menu -Items $presetNames -Title "Select Starship Preset"
    }

    if (-not [string]::IsNullOrWhiteSpace($Preset)) {
        [string[]] $presetPaths = @(
            [System.IO.Path]::GetFullPath($Preset),
            [System.IO.Path]::GetFullPath($Preset + ".toml"),
            [System.IO.Path]::Combine($presetFolder, $Preset),
            [System.IO.Path]::Combine($presetFolder, $Preset + ".toml")
        )
        
        [string] $fullPresetPath = $presetPaths | Where-Object { Test-Path $_ } | Select-Object -First 1
        if (-not [string]::IsNullOrWhiteSpace($fullPresetPath)) {
            # $ENV:STARSHIP_CONFIG = $fullPresetPath
            # env set STARSHIP_CONFIG $fullPresetPath
            [Environment]::SetEnvironmentVariable("STARSHIP_CONFIG", $fullPresetPath)
            [Environment]::SetEnvironmentVariable("STARSHIP_CONFIG", $fullPresetPath, "User")
        }
        else {
            Write-Host "err: " -Foreground Red -NoNewLine
            Write-Host "Unable to find a preset named " -NoNewLine
            Write-Host $Preset -Foreground Yellow
        }
    }

    # # Calculate source and target paths
    # $presetFileName = $($Preset -replace ' ', '-') + '.toml'
    # $sourcePath = [System.IO.Path]::Combine($PSScriptRoot, 'starship-presets', 'toml', $presetFileName)
    # $targetPath = [System.IO.Path]::Combine($HOME, '.config', 'starship.toml')
    
    # # Ensure the destination directory exists
    # $targetDir = [System.IO.Path]::GetDirectoryName($targetPath)
    # if (-not (Test-Path -Path $targetDir)) {
    #     New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    # }
    
    # # Copy the file
    # [System.IO.File]::Copy($sourcePath, $targetPath, $true)
}

#Starship-Use-Preset -Preset 'pastel-powerline'
#Starship-Use-Preset -Preset 'tokyo-night'
#Starship-Use-Preset -Preset 'gruvbox-rainbow'
#Starship-Use-Preset -Preset 'jetpack'

Invoke-Expression (&starship init powershell)