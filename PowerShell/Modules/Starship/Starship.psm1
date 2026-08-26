<#
.SYNOPSIS
    Provides Starship prompt preset selection.
.DESCRIPTION
    Commands for selecting a saved Starship prompt preset from the bundled Assets/Presets folder.
#>

$script:StarshipPresetsPath = Join-Path $PSScriptRoot 'Assets\Presets'

function Starship-Use-Preset {
    param (
        [string] $Preset = $null
    )

    [string] $presetFolder = $script:StarshipPresetsPath

    if ([string]::IsNullOrWhiteSpace($Preset)) {
        Import-Module PwshSpectreConsole -ErrorAction Stop
        $presets = [System.IO.Directory]::GetFiles($presetFolder, "*.toml")
        $presetNames = $presets | ForEach-Object { [System.IO.Path]::GetFileNameWithoutExtension($_) }
        $Preset = Read-SpectreSelection `
            -Message 'Select a Starship preset' `
            -Choices $presetNames `
            -EnableSearch `
            -Color 'Cyan1'
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
            [Environment]::SetEnvironmentVariable("STARSHIP_CONFIG", $fullPresetPath)
            [Environment]::SetEnvironmentVariable("STARSHIP_CONFIG", $fullPresetPath, "User")
        }
        else {
            Write-Host "err: " -ForegroundColor Red -NoNewLine
            Write-Host "Unable to find a preset named " -NoNewLine
            Write-Host $Preset -ForegroundColor Yellow
        }
    }
}

function Use-Starship-Preset {
    Starship-Use-Preset
}

Export-ModuleMember -Function Starship-Use-Preset, Use-Starship-Preset
