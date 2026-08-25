@{
    RootModule        = 'KeyBindings.psm1'
    ModuleVersion     = '1.0.0'
    PowerShellVersion = '5.1'
    Description       = 'Convenient access to active PSReadLine key bindings.'
    RequiredModules   = @('PSReadLine')
    FunctionsToExport = @('Get-BoundKeyBinding')
    AliasesToExport   = @('keybind', 'keybinds', 'keybindings', 'hotkeys')
    CmdletsToExport   = @()
    VariablesToExport = @()
}
