function Show-WindowsHelp {
    Write-Host 'Usage:' -ForegroundColor Yellow
    Write-Host '    windows                    # Open the interactive menu'
    Write-Host '    windows theme              # Toggle the current theme'
    Write-Host '    windows theme light        # Use the light theme'
    Write-Host '    windows theme dark         # Use the dark theme'
    Write-Host '    windows theme toggle       # Toggle light and dark'
    Write-Host '    windows resolution         # Select a display resolution'
}

function Show-WindowsTools {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [ValidateSet('theme', 'resolution', 'help')]
        [string]$Command,

        [Parameter(Position = 1)]
        [ValidateSet('light', 'dark', 'toggle')]
        [string]$Theme
    )

    if ($Command) {
        switch ($Command) {
            'theme' { Set-WindowsTheme -Theme $(if ($Theme) { $Theme } else { 'toggle' }) }
            'resolution' { Set-Resolution }
            'help' { Show-WindowsHelp }
        }
        return
    }

    Import-Module PwshSpectreConsole -ErrorAction Stop
    while ($true) {
        $action = Read-SpectreSelection -Message 'Windows tools' -Choices @('Theme', 'Display resolution', 'Exit') -Color 'Cyan1'
        if (-not $action) { return }
        switch ($action) {
            'Theme' {
                $selectedTheme = Read-SpectreSelection -Message 'Select a Windows theme' -Choices @('Light', 'Dark', 'Toggle') -Color 'Cyan1'
                if ($selectedTheme) { Set-WindowsTheme -Theme $selectedTheme }
            }
            'Display resolution' { Set-Resolution }
            'Exit' { return }
        }
    }
}

Set-Alias -Name windows -Value Show-WindowsTools
