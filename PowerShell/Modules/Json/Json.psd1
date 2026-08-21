@{
    RootModule        = 'Json.psm1'
    ModuleVersion     = '1.0.0'
    PowerShellVersion = '5.1'
    Description       = 'JSON loading, saving, and display helpers.'
    FunctionsToExport = @('Json-LoadHashtable', 'Json-LoadPsObject', 'Json-PrintHashtable', 'Json-PrintPsObject', 'Json-SaveHashtable', 'Json-SavePsObject')
    AliasesToExport   = @()
    CmdletsToExport   = @()
    VariablesToExport = @()
}
