@{
    RootModule        = 'Flags.psm1'
    ModuleVersion     = '1.0.0'
    PowerShellVersion = '5.1'
    Description       = 'Bit flag and hashtable helpers.'
    FunctionsToExport = @('Flags-Add', 'Flags-Combine', 'Flags-Has', 'Flags-Remove', 'Flags-Toggle', 'Merge-Hashtables')
    AliasesToExport   = @()
    CmdletsToExport   = @()
    VariablesToExport = @()
}
