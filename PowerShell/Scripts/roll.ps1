<#
.SYNOPSIS
    Rolls dice using standard tabletop dice notation.
.DESCRIPTION
    Accepts notation such as 1d6, 2d6, or 2d6+2 and displays each roll,
    any modifier, and a clearly highlighted final total.
.EXAMPLE
    roll 1d6
.EXAMPLE
    roll 2d6+2
.EXAMPLE
    roll 1 d 6 + 5
.EXAMPLE
    roll d20
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory, Position = 0, ValueFromRemainingArguments)]
    [string[]]$Dice
)

$suppliedNotation = $Dice -join ' '
$notation = ($Dice -join '') -replace '\s', ''
if ($notation -notmatch '^(?<Count>\d*)d(?<Sides>\d+)(?<Modifier>[+-]\d+)?$') {
    Write-Error "Invalid dice notation '$suppliedNotation'. Use notation such as 1d6, 2d6, or 2d6+2."
    exit 1
}

$count = if ([string]::IsNullOrEmpty($Matches.Count)) { 1 } else { [int]$Matches.Count }
$sides = [int]$Matches.Sides
$modifier = if ([string]::IsNullOrEmpty($Matches.Modifier)) { 0 } else { [int]$Matches.Modifier }

if ($count -lt 1 -or $count -gt 1000) {
    Write-Error 'The number of dice must be between 1 and 1000.'
    exit 1
}

if ($sides -lt 2 -or $sides -gt 1000000) {
    Write-Error 'The number of sides must be between 2 and 1,000,000.'
    exit 1
}

$normalizedNotation = "$($count)d$sides"
if ($modifier -gt 0) {
    $normalizedNotation += "+$modifier"
}
elseif ($modifier -lt 0) {
    $normalizedNotation += "$modifier"
}

$rolls = @(
    for ($index = 0; $index -lt $count; $index++) {
        Get-Random -Minimum 1 -Maximum ($sides + 1)
    }
)

$rollTotal = ($rolls | Measure-Object -Sum).Sum
$finalTotal = $rollTotal + $modifier

Write-Host
Write-Host '  Rolling ' -ForegroundColor DarkGray -NoNewline
Write-Host $normalizedNotation -ForegroundColor Cyan

Write-Host '  Dice:    ' -ForegroundColor DarkGray -NoNewline
for ($index = 0; $index -lt $rolls.Count; $index++) {
    if ($index -gt 0) {
        Write-Host ' + ' -ForegroundColor DarkGray -NoNewline
    }
    Write-Host $rolls[$index] -ForegroundColor Yellow -NoNewline
}
Write-Host

if ($modifier -ne 0) {
    $operator = if ($modifier -gt 0) { '+' } else { '-' }
    Write-Host '  Modifier:' -ForegroundColor DarkGray -NoNewline
    Write-Host " $operator $([Math]::Abs($modifier))" -ForegroundColor Magenta
}

Write-Host '  ──────────────────' -ForegroundColor DarkGray
Write-Host '  TOTAL:   ' -ForegroundColor White -NoNewline
Write-Host $finalTotal -ForegroundColor Green
Write-Host
