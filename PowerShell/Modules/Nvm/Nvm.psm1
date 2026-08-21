<#
.SYNOPSIS
    Provides user-level Node.js version management on Windows.
.DESCRIPTION
    Loads the NVM implementation and exports the nvm command.
#>

. (Join-Path $PSScriptRoot 'Public\Nvm.ps1')

Set-Alias -Name nvm -Value Invoke-Nvm
Export-ModuleMember -Function Invoke-Nvm -Alias nvm
