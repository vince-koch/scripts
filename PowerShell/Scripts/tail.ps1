<#
.SYNOPSIS
    Displays the last lines of a file.
.DESCRIPTION
    Shows the final 10 lines and continues watching for appended content by
    default. Use -Lines (or -n) to change the count, or -Follow:$false for
    a one-time read.
.EXAMPLE
    tail .\application.log
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
    exit 1
}

$parameters = @{
    Path = $Path
    Tail = $Lines
}

if ($Follow) {
    $parameters.Wait = $true
}

Get-Content @parameters
