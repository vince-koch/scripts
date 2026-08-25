function Get-WindowsTerminalTheme {
    (Get-WindowsTerminalSettings).profiles.defaults.colorScheme
}

function Get-WindowsTerminalThemes {
    param([string]$Filter)
    $names = @((Get-WindowsTerminalSettings).schemes.name | Sort-Object -Unique)
    if ($Filter) { @($names | Where-Object { $_ -like "*$Filter*" }) } else { $names }
}

function Set-WindowsTerminalTheme {
    [CmdletBinding()]
    param([Parameter(Mandatory, Position = 0)][string]$Name)
    $matches = @(Get-WindowsTerminalThemes $Name)
    if ($Name -in $matches) { $matches = @($Name) }
    if ($matches.Count -ne 1) { Write-Warning "$($matches.Count) themes match '$Name'."; return $matches }
    Write-WindowsTerminalThemeName $matches[0]
    Write-Host 'Current theme: ' -NoNewline; Write-Host $matches[0] -ForegroundColor Yellow
}

function Move-WindowsTerminalTheme {
    param([ValidateSet('Next','Previous')][string]$Direction = 'Next')
    $names = @(Get-WindowsTerminalThemes)
    $index = [array]::IndexOf($names, (Get-WindowsTerminalTheme)) + $(if ($Direction -eq 'Next') { 1 } else { -1 })
    if ($index -ge $names.Count) { $index = 0 }; if ($index -lt 0) { $index = $names.Count - 1 }
    Set-WindowsTerminalTheme $names[$index]
}
