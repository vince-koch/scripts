$publicRoot = Join-Path $PSScriptRoot 'Public'
. (Join-Path $publicRoot 'FindFiles.ps1')
. (Join-Path $publicRoot 'FindModules.ps1')
. (Join-Path $publicRoot 'Less.ps1')
. (Join-Path $publicRoot 'Search.ps1')
. (Join-Path $publicRoot 'Tail.ps1')
. (Join-Path $publicRoot 'Touch.ps1')
. (Join-Path $publicRoot 'Unzip.ps1')

Set-Alias -Name find-files -Value Find-File
Set-Alias -Name find-modules -Value Find-Module
Set-Alias -Name search -Value File-Search
Set-Alias -Name touch -Value File-Touch
Set-Alias -Name less -Value Show-FilePage
Set-Alias -Name tail -Value Get-FileTail
Set-Alias -Name unzip -Value Expand-ZipFile

Export-ModuleMember `
    -Function Find-File, Find-Module, File-Search, File-Touch, Show-FilePage, Get-FileTail, Expand-ZipFile `
    -Alias find-files, find-modules, search, touch, less, tail, unzip
