@{
    RootModule        = 'Ps.psm1'
    ModuleVersion     = '1.0.0'
    PowerShellVersion = '5.1'
    Description       = 'PowerShell process and update helpers.'
    FunctionsToExport = @('Ps-IsCore', 'Ps-Restart', 'Ps-RestartPowershell', 'Ps-RestartPwsh', 'Ps-Update', 'Ps-Update-Version', 'Ps-Which')
    AliasesToExport   = @('reload', 'restart', 'reset', 'pwsh', 'powershell', 'update')
    CmdletsToExport   = @()
    VariablesToExport = @()
}
