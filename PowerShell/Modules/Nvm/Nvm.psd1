@{
    RootModule        = 'Nvm.psm1'
    ModuleVersion     = '1.0.0'
    PowerShellVersion = '5.1'
    Description       = 'User-level Node.js version management for Windows.'
    FunctionsToExport = @('Invoke-Nvm')
    AliasesToExport   = @('nvm')
    CmdletsToExport   = @()
    VariablesToExport = @()
}
