@{
    RootModule        = 'Notepad++.psm1'
    ModuleVersion     = '1.0.0'
    PowerShellVersion = '5.1'
    Description       = 'Notepad++ launcher helpers.'
    FunctionsToExport = @('Open-NotepadPlusPlus')
    AliasesToExport   = @('npp')
    CmdletsToExport   = @()
    VariablesToExport = @()
}
