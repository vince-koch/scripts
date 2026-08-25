@{
    RootModule        = 'WindowsTerminal.psm1'
    ModuleVersion     = '1.0.0'
    PowerShellVersion = '7.0'
    Description       = 'Windows Terminal theme, color-table, and console synchronization tools.'
    FunctionsToExport = @('Invoke-WindowsTerminal', 'Get-WindowsTerminalTheme', 'Get-WindowsTerminalThemes', 'Set-WindowsTerminalTheme', 'Move-WindowsTerminalTheme', 'Get-WindowsTerminalBackgrounds', 'Set-WindowsTerminalBackground', 'Remove-WindowsTerminalBackground', 'Toggle-WindowsTerminalBackground', 'Write-WindowsTerminalColorTable', 'Sync-WindowsTerminalToRegistry', 'Show-WindowsTerminalMenu', 'Open-WindowsTerminalSettings', 'Is-WindowsTerminal', 'Handle-WindowsTerminal', 'Install-WindowsTerminalHotkeys')
    AliasesToExport   = @('winterm')
    CmdletsToExport   = @()
    VariablesToExport = @()
}
