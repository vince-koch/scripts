@{
    RootModule        = 'Colors.psm1'
    ModuleVersion     = '1.0.0'
    PowerShellVersion = '5.1'
    Description       = 'Console color helpers and named color data.'
    FunctionsToExport = @('AdjustColorBrightness', 'Get-Colors')
    AliasesToExport   = @()
    CmdletsToExport   = @()
    VariablesToExport = @('Colors')
}
