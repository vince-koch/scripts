function Find-Module {
    <#
    .SYNOPSIS
        Locates and imports a module file from PSModulePath or PATH.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$ModuleName
    )

    $separator = [System.IO.Path]::PathSeparator
    [string[]]$modulePaths = $env:PSModulePath -split [regex]::Escape($separator)
    [string]$modulePath = Find-File -FileName $ModuleName -Paths $modulePaths

    if (-not $modulePath) {
        [string[]]$paths = $env:Path -split [regex]::Escape($separator)
        $modulePath = Find-File -FileName $ModuleName -Paths $paths
    }

    if (-not $modulePath) { throw "Unable to locate module $ModuleName" }

    Write-Verbose "Importing $modulePath"
    Import-Module $modulePath -DisableNameChecking -Force
}
