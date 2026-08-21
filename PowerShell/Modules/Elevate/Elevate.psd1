@{
    RootModule        = 'Elevate.psm1'
    ModuleVersion     = '1.0.0'
    PowerShellVersion = '5.1'
    Description       = 'Windows process elevation helpers.'
    FunctionsToExport = @('Ensure-Elevated', 'Is-Elevated')
    AliasesToExport   = @()
    CmdletsToExport   = @()
    VariablesToExport = @()
}
