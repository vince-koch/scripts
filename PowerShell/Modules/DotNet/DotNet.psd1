@{
    RootModule        = 'DotNet.psm1'
    ModuleVersion     = '1.0.0'
    PowerShellVersion = '5.1'
    Description       = '.NET build artifact and user-secrets utilities.'
    FunctionsToExport = @('Clear-DotNetArtifacts', 'Open-DotNetSecrets')
    AliasesToExport   = @('dotnet-clean', 'dotnet-secrets')
    CmdletsToExport   = @()
    VariablesToExport = @()
}
