@{
    RootModule        = 'Windows.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = '72f62672-6b57-4b62-80dd-792991addd7c'
    Author            = 'Vince'
    Description       = 'Windows theme and display resolution tools.'
    PowerShellVersion = '7.0'

    FunctionsToExport = @(
        'Set-WindowsTheme'
        'Set-Resolution'
        'Show-WindowsTools'
    )

    AliasesToExport = @(
        'theme'
        'windows'
    )

    CmdletsToExport   = @()
    VariablesToExport = @()
}
