function Write-WindowsTerminalColorTable {
    param([ConsoleColor]$LabelColor = [ConsoleColor]::Gray)
    Write-Host '   Ordinal                        Matched color'
    $colors = [Enum]::GetValues([ConsoleColor])
    for ($index = 0; $index -lt $colors.Count; $index++) {
        $left = $colors[$index]; $right = $colors[($index + 8) % $colors.Count]
        Write-Host ("{0,2} {1,-15}" -f [int]$left, $left) -ForegroundColor $LabelColor -NoNewline
        Write-Host ("{0,-15}" -f $left) -ForegroundColor $left -NoNewline
        Write-Host ("{0,2} {1,-15}" -f [int]$right, $right) -ForegroundColor $right
    }
}
