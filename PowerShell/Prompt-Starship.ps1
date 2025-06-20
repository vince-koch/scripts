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
Invoke-Expression (&starship init powershell)


function Handle-TerminalHost {

    # Visual Studio Code
    if ($env:TERM_PROGRAM -eq "vscode") {
        Write-Host "$($env:TERM_PROGRAM)" -ForegroundColor Blue -NoNewLine
        Write-Host " $($env:TERM_PROGRAM_VERSION)" -ForegroundColor Cyan

        # Visual Studio Code always word wraps the terminal window which makes dootnet build output look terrible
        # To combat that we will attempt to reset the horizontal buffer size each time the prompt is shown
        # And we will do it each time our prompt is run
        function global:Invoke-Starship-PreCommand {
            $desiredWidth = 2000
            $bufferSize = $Host.UI.RawUI.BufferSize
            $Host.UI.RawUI.BufferSize = New-Object Management.Automation.Host.Size($desiredWidth, $bufferSize.Height)
        }
    }

    # Visual Studio
    elseif ($env:VisualStudioEdition -ne "") {
        Write-Host "$($env:VisualStudioEdition)" -ForegroundColor Blue -NoNewLine
        Write-Host " $($env:VisualStudioVersion)" -ForegroundColor Cyan

        # use a starship preset which doesn't break in visual studio
        if ($env:STARSHIP_CONFIG -ne "") {
            $env:STARSHIP_CONFIG = "no-nerd-font"
        }
    }

    # Otherwise
    else {
        # Start starship
        Invoke-Expression (&starship init powershell)
    }
}


Handle-TerminalHost
