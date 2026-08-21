function File-Touch {
    <#
    .SYNOPSIS
        Creates a file or updates its access and modification timestamps.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Path
    )

    if (-not (Test-Path $Path)) {
        New-Item -ItemType File -Path $Path | Out-Null
    }

    $file = Get-Item $Path
    $now = Get-Date
    $file.LastWriteTime = $now
    $file.LastAccessTime = $now
}
