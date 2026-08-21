<#
.SYNOPSIS
    Displays the available console colors.
.DESCRIPTION
    Prints every System.ConsoleColor value using that color alongside its default rendering.
#>

$colors = [Enum]::GetValues([System.ConsoleColor])

foreach ($color in $colors) {
    Write-Host ('{0,-15}' -f $color) -ForegroundColor $color -NoNewline
    Write-Host ('{0,-15}' -f $color)
}
