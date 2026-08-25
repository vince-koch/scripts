<#
.SYNOPSIS
    Provides Windows Terminal theme and console synchronization tools.
#>

$privateRoot = Join-Path $PSScriptRoot 'Private'
$publicRoot = Join-Path $PSScriptRoot 'Public'
$script:WindowsTerminalBackgroundsPath = Join-Path $PSScriptRoot 'Assets\Backgrounds'
. (Join-Path $privateRoot 'Settings.ps1')
. (Join-Path $publicRoot 'Themes.ps1')
. (Join-Path $publicRoot 'Background.ps1')
. (Join-Path $publicRoot 'ColorTable.ps1')
. (Join-Path $publicRoot 'Sync.ps1')
. (Join-Path $publicRoot 'Interactive.ps1')
. (Join-Path $publicRoot 'OpenSettings.ps1')
. (Join-Path $publicRoot 'Host.ps1')
. (Join-Path $publicRoot 'Hotkeys.ps1')
. (Join-Path $publicRoot 'Command.ps1')

Set-Alias -Name winterm -Value Invoke-WindowsTerminal
Export-ModuleMember `
    -Function Invoke-WindowsTerminal, Get-WindowsTerminalTheme, Get-WindowsTerminalThemes, Set-WindowsTerminalTheme, Move-WindowsTerminalTheme, Get-WindowsTerminalBackgrounds, Set-WindowsTerminalBackground, Remove-WindowsTerminalBackground, Toggle-WindowsTerminalBackground, Write-WindowsTerminalColorTable, Sync-WindowsTerminalToRegistry, Show-WindowsTerminalMenu, Open-WindowsTerminalSettings, Is-WindowsTerminal, Handle-WindowsTerminal, Install-WindowsTerminalHotkeys `
    -Alias winterm
