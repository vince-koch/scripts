@{
    RootModule        = 'Win-User32.psm1'
    ModuleVersion     = '1.0.0'
    PowerShellVersion = '5.1'
    Description       = 'Windows User32 interop helpers.'
    FunctionsToExport = @('Get-Flags', 'Get-ForegroundWindow', 'Get-ScreenFromRectangle', 'Get-WindowLong', 'Get-WindowRect', 'Set-ForegroundWindow', 'Set-WindowLong', 'Set-WindowPos', 'Show-Window')
    AliasesToExport   = @()
    CmdletsToExport   = @()
    VariablesToExport = @()
}
