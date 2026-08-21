@{
    RootModule        = 'Environment.psm1'
    ModuleVersion     = '1.0.0'
    PowerShellVersion = '7.0'
    FunctionsToExport = @(
        'Environment-List'
        'Environment-Get'
        'Environment-Set'
        'Environment-Unset'
        'Environment-PathAdd'
        'Environment-PathRemove'
        'Environment-PathPrint'
        'Environment-PathList'
        'Show-Environment'
    )
    AliasesToExport   = @('add-path', 'remove-path', 'env')
    CmdletsToExport   = @()
    VariablesToExport = @()
}
