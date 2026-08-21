@{
    RootModule        = 'Config.psm1'
    ModuleVersion     = '1.0.0'
    PowerShellVersion = '7.0'
    RequiredModules   = @('PwshSpectreConsole')
    FunctionsToExport = @('Show-Config')
    AliasesToExport   = @('config')
    CmdletsToExport   = @()
    VariablesToExport = @()
}
