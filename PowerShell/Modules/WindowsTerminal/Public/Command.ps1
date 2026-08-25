function Invoke-WindowsTerminal {
    param([Parameter(Position=0)][string]$Verb, [Parameter(Position=1)][string]$Argument='')
    switch ($Verb) {
        { [string]::IsNullOrWhiteSpace($_) } { Show-WindowsTerminalMenu }
        'current' { Get-WindowsTerminalTheme }
        'list' { Get-WindowsTerminalThemes $Argument }
        'set' { Set-WindowsTerminalTheme $Argument }
        'next' { Move-WindowsTerminalTheme Next }
        'prev' { Move-WindowsTerminalTheme Previous }
        { $_ -in 'table','colortable' } { if ($Argument) { Write-WindowsTerminalColorTable ([ConsoleColor]$Argument) } else { Write-WindowsTerminalColorTable } }
        'registry' { Sync-WindowsTerminalToRegistry }
        { $_ -in 'interactive', 'menu' } { Show-WindowsTerminalMenu }
        'background' { if ($Argument -eq 'remove') { Remove-WindowsTerminalBackground } elseif ($Argument) { Set-WindowsTerminalBackground $Argument } else { Write-Host 'winterm background <image path|desktopWallpaper> | background remove' } }
        'backgrounds' { Get-WindowsTerminalBackgrounds }
        'settings' { Open-WindowsTerminalSettings }
        'download' { Write-Host 'Themes: https://windowsterminalthemes.dev/'; Write-Host 'Repository: https://github.com/atomcorp/themes' }
        'help' { Write-Host 'winterm current | list [filter] | set <theme> | next | prev | backgrounds | background <name|path|remove> | settings | table | interactive | menu | registry | download' }
        default { Write-Host 'winterm current | list [filter] | set <theme> | next | prev | backgrounds | background <name|path|remove> | settings | table | interactive | menu | registry | download' }
    }
}
