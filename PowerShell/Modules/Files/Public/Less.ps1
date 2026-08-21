function Show-FilePage {
    <#
    .SYNOPSIS
        Displays a text file one page at a time.
    .EXAMPLE
        less .\README.md
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Path
    )

    if (-not (Test-Path -Path $Path -PathType Leaf)) {
        Write-Error "File not found: $Path"
        return
    }

    Get-Content -Path $Path | Out-Host -Paging
}
