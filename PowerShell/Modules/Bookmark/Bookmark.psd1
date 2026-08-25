@{
    RootModule        = 'Bookmark.psm1'
    ModuleVersion     = '1.0.0'
    PowerShellVersion = '5.1'
    FunctionsToExport = @('Bookmark', 'Get-Bookmark', 'Select-Bookmark', 'Install-BookmarkHotkeys')
    AliasesToExport   = @('Bookmarks', 'ccd')
    CmdletsToExport   = @()
    VariablesToExport = @()
}
