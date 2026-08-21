@{
    RootModule        = 'Files.psm1'
    ModuleVersion     = '1.0.0'
    PowerShellVersion = '5.1'
    Description       = 'File searching, paging, tailing, timestamp, and archive helpers.'
    FunctionsToExport = @('Find-File', 'Find-Module', 'File-Search', 'File-Touch', 'Show-FilePage', 'Get-FileTail', 'Expand-ZipFile')
    AliasesToExport   = @('find-files', 'find-modules', 'search', 'touch', 'less', 'tail', 'unzip')
    CmdletsToExport   = @()
    VariablesToExport = @()
}
