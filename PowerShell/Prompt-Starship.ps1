# starship prompt

function Starship-Use-Preset {
    param (
        [string] $Preset = $null
    )

    [string] $presetFolder = [System.IO.Path]::Combine($PSScriptRoot, 'starship-presets', 'toml')

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


# initialize starship
$env:STARSHIP_CONFIG = [Environment]::GetEnvironmentVariable("STARSHIP_CONFIG", "User")
Invoke-Expression (&starship init powershell)
