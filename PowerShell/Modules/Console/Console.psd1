@{
    RootModule        = 'Console.psm1'
    ModuleVersion     = '1.0.0'
    PowerShellVersion = '5.1'
    Description       = 'Legacy console prompting and formatting helpers.'
    FunctionsToExport = @('Console-Confirm', 'Console-CreateMenu', 'Console-Menu', 'Console-RunTests', 'Console-WriteColor', 'Console-WriteHR')
    AliasesToExport   = @()
    CmdletsToExport   = @()
    VariablesToExport = @()
}
