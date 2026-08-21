function File-Search {
    <#
    .SYNOPSIS
        Recursively searches beneath the current directory using a file pattern.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$Pattern = '*'
    )

    Get-ChildItem -Path (Get-Location) -Recurse -Filter $Pattern -File
}
