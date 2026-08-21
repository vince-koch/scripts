@{
    RootModule        = 'VisualStudio.psm1'
    ModuleVersion     = '1.0.0'
    PowerShellVersion = '5.1'
    Description       = 'Visual Studio host detection helpers.'
    FunctionsToExport = @('Handle-VisualStudio', 'Handle-VisualStudioCode', 'Is-VisualStudio', 'Is-VisualStudioCode')
    AliasesToExport   = @()
    CmdletsToExport   = @()
    VariablesToExport = @()
}
