@{
    RootModule        = 'Files.psm1'
    ModuleVersion     = '1.0.0'
    PowerShellVersion = '5.1'
    FunctionsToExport = @('File-Search', 'File-Touch')
    AliasesToExport   = @('search', 'touch')
    CmdletsToExport   = @()
    VariablesToExport = @()
}
