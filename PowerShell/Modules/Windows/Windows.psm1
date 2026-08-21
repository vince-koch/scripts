if ($env:OS -notlike '*Windows*') {
    return
}

$publicRoot = Join-Path $PSScriptRoot 'Public'
. (Join-Path $publicRoot 'Themes.ps1')
. (Join-Path $publicRoot 'Resolution.ps1')
. (Join-Path $publicRoot 'Menu.ps1')

Export-ModuleMember -Function @(
    'Set-WindowsTheme'
    'Set-Resolution'
    'Show-WindowsTools'
) -Alias @(
    'theme'
    'windows'
)
