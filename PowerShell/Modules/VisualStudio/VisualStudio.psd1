@{
    RootModule        = 'VisualStudio.psm1'
    ModuleVersion     = '1.0.0'
    PowerShellVersion = '5.1'
    Description       = 'Visual Studio launch and host detection helpers.'
    FunctionsToExport = @('Handle-VisualStudio', 'Handle-VisualStudioCode', 'Is-VisualStudio', 'Is-VisualStudioCode', 'Open-VisualStudio')
    AliasesToExport   = @('vs')
    CmdletsToExport   = @()
    VariablesToExport = @()
}
