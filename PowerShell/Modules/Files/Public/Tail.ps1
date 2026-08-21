function Get-FileTail {
    <#
    .SYNOPSIS
        Displays the last lines of a file and follows appended content by default.
    .EXAMPLE
        tail .\application.log -n 25
    .EXAMPLE
        tail .\application.log -Follow:$false
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Path,

        [Parameter(Position = 1)]
        [Alias('n')]
        [ValidateRange(0, [int]::MaxValue)]
        [int]$Lines = 10,

        [Alias('f')]
        [switch]$Follow = $true
    )

    if (-not (Test-Path -Path $Path -PathType Leaf)) {
        Write-Error "File not found: $Path"
        return
    }

    $parameters = @{ Path = $Path; Tail = $Lines }
    if ($Follow) { $parameters.Wait = $true }
    Get-Content @parameters
}
